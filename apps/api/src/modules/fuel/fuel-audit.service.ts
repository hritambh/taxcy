import { Injectable } from '@nestjs/common';
import type { Prisma, TenantTx } from '@taxcy/db';
import {
  auditVehicle,
  explainFuelCycle,
  explainInvalidCycle,
  trackFor,
  type AuditTrack,
  type Fill,
} from '@taxcy/domain';
import { newId } from '../../platform/ids.js';
import { AlertsRepository } from '../alerts/alerts.repository.js';
import { ReviewItemsRepository } from '../alerts/review-items.repository.js';
import { SettingsService } from '../fleet/settings.service.js';

/** Used when no org/model-specific default exists in fuel_baseline_defaults. */
const FALLBACK_SEEDS: Record<AuditTrack, { mean: number; std: number }> = {
  petrol: { mean: 14, std: 1.5 },
  diesel: { mean: 13, std: 1.3 },
  cng: { mean: 22, std: 2.5 },
  bifuel_cost: { mean: 420, std: 40 },
};

const FUEL_ALERT_KINDS = ['fuel_efficiency_low', 'fuel_cost_high'];
const alertKey = (closingFillId: string) => `fuel:${closingFillId}`;

/**
 * Recomputes a vehicle's fuel audit from scratch: every fill, every cycle, the
 * baseline, and the alerts and review items that follow from them. Cheap and
 * deterministic, so it simply reruns on every fill, void, late offline fill, or
 * reviewer decision. Previous cycle rows are kept with superseded_at set.
 */
@Injectable()
export class FuelAuditService {
  constructor(
    private readonly settings: SettingsService,
    private readonly alerts: AlertsRepository,
    private readonly reviews: ReviewItemsRepository,
  ) {}

