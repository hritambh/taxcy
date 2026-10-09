import { Injectable } from '@nestjs/common';
import type { FuelFill } from '@taxcy/contracts';
import type { Prisma, TenantTx } from '@taxcy/db';
import { allowedFuels, metricFor, trackFor, type FuelKind } from '@taxcy/domain';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { AppError, notFound } from '../../platform/errors.js';
import { publish } from '../../platform/outbox.js';
import { Db } from '../../platform/prisma.service.js';
import { EvidenceReconciler } from '../media/evidence.reconciler.js';

const fillInclude = {
  odometer: true,
  driver: { select: { name: true } },
} as const satisfies Prisma.FuelFillInclude;

type FillRow = Prisma.FuelFillGetPayload<{ include: typeof fillInclude }>;

export interface RecordFillInput {
  id: string;
  vehicleId: string;
  tripId?: string | undefined;
  driverId?: string | undefined;
  fuel: FuelKind;
  quantityMilli: number;
  costPaise: number;
  odometer: { id: string; typedKm: number; mediaId: string; capturedAt: Date };
  isFullTank: boolean;
  receiptMediaId?: string | undefined;
  paidBy: 'driver_cash' | 'owner' | 'fuel_card';
  filledAt: Date;
}

function toFill(row: FillRow): FuelFill {
  return {
    id: row.id,
    vehicleId: row.vehicleId,
    driverId: row.driverId,
    driverName: row.driver?.name ?? null,
    tripId: row.tripId,
    fuel: row.fuel,
    quantityMilli: row.quantityMilli,
    unit: row.fuel === 'cng' ? 'kg' : 'L',
    costPaise: Number(row.costPaise),
    odometer: {
      id: row.odometer.id,
      typedKm: row.odometer.typedKm,
      ocrKm: row.odometer.ocrKm,
      mediaId: row.odometer.mediaId,
      capturedAt: row.odometer.capturedAt,
    },
    isFullTank: row.isFullTank,
    receiptMediaId: row.receiptMediaId,
    ocrCostPaise: row.ocrCostPaise === null ? null : Number(row.ocrCostPaise),
    paidBy: row.paidBy as FuelFill['paidBy'],
    filledAt: row.filledAt,
    voidedAt: row.voidedAt,
    createdAt: row.createdAt,
  };
}

@Injectable()
export class FuelService {
  constructor(
    private readonly db: Db,
    private readonly evidence: EvidenceReconciler,
  ) {}

  /** Idempotent on the client's id: a replayed sync returns the original fill. */
  async record(auth: TenantAuth, input: RecordFillInput): Promise<FuelFill> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const existing = await tx.fuelFill.findFirst({
        where: { id: input.id, orgId: tx.orgId },
        include: fillInclude,
      });
      if (existing) {
        const same =
          existing.vehicleId === input.vehicleId &&
          existing.quantityMilli === input.quantityMilli &&
          Number(existing.costPaise) === input.costPaise &&
          existing.isFullTank === input.isFullTank;
        if (!same)
          throw new AppError(
            'IDEMPOTENCY_CONFLICT',
            'This fill id was already recorded with different values',
          );
        return toFill(existing);
      }

