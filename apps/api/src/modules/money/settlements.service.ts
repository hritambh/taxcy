import { Injectable } from '@nestjs/common';
import { PayRule, type SettlementSummary } from '@taxcy/contracts';
import type { Prisma, TenantTx } from '@taxcy/db';
import {
  computeSettlement,
  formatInrShort,
  istBusinessDate,
  type SettlementLineType,
  type SettlementTrip,
} from '@taxcy/domain';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { AppError, notFound } from '../../platform/errors.js';
import { newId } from '../../platform/ids.js';
import { Db } from '../../platform/prisma.service.js';
import { SettingsService } from '../fleet/settings.service.js';
import { TripsService } from '../trips/trips.service.js';

/** How far back to look for late items from already-settled days. */
const LOOKBACK_DAYS = 60;
const DAY_MS = 86_400_000;

interface Line {
  refType: SettlementLineType;
  refId: string;
  amountPaise: number;
  description: string;
  originalDate: string | null;
}

export interface SettlementDetail extends SettlementSummary {
  payRule: PayRule;
  lines: Line[];
}

const istDayStart = (date: string) => new Date(`${date}T00:00:00+05:30`);
const rupees = (paise: bigint | number) => formatInrShort(Number(paise));

const tripInclude = {
  vehicle: { select: { registrationNo: true } },
  charges: { where: { voidedAt: null } },
  collections: true,
} as const satisfies Prisma.TripInclude;
type TripWithMoney = Prisma.TripGetPayload<{ include: typeof tripInclude }>;

@Injectable()
export class SettlementsService {
  constructor(
    private readonly db: Db,
    private readonly settings: SettingsService,
    private readonly trips: TripsService,
  ) {}

  async list(auth: TenantAuth, date: Date): Promise<SettlementSummary[]> {
    const day = date.toISOString().slice(0, 10);
    return this.db.tenant(auth.orgId, async (tx) => {
      const start = istDayStart(day);
      const end = new Date(start.getTime() + DAY_MS);
      const [tripDrivers, fillDrivers, settled] = await Promise.all([
        tx.trip.findMany({
          where: {
            orgId: tx.orgId,
            driverId: { not: null },
            OR: [
              { endedAt: { gte: start, lt: end } },
              { cancelledAt: { gte: start, lt: end }, startedAt: { not: null } },
            ],
          },
          select: { driverId: true },
        }),
        tx.fuelFill.findMany({
          where: {
            orgId: tx.orgId,
            driverId: { not: null },
            voidedAt: null,
            filledAt: { gte: start, lt: end },
          },
          select: { driverId: true },
        }),
        tx.settlement.findMany({
          where: { orgId: tx.orgId, businessDate: date },
          select: { driverId: true },
        }),
      ]);
      const driverIds = [
        ...new Set(
          [...tripDrivers, ...fillDrivers, ...settled]
            .map((r) => r.driverId)
            .filter((d): d is string => !!d),
        ),
      ];
      const results: SettlementSummary[] = [];
      for (const driverId of driverIds) {
        const {
          lines: _lines,
          payRule: _payRule,
          ...summary
        } = await this.detailInTx(tx, driverId, day);
        results.push(summary);
      }
      return results.sort((a, b) => a.driverName.localeCompare(b.driverName));
    });
  }

  async get(auth: TenantAuth, date: Date, driverId: string): Promise<SettlementDetail> {
    return this.db.tenant(auth.orgId, (tx) =>
      this.detailInTx(tx, driverId, date.toISOString().slice(0, 10)),
    );
  }