  async recompute(tx: TenantTx, vehicleId: string): Promise<void> {
    // One recompute per vehicle at a time (two late fills syncing together).
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${vehicleId}))`;
    const vehicle = await tx.vehicle.findFirst({ where: { id: vehicleId, orgId: tx.orgId } });
    if (!vehicle) return;
    const track = trackFor(vehicle.fuelType);

    const rows = await tx.fuelFill.findMany({
      where: { vehicleId, orgId: tx.orgId, voidedAt: null },
      include: { odometer: { select: { typedKm: true } }, driver: { select: { name: true } } },
    });
    const fills: Fill[] = rows.map((r) => ({
      id: r.id,
      fuel: r.fuel,
      odometerKm: r.odometer.typedKm,
      quantityMilli: r.quantityMilli,
      costPaise: Number(r.costPaise),
      isFullTank: r.isFullTank,
      filledAt: r.filledAt,
    }));
    const byId = new Map(rows.map((r) => [r.id, r]));
    const { audit } = await this.settings.get(tx);
    const result = auditVehicle({
      fills,
      track,
      seed: await this.seedFor(tx, vehicle.vehicleModelId, track),
      settings: {
        kSigma: audit.fuelKSigma,
        minCycles: audit.fuelMinCycles,
        pctThreshold: audit.fuelPctThreshold,
        ewmaAlpha: audit.fuelEwmaAlpha,
      },
      acceptedClosingFillIds: await this.acceptedFalseAlarms(tx, vehicleId),
    });

    const now = new Date();
    await tx.fuelCycle.updateMany({
      where: { vehicleId, orgId: tx.orgId, supersededAt: null },
      data: { supersededAt: now },
    });
    if (result.cycles.length) {
      await tx.fuelCycle.createMany({
        data: result.cycles.map(({ cycle, evaluation, includedInBaseline }) => ({
          id: newId(),
          orgId: tx.orgId,
          vehicleId,
          track,
          openingFillId: cycle.openingFillId,
          closingFillId: cycle.closingFillId,
          distanceKm: cycle.distanceKm,
          fuelMilli: cycle.fuelMilli,
          costPaise: BigInt(cycle.costPaise),
          metric: cycle.metric,
          metricValue: cycle.value,
          baselineMean: evaluation.baselineMean,
          baselineStd: evaluation.baselineStd,
          priorCycles: evaluation.priorCycles,
          method: evaluation.method,
          deviation: evaluation.deviation,
          verdict: evaluation.verdict,
          includedInBaseline,
          computedAt: now,
        })),
      });
    }
    await tx.vehicleFuelBaseline.upsert({
      where: { vehicleId_track: { vehicleId, track } },
      update: {
        ewmaMean: result.baseline.mean,
        ewmaVar: result.baseline.variance,
        nCycles: result.baseline.n,
        updatedAt: now,
      },
      create: {
        vehicleId,
        track,
        orgId: tx.orgId,
        ewmaMean: result.baseline.mean,
        ewmaVar: result.baseline.variance,
        nCycles: result.baseline.n,
      },
    });

    const flagged = new Set<string>();
    for (const { cycle, evaluation } of result.cycles) {
      const key = alertKey(cycle.closingFillId);
      const cycleFills = cycle.fillIds.map((id) => byId.get(id)).filter((r) => r !== undefined);
      if (evaluation.verdict === 'flagged') {
        flagged.add(key);
        const text = explainFuelCycle({
          cycle,
          evaluation,
          vehicle: {
            registrationNo: vehicle.registrationNo,
            model: vehicle.model,
            fuelType: vehicle.fuelType,
          },
          driverNames: [
            ...new Set(cycleFills.map((f) => f.driver?.name).filter((n): n is string => !!n)),
          ],
          petrolCostPaise: cycleFills
            .filter((f) => f.fuel === 'petrol')
            .reduce((sum, f) => sum + Number(f.costPaise), 0),
        });
        await this.alerts.raise(tx, {
          kind: cycle.metric === 'paise_per_km' ? 'fuel_cost_high' : 'fuel_efficiency_low',
          severity: evaluation.severity ?? 'warning',
          ...text,
          subjectType: 'fuel_cycle',
          subjectId: cycle.closingFillId,
          vehicleId,
          driverId: cycleFills.at(-1)?.driverId ?? null,
          data: {
            closingFillId: cycle.closingFillId,
            openingFillId: cycle.openingFillId,
            metric: cycle.metric,
            value: cycle.value,
            baselineMean: evaluation.baselineMean,
            deviation: evaluation.deviation,
            method: evaluation.method,
          } satisfies Prisma.InputJsonObject,
          dedupeKey: key,
        });
      }
      if (evaluation.verdict === 'invalid' && evaluation.invalidReason) {
        await this.reviews.raise(tx, {
          kind:
            evaluation.invalidReason === 'odometer_not_increasing'
              ? 'odometer_regression'
              : 'implausible_efficiency',
          subjectType: 'fuel_cycle',
          subjectId: cycle.closingFillId,
          typedValue: cycle.value === null ? null : cycle.value.toFixed(2),
          context: {
            reason: explainInvalidCycle(evaluation.invalidReason),
            reasonCode: evaluation.invalidReason,
            vehicleId,
            openingFillId: cycle.openingFillId,
            distanceKm: cycle.distanceKm,
          },
        });
      } else {
        await this.reviews.autoResolve(
          tx,
          'implausible_efficiency',
          'fuel_cycle',
          cycle.closingFillId,
        );
        await this.reviews.autoResolve(
          tx,
          'odometer_regression',
          'fuel_cycle',
          cycle.closingFillId,
        );
      }
    }
    // Resolve fuel alerts for cycles that are no longer flagged (or no longer exist).
    const stale = await tx.alert.findMany({
      where: {
        orgId: tx.orgId,
        vehicleId,
        kind: { in: FUEL_ALERT_KINDS },
        status: { in: ['open', 'acknowledged'] },
      },
      select: { dedupeKey: true },
    });
    for (const alert of stale)
      if (!flagged.has(alert.dedupeKey)) await this.alerts.autoResolve(tx, alert.dedupeKey);
  }

  /** Most specific default first: org+model, global+model, org fuel-only, global fuel-only. */
  private async seedFor(
    tx: TenantTx,
    vehicleModelId: string | null,
    track: AuditTrack,
  ): Promise<{ mean: number; std: number }> {
    const candidates = await tx.fuelBaselineDefault.findMany({
      where: {
        track,
        OR: [{ orgId: tx.orgId }, { orgId: null }],
        AND: [{ OR: [{ vehicleModelId: null }, ...(vehicleModelId ? [{ vehicleModelId }] : [])] }],
      },
    });
    const score = (c: (typeof candidates)[number]) =>
      (c.vehicleModelId ? 2 : 0) + (c.orgId ? 1 : 0);
    const best = candidates.sort((a, b) => score(b) - score(a))[0];
    return best ? { mean: best.meanValue, std: best.stdValue } : FALLBACK_SEEDS[track];
  }

  /** Flagged cycles an owner dismissed as false alarms; these train the baseline. */
  private async acceptedFalseAlarms(tx: TenantTx, vehicleId: string): Promise<Set<string>> {
    const dismissed = await tx.alert.findMany({
      where: {
        orgId: tx.orgId,
        vehicleId,
        kind: { in: FUEL_ALERT_KINDS },
        status: 'dismissed',
        data: { path: ['falsePositive'], equals: true },
      },
      select: { subjectId: true },
    });
    return new Set(dismissed.map((a) => a.subjectId));
  }
}