      const vehicle = await tx.vehicle.findFirst({
        where: { id: input.vehicleId, orgId: tx.orgId },
      });
      if (!vehicle) throw notFound('Vehicle');
      if (!allowedFuels(vehicle.fuelType).includes(input.fuel)) {
        throw new AppError(
          'FUEL_TYPE_MISMATCH',
          `${vehicle.registrationNo} runs on ${vehicle.fuelType.replace('_', ' + ')}, not ${input.fuel}`,
        );
      }
      const driverId = await this.resolveDriver(tx, auth, input.driverId);
      for (const mediaId of [input.odometer.mediaId, input.receiptMediaId].filter(
        (m): m is string => !!m,
      )) {
        if (!(await tx.mediaObject.count({ where: { id: mediaId, orgId: tx.orgId } }))) {
          throw new AppError(
            'VALIDATION_FAILED',
            'Register the photo (POST /media) before using it',
          );
        }
      }
      const odometerExists = await tx.odometerReading.count({ where: { id: input.odometer.id } });
      if (!odometerExists) {
        await tx.odometerReading.create({
          data: {
            id: input.odometer.id,
            orgId: tx.orgId,
            vehicleId: vehicle.id,
            context: 'fuel_fill',
            typedKm: input.odometer.typedKm,
            mediaId: input.odometer.mediaId,
            capturedAt: input.odometer.capturedAt,
            createdBy: auth.userId,
          },
        });
      }
      if (vehicle.lastOdometerKm === null || input.odometer.typedKm > vehicle.lastOdometerKm) {
        await tx.vehicle.update({
          where: { id: vehicle.id },
          data: { lastOdometerKm: input.odometer.typedKm },
        });
      }
      await tx.fuelFill.create({
        data: {
          id: input.id,
          orgId: tx.orgId,
          vehicleId: vehicle.id,
          driverId,
          tripId: input.tripId ?? null,
          fuel: input.fuel,
          quantityMilli: input.quantityMilli,
          costPaise: BigInt(input.costPaise),
          odometerId: input.odometer.id,
          isFullTank: input.isFullTank,
          receiptMediaId: input.receiptMediaId ?? null,
          paidBy: input.paidBy,
          filledAt: input.filledAt,
        },
      });
      await this.evidence.reconcileOdometerMedia(tx, input.odometer.mediaId);
      if (input.receiptMediaId) await this.evidence.reconcileReceiptMedia(tx, input.receiptMediaId);
      await publish(tx, 'fuel.fill_recorded', { vehicleId: vehicle.id, fillId: input.id });
      return this.require(tx, input.id);
    });
  }

  async list(
    auth: TenantAuth,
    q: {
      vehicleId?: string | undefined;
      driverId?: string | undefined;
      from?: Date | undefined;
      to?: Date | undefined;
      includeVoided?: boolean | undefined;
      limit: number;
    },
  ): Promise<FuelFill[]> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const rows = await tx.fuelFill.findMany({
        where: {
          orgId: tx.orgId,
          ...(q.vehicleId ? { vehicleId: q.vehicleId } : {}),
          ...(q.driverId ? { driverId: q.driverId } : {}),
          ...(q.includeVoided ? {} : { voidedAt: null }),
          ...(q.from || q.to
            ? { filledAt: { ...(q.from ? { gte: q.from } : {}), ...(q.to ? { lt: q.to } : {}) } }
            : {}),
        },
        include: fillInclude,
        orderBy: { filledAt: 'desc' },
        take: q.limit,
      });
      return rows.map(toFill);
    });
  }

  async void(auth: TenantAuth, id: string, reason: string): Promise<FuelFill> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const fill = await tx.fuelFill.findFirst({ where: { id, orgId: tx.orgId } });
      if (!fill) throw notFound('Fuel fill');
      if (await tx.settlementLine.count({ where: { refType: 'fuel_fill', refId: id } })) {
        throw new AppError(
          'ALREADY_SETTLED',
          'This fill is part of a settled day and cannot be voided',
        );
      }
      if (!fill.voidedAt) {
        await tx.fuelFill.update({ where: { id }, data: { voidedAt: new Date() } });
        await publish(tx, 'fuel.fill_recorded', {
          vehicleId: fill.vehicleId,
          fillId: id,
          voided: true,
          reason,
        });
      }
      return this.require(tx, id);
    });
  }

  async vehicleAudit(auth: TenantAuth, vehicleId: string) {
    return this.db.tenant(auth.orgId, async (tx) => {
      const vehicle = await tx.vehicle.findFirst({
        where: { id: vehicleId, orgId: tx.orgId },
        select: { fuelType: true },
      });
      if (!vehicle) throw notFound('Vehicle');
      const track = trackFor(vehicle.fuelType);
      const [cycles, baseline] = await Promise.all([
        tx.fuelCycle.findMany({
          where: { vehicleId, orgId: tx.orgId, supersededAt: null },
          orderBy: { computedAt: 'asc' },
        }),
        tx.vehicleFuelBaseline.findUnique({ where: { vehicleId_track: { vehicleId, track } } }),
      ]);
      const fills = await tx.fuelFill.findMany({
        where: { id: { in: cycles.flatMap((c) => [c.openingFillId, c.closingFillId]) } },
        select: { id: true, filledAt: true },
      });
      const filledAt = new Map(fills.map((f) => [f.id, f.filledAt]));
      return {
        vehicleId,
        track,
        metric: metricFor(track),
        unitLabel: track === 'bifuel_cost' ? '₹/km' : track === 'cng' ? 'km/kg' : 'km/L',
        baseline: baseline
          ? { mean: baseline.ewmaMean, std: Math.sqrt(baseline.ewmaVar), cycles: baseline.nCycles }
          : null,
        cycles: cycles
          .map((c) => ({
            id: c.id,
            openingFillId: c.openingFillId,
            closingFillId: c.closingFillId,
            startedAt: filledAt.get(c.openingFillId) ?? c.computedAt,
            endedAt: filledAt.get(c.closingFillId) ?? c.computedAt,
            distanceKm: c.distanceKm,
            fuelMilli: c.fuelMilli,
            costPaise: Number(c.costPaise),
            metric: c.metric as 'km_per_unit' | 'paise_per_km',
            metricValue: c.metricValue,
            baselineMean: c.baselineMean,
            baselineStd: c.baselineStd,
            priorCycles: c.priorCycles,
            method: c.method as 'sigma' | 'percent',
            deviation: c.deviation,
            verdict: c.verdict as 'ok' | 'flagged' | 'invalid',
            includedInBaseline: c.includedInBaseline,
          }))
          .sort((a, b) => a.endedAt.getTime() - b.endedAt.getTime()),
      };
    });
  }

  /** Drivers record fills as themselves; staff may name the driver. */
  private async resolveDriver(
    tx: TenantTx,
    auth: TenantAuth,
    requested: string | undefined,
  ): Promise<string | null> {
    const isStaff = auth.roles.includes('owner') || auth.roles.includes('manager');
    const own = await tx.driver.findFirst({
      where: { orgId: tx.orgId, userId: auth.userId },
      select: { id: true },
    });
    if (!isStaff) {
      if (!own) throw new AppError('FORBIDDEN_ROLE', 'Only drivers and staff can record fills');
      return own.id;
    }
    if (requested) {
      if (!(await tx.driver.count({ where: { id: requested, orgId: tx.orgId } })))
        throw notFound('Driver');
      return requested;
    }
    return own?.id ?? null;
  }

  private async require(tx: TenantTx, id: string): Promise<FuelFill> {
    const row = await tx.fuelFill.findFirst({
      where: { id, orgId: tx.orgId },
      include: fillInclude,
    });
    if (!row) throw notFound('Fuel fill');
    return toFill(row);
  }
}
