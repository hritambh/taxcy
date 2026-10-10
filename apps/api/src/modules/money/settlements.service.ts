import { Injectable } from '@nestjs/common';
import {
  ChargeKind,
  CollectionMethod,
  PaidBy,
  PayRule,
  type SettlementItem,
  type SettlementSummary,
} from '@taxcy/contracts';
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
  item: SettlementItem | null;
  originalDate: string | null;
}

export interface SettlementDetail extends SettlementSummary {
  payRule: PayRule;
  lines: Line[];
}

const istDayStart = (date: string) => new Date(`${date}T00:00:00+05:30`);
const rupees = (paise: bigint | number) => formatInrShort(Number(paise));

interface TripLike {
  fromText: string;
  toText: string | null;
  status: string;
  vehicle: { registrationNo: string } | null;
}
interface TripRef {
  from: string;
  to: string | null;
  registrationNo: string | null;
}

const tripRef = (t: TripLike): TripRef => ({
  from: t.fromText,
  to: t.toText,
  registrationNo: t.vehicle?.registrationNo ?? null,
});
const tripItem = (t: TripLike): SettlementItem => ({
  kind: 'trip',
  trip: tripRef(t),
  cancelled: t.status === 'cancelled',
});
const chargeItem = (
  c: { kind: string; amountPaise: bigint; paidByDriver: boolean },
  t: TripLike | undefined,
): SettlementItem => ({
  kind: 'charge',
  chargeKind: ChargeKind.parse(c.kind),
  amountPaise: Number(c.amountPaise),
  paidByDriver: c.paidByDriver,
  trip: t ? tripRef(t) : null,
});
const collectionItem = (
  c: { method: string; amountPaise: bigint; reference: string | null },
  t: TripLike | undefined,
): SettlementItem => ({
  kind: 'collection',
  method: CollectionMethod.parse(c.method),
  amountPaise: Number(c.amountPaise),
  reference: c.reference,
  trip: t ? tripRef(t) : null,
});
const fillItem = (f: {
  fuel: 'petrol' | 'diesel' | 'cng';
  quantityMilli: number;
  costPaise: bigint;
  paidBy: string;
}): SettlementItem => ({
  kind: 'fuel_fill',
  fuel: f.fuel,
  quantityMilli: f.quantityMilli,
  costPaise: Number(f.costPaise),
  paidBy: PaidBy.parse(f.paidBy),
});

const tripText = (r: TripRef) =>
  `${r.to ? `${r.from} → ${r.to}` : r.from}${r.registrationNo ? ` (${r.registrationNo})` : ''}`;

/** The English fallback for a line; apps describe `item` in the user's language. */
function describe(item: SettlementItem | null, late = false): string {
  if (!item) return '';
  let text: string;
  let trip: TripRef | null = null;
  switch (item.kind) {
    case 'trip':
      text = `${tripText(item.trip)}${item.cancelled ? ' (cancelled, cancellation fare)' : ''}`;
      break;
    case 'charge':
      text = `${item.chargeKind.replace('_', ' ')} ${rupees(item.amountPaise)}${item.paidByDriver ? ', paid by driver' : ''}`;
      trip = item.trip;
      break;
    case 'collection':
      text = `${item.method.toUpperCase()} collected ${rupees(item.amountPaise)}${item.reference ? ` (${item.reference})` : ''}`;
      trip = item.trip;
      break;
    case 'fuel_fill':
      text = `${item.fuel} ${(item.quantityMilli / 1000).toFixed(1)} ${item.fuel === 'cng' ? 'kg' : 'L'}, ${rupees(item.costPaise)}, ${item.paidBy.replace('_', ' ')}`;
      break;
  }
  return late ? `Late item: ${text}${trip ? ` for ${tripText(trip)}` : ''}` : text;
}

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
        const item = collectionItem(c, trip);
        lines.push({
          refType: 'adjustment',
          refId: c.id,
          amountPaise: amount,
          description: describe(item, true),
          item,
          originalDate: istBusinessDate(closedAt(trip)),
        });
      }
      for (const c of trip.charges.filter((x) => open(x.id))) {
        const amount = c.paidByDriver ? -Number(c.amountPaise) : 0;
        adjustments.push({ id: c.id, amountPaise: amount });
        const item = chargeItem(c, trip);
        lines.push({
          refType: 'adjustment',
          refId: c.id,
          amountPaise: amount,
          description: describe(item, true),
          item,
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
      trips.flatMap((t) => t.collections.map((c) => [c.id, { c, t }] as const)),
    );
    const fillById = new Map(fills.map((f) => [f.id, f]));
    for (const line of result.lines) {
      if (line.refType === 'adjustment') continue; // described above
      let item: SettlementItem | null = null;
      let originalDate: string | null = null;
      if (line.refType === 'trip') {
        const t = tripById.get(line.refId);
        if (t) {
          item = tripItem(t);
          const tripDay = istBusinessDate(closedAt(t));
          if (tripDay !== day) originalDate = tripDay;
        }
      } else if (line.refType === 'trip_charge') {
        const entry = chargeById.get(line.refId);
        if (entry) item = chargeItem(entry.c, entry.t);
      } else if (line.refType === 'collection') {
        const entry = collectionById.get(line.refId);
        if (entry) item = collectionItem(entry.c, entry.t);
      } else {
        const f = fillById.get(line.refId);
        if (f) {
          item = fillItem(f);
          const fillDay = istBusinessDate(f.filledAt);
          if (fillDay !== day) originalDate = fillDay;
        }
      }
      lines.push({ ...line, description: describe(item), item, originalDate });
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
      tx.trip.findMany({ where: { id: { in: ids } }, include: { vehicle: tripInclude.vehicle } }),
      tx.tripCharge.findMany({
        where: { id: { in: ids } },
        include: { trip: { include: { vehicle: tripInclude.vehicle } } },
      }),
      tx.tripCollection.findMany({
        where: { id: { in: ids } },
        include: { trip: { include: { vehicle: tripInclude.vehicle } } },
      }),
      tx.fuelFill.findMany({ where: { id: { in: ids } } }),
    ]);
    const itemFor = (refId: string): SettlementItem | null => {
      const t = trips.find((x) => x.id === refId);
      if (t) return tripItem(t);
      const c = charges.find((x) => x.id === refId);
      if (c) return chargeItem(c, c.trip);
      const col = collections.find((x) => x.id === refId);
      if (col) return collectionItem(col, col.trip);
      const f = fills.find((x) => x.id === refId);
      return f ? fillItem(f) : null;
    };
    return lines.map((l) => {
      const item = itemFor(l.refId);
      return {
        refType: l.refType as SettlementLineType,
        refId: l.refId,
        amountPaise: Number(l.amountPaise),
        description: describe(item, l.refType === 'adjustment'),
        item,
        originalDate: null,
      };
    });
  }
}