  /**
   * Freezes the day: stores the totals and every covered item as a settlement line
   * (each item can be settled only once), and moves the day's ended trips to settled.
   * Settling an already-settled day returns it unchanged.
   */
  async settle(auth: TenantAuth, date: Date, driverId: string): Promise<SettlementDetail> {
    const day = date.toISOString().slice(0, 10);
    return this.db.tenant(auth.orgId, async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${`settle:${driverId}:${day}`}))`;
      const draft = await this.detailInTx(tx, driverId, day);
      if (draft.status === 'settled') return draft;
      if (!draft.lines.length)
        throw new AppError('CONFLICT', 'There is nothing to settle for this driver on this day');

      const id = newId();
      await tx.settlement.create({
        data: {
          id,
          orgId: tx.orgId,
          driverId,
          businessDate: date,
          expectedFarePaise: BigInt(draft.expectedFarePaise),
          cashPaise: BigInt(draft.cashPaise),
          onlinePaise: BigInt(draft.onlinePaise),
          driverExpensesPaise: BigInt(draft.driverExpensesPaise),
          driverEarningsPaise: BigInt(draft.driverEarningsPaise),
          carriedAdjustmentPaise: BigInt(draft.carriedAdjustmentPaise),
          netPayablePaise: BigInt(draft.netPayablePaise),
          payRuleSnapshot: draft.payRule,
          status: 'settled',
          settledBy: auth.userId,
          settledAt: new Date(),
        },
      });
      await tx.settlementLine.createMany({
        data: draft.lines.map((l) => ({
          id: newId(),
          orgId: tx.orgId,
          settlementId: id,
          refType: l.refType,
          refId: l.refId,
          amountPaise: BigInt(l.amountPaise),
        })),
      });
      const endedTrips = await tx.trip.findMany({
        where: {
          id: { in: draft.lines.filter((l) => l.refType === 'trip').map((l) => l.refId) },
          status: 'ended',
        },
        select: { id: true },
      });
      await this.trips.settleInTx(
        tx,
        auth,
        endedTrips.map((t) => t.id),
      );
      return this.detailInTx(tx, driverId, day);
    });
  }

  private async detailInTx(tx: TenantTx, driverId: string, day: string): Promise<SettlementDetail> {
    const driver = await tx.driver.findFirst({ where: { id: driverId, orgId: tx.orgId } });
    if (!driver) throw notFound('Driver');
    const date = new Date(`${day}T00:00:00.000Z`);
    const stored = await tx.settlement.findUnique({
      where: { orgId_driverId_businessDate: { orgId: tx.orgId, driverId, businessDate: date } },
      include: { lines: true },
    });
    if (stored?.status === 'settled') {
      const payRule = PayRule.parse(stored.payRuleSnapshot);
      const lines = await this.describeStored(tx, stored.lines);
      return {
        driverId,
        driverName: driver.name,
        businessDate: date,
        status: 'settled',
        expectedFarePaise: Number(stored.expectedFarePaise),
        cashPaise: Number(stored.cashPaise),
        onlinePaise: Number(stored.onlinePaise),
        driverExpensesPaise: Number(stored.driverExpensesPaise),
        driverEarningsPaise: Number(stored.driverEarningsPaise),
        carriedAdjustmentPaise: Number(stored.carriedAdjustmentPaise),
        netPayablePaise: Number(stored.netPayablePaise),
        shortfallPaise:
          Number(stored.expectedFarePaise) - Number(stored.cashPaise) - Number(stored.onlinePaise),
        tripCount: stored.lines.filter((l) => l.refType === 'trip').length,
        settledAt: stored.settledAt,
        settledBy: stored.settledBy,
        payRule,
        lines,
      };
    }
    return this.draft(tx, driver, day, date);
  }

  private async draft(
    tx: TenantTx,
    driver: { id: string; name: string; payRule: Prisma.JsonValue },
    day: string,
    date: Date,
  ): Promise<SettlementDetail> {
    const start = istDayStart(day);
    const end = new Date(start.getTime() + DAY_MS);
    const lookback = new Date(start.getTime() - LOOKBACK_DAYS * DAY_MS);

    const settledDays = new Set(
      (
        await tx.settlement.findMany({
          where: {
            orgId: tx.orgId,
            driverId: driver.id,
            status: 'settled',
            businessDate: { gte: lookback, lt: date },
          },
          select: { businessDate: true },
        })
      ).map((s) => s.businessDate.toISOString().slice(0, 10)),
    );
    const daySettled = (at: Date) => settledDays.has(istBusinessDate(at));

    const [dayTrips, earlierTrips, dayFills, earlierFills] = await Promise.all([
      tx.trip.findMany({
        where: {
          orgId: tx.orgId,
          driverId: driver.id,
          OR: [
            { status: { in: ['ended', 'settled'] }, endedAt: { gte: start, lt: end } },
            { status: 'cancelled', startedAt: { not: null }, cancelledAt: { gte: start, lt: end } },
          ],
        },
        include: tripInclude,
      }),
      tx.trip.findMany({
        where: {
          orgId: tx.orgId,
          driverId: driver.id,
          OR: [
            { status: { in: ['ended', 'settled'] }, endedAt: { gte: lookback, lt: start } },
            {
              status: 'cancelled',
              startedAt: { not: null },
              cancelledAt: { gte: lookback, lt: start },
            },
          ],
        },
        include: tripInclude,
      }),
      tx.fuelFill.findMany({
        where: {
          orgId: tx.orgId,
          driverId: driver.id,
          voidedAt: null,
          filledAt: { gte: start, lt: end },
        },
      }),
      tx.fuelFill.findMany({
        where: {
          orgId: tx.orgId,
          driverId: driver.id,
          voidedAt: null,
          filledAt: { gte: lookback, lt: start },
        },
      }),
    ]);

    const candidateIds = [
      ...[...dayTrips, ...earlierTrips].flatMap((t) => [
        t.id,
        ...t.charges.map((c) => c.id),
        ...t.collections.map((c) => c.id),
      ]),
      ...[...dayFills, ...earlierFills].map((f) => f.id),
    ];
    const settledIds = new Set(
      (
        await tx.settlementLine.findMany({
          where: { refId: { in: candidateIds } },
          select: { refId: true },
        })
      ).map((l) => l.refId),
    );
    const open = (id: string) => !settledIds.has(id);
    const closedAt = (t: TripWithMoney) => t.endedAt ?? t.cancelledAt ?? t.updatedAt;

    // Trips that belong to this day, plus trips from settled days that synced late.
    const trips = [...dayTrips, ...earlierTrips.filter((t) => daySettled(closedAt(t)))].filter(
      (t) => open(t.id),
    );
    // Items added late to trips that were already settled become adjustments.
    const settledTrips = [...dayTrips, ...earlierTrips].filter((t) => !open(t.id));
    const fills = [...dayFills, ...earlierFills.filter((f) => daySettled(f.filledAt))].filter((f) =>
      open(f.id),
    );

    const lines: Line[] = [];
    const adjustments: { id: string; amountPaise: number }[] = [];
    for (const trip of settledTrips) {
      for (const c of trip.collections.filter((x) => open(x.id))) {
        const amount = c.method === 'cash' ? Number(c.amountPaise) : 0;
        adjustments.push({ id: c.id, amountPaise: amount });
        lines.push({
          refType: 'adjustment',
          refId: c.id,
          amountPaise: amount,
          description: `Late ${c.method} collection ${rupees(c.amountPaise)} for ${this.tripLabel(trip)}`,
          originalDate: istBusinessDate(closedAt(trip)),
        });
      }
      for (const c of trip.charges.filter((x) => open(x.id))) {
        const amount = c.paidByDriver ? -Number(c.amountPaise) : 0;
        adjustments.push({ id: c.id, amountPaise: amount });
        lines.push({
          refType: 'adjustment',
          refId: c.id,
          amountPaise: amount,
          description: `Late ${c.kind.replace('_', ' ')} ${rupees(c.amountPaise)} for ${this.tripLabel(trip)}`,
          originalDate: istBusinessDate(closedAt(trip)),
        });
      }
    }

    const settlementTrips: SettlementTrip[] = [];
    for (const trip of trips) {
      const fare =
        trip.status === 'cancelled'
          ? Number(trip.cancellationFarePaise ?? 0n)
          : Number(trip.quotedFarePaise);
      settlementTrips.push({
        id: trip.id,
        farePaise: fare,
        odometerKm: await this.tripKm(tx, trip),
        charges: trip.charges
          .filter((c) => open(c.id))
          .map((c) => ({
            id: c.id,
            kind: c.kind,
            amountPaise: Number(c.amountPaise),
            paidByDriver: c.paidByDriver,
          })),
        collections: trip.collections
          .filter((c) => open(c.id))
          .map((c) => ({
            id: c.id,
            method: c.method as 'cash' | 'upi' | 'card',
            amountPaise: Number(c.amountPaise),
          })),
      });
    }

    const payRule =
      driver.payRule === null
        ? (await this.settings.get(tx)).payRule
        : PayRule.parse(driver.payRule);
    const result = computeSettlement({
      trips: settlementTrips,
      fuelFills: fills.map((f) => ({
        id: f.id,
        costPaise: Number(f.costPaise),
        paidBy: f.paidBy as 'driver_cash' | 'owner' | 'fuel_card',
      })),
      payRule,
      adjustments,
    });

    const tripById = new Map(trips.map((t) => [t.id, t]));
    const chargeById = new Map(
      trips.flatMap((t) => t.charges.map((c) => [c.id, { c, t }] as const)),
    );
    const collectionById = new Map(
      trips.flatMap((t) => t.collections.map((c) => [c.id, c] as const)),
    );
    const fillById = new Map(fills.map((f) => [f.id, f]));
    for (const line of result.lines) {
      if (line.refType === 'adjustment') continue; // described above
      let description = '';
      let originalDate: string | null = null;
      if (line.refType === 'trip') {
        const t = tripById.get(line.refId);
        if (t) {
          description = `${this.tripLabel(t)}${t.status === 'cancelled' ? ' (cancelled, cancellation fare)' : ''}`;
          const tripDay = istBusinessDate(closedAt(t));
          if (tripDay !== day) originalDate = tripDay;
        }
      } else if (line.refType === 'trip_charge') {
        const entry = chargeById.get(line.refId);
        if (entry)
          description = `${entry.c.kind.replace('_', ' ')} ${rupees(entry.c.amountPaise)}${entry.c.paidByDriver ? ', paid by driver' : ''}`;
      } else if (line.refType === 'collection') {
        const c = collectionById.get(line.refId);
        if (c)
          description = `${c.method.toUpperCase()} collected ${rupees(c.amountPaise)}${c.reference ? ` (${c.reference})` : ''}`;
      } else {
        const f = fillById.get(line.refId);
        if (f) {
          description = `${f.fuel} ${(f.quantityMilli / 1000).toFixed(1)} ${f.fuel === 'cng' ? 'kg' : 'L'}, ${rupees(f.costPaise)}, ${f.paidBy.replace('_', ' ')}`;
          const fillDay = istBusinessDate(f.filledAt);
          if (fillDay !== day) originalDate = fillDay;
        }
      }
      lines.push({ ...line, description, originalDate });
    }

    return {
      driverId: driver.id,
      driverName: driver.name,
      businessDate: date,
      status: 'draft',
      expectedFarePaise: result.expectedFarePaise,
      cashPaise: result.cashPaise,
      onlinePaise: result.onlinePaise,
      driverExpensesPaise: result.driverExpensesPaise,
      driverEarningsPaise: result.driverEarningsPaise,
      carriedAdjustmentPaise: result.carriedAdjustmentPaise,
      netPayablePaise: result.netPayablePaise,
      shortfallPaise: result.shortfallPaise,
      tripCount: trips.length,
      settledAt: null,
      settledBy: null,
      payRule,
      lines,
    };
  }

  private tripLabel(trip: {
    fromText: string;
    toText: string | null;
    vehicle: { registrationNo: string } | null;
  }): string {
    return `${trip.toText ? `${trip.fromText} → ${trip.toText}` : trip.fromText}${trip.vehicle ? ` (${trip.vehicle.registrationNo})` : ''}`;
  }

  private async tripKm(
    tx: TenantTx,
    trip: { startOdometerId: string | null; endOdometerId: string | null },
  ): Promise<number | null> {
    if (!trip.startOdometerId || !trip.endOdometerId) return null;
    const readings = await tx.odometerReading.findMany({
      where: { id: { in: [trip.startOdometerId, trip.endOdometerId] } },
      select: { id: true, typedKm: true },
    });
    const startKm = readings.find((r) => r.id === trip.startOdometerId)?.typedKm;
    const endKm = readings.find((r) => r.id === trip.endOdometerId)?.typedKm;
    return startKm === undefined || endKm === undefined ? null : endKm - startKm;
  }

  private async describeStored(
    tx: TenantTx,
    lines: readonly { refType: string; refId: string; amountPaise: bigint }[],
  ): Promise<Line[]> {
    const ids = lines.map((l) => l.refId);
    const [trips, charges, collections, fills] = await Promise.all([
      tx.trip.findMany({
        where: { id: { in: ids } },
        include: { vehicle: { select: { registrationNo: true } } },
      }),
      tx.tripCharge.findMany({ where: { id: { in: ids } } }),
      tx.tripCollection.findMany({ where: { id: { in: ids } } }),
      tx.fuelFill.findMany({ where: { id: { in: ids } } }),
    ]);
    const describe = (refId: string): string => {
      const t = trips.find((x) => x.id === refId);
      if (t) return this.tripLabel(t);
      const c = charges.find((x) => x.id === refId);
      if (c)
        return `${c.kind.replace('_', ' ')} ${rupees(c.amountPaise)}${c.paidByDriver ? ', paid by driver' : ''}`;
      const col = collections.find((x) => x.id === refId);
      if (col) return `${col.method.toUpperCase()} collected ${rupees(col.amountPaise)}`;
      const f = fills.find((x) => x.id === refId);
      if (f)
        return `${f.fuel} ${(f.quantityMilli / 1000).toFixed(1)} ${f.fuel === 'cng' ? 'kg' : 'L'}, ${rupees(f.costPaise)}, ${f.paidBy.replace('_', ' ')}`;
      return '';
    };
    return lines.map((l) => ({
      refType: l.refType as SettlementLineType,
      refId: l.refId,
      amountPaise: Number(l.amountPaise),
      description:
        l.refType === 'adjustment' ? `Late item: ${describe(l.refId)}` : describe(l.refId),
      originalDate: null,
    }));
  }
}
