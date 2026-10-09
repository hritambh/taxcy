import { Injectable, Logger, type OnApplicationBootstrap } from '@nestjs/common';
import type { TenantTx } from '@taxcy/db';
import { coverage, explainOdoGps, filterPoints, odoGpsVerdict } from '@taxcy/domain';
import { z } from 'zod';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { notFound } from '../../platform/errors.js';
import { OnJob, type JobEvent } from '../../platform/jobs/on-job.js';
import { publish } from '../../platform/outbox.js';
import { Db } from '../../platform/prisma.service.js';
import { AlertsRepository } from '../alerts/alerts.repository.js';
import { ReviewItemsRepository } from '../alerts/review-items.repository.js';
import { SettingsService } from '../fleet/settings.service.js';
import { TelemetryRepository, type PointInput } from './telemetry.repository.js';

const BEFORE_START_MS = 5 * 60_000;
const AFTER_END_MS = 30 * 60_000;
const MAX_ROUTE_POINTS = 1_000;
const GPS_RETENTION_MONTHS = 12;

const TripClosed = z.object({ tripId: z.uuid() });
const DistanceResult = z.enum(['ok', 'flagged', 'inconclusive']);

const monthStart = (date: Date, offsetMonths = 0) =>
  new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + offsetMonths, 1))
    .toISOString()
    .slice(0, 10);

@Injectable()
export class TelemetryService implements OnApplicationBootstrap {
  private readonly logger = new Logger('TelemetryService');

  constructor(
    private readonly db: Db,
    private readonly repo: TelemetryRepository,
    private readonly settings: SettingsService,
    private readonly alerts: AlertsRepository,
    private readonly reviews: ReviewItemsRepository,
  ) {}

  /** Make sure this month's and the next two months' partitions exist before any points arrive. */
  async onApplicationBootstrap(): Promise<void> {
    await this.ensurePartitions();
  }

  @OnJob('telemetry.gps_partitions')
  async maintainPartitions(): Promise<void> {
    await this.ensurePartitions();
    const dropped = await this.db.system(async (tx) => {
      const rows = await tx.$queryRaw<{ n: number }[]>`
        SELECT drop_gps_partitions_before(${monthStart(new Date(), -GPS_RETENTION_MONTHS)}::date) AS n`;
      return rows[0]?.n ?? 0;
    });
    if (dropped)
      this.logger.log(
        `dropped ${dropped} GPS partitions older than ${GPS_RETENTION_MONTHS} months`,
      );
  }

  private async ensurePartitions(): Promise<void> {
    await this.db.system(async (tx) => {
      for (const offset of [0, 1, 2]) {
        await tx.$queryRaw`SELECT ensure_gps_partition(${monthStart(new Date(), offset)}::date)`;
      }
    });
  }

  /**
   * Stores a batch from the driver app. Only the trip's driver (or staff) may upload,
   * only points inside the trip's time window are kept, and re-sent points are
   * ignored. Points arriving after the trip closed re-run its distance check.
   */
  async ingest(auth: TenantAuth, tripId: string, points: readonly PointInput[]) {
    return this.db.tenant(auth.orgId, async (tx) => {
      const trip = await tx.trip.findFirst({
        where: { id: tripId, orgId: tx.orgId },
        include: { driver: { select: { id: true, userId: true } } },
      });
      const isStaff = auth.roles.includes('owner') || auth.roles.includes('manager');
      if (!trip?.driver || (!isStaff && trip.driver.userId !== auth.userId) || !trip.startedAt)
        throw notFound('Trip');

      const from = trip.startedAt.getTime() - BEFORE_START_MS;
      const closedAt = trip.endedAt ?? trip.cancelledAt;
      const to = (closedAt ?? new Date()).getTime() + AFTER_END_MS;
      const inWindow = points.filter(
        (p) => p.recordedAt.getTime() >= from && p.recordedAt.getTime() <= to,
      );
      const accepted = await this.repo.insertPoints(tx, trip.id, trip.driver.id, inWindow);
      if (accepted && closedAt) await publish(tx, 'trip.closed', { tripId: trip.id });
      return {
        accepted,
        duplicates: inWindow.length - accepted,
        outOfWindow: points.length - inWindow.length,
      };
    });
  }

  async route(auth: TenantAuth, tripId: string) {
    return this.db.tenant(auth.orgId, async (tx) => {
      const trip = await tx.trip.findFirst({
        where: { id: tripId, orgId: tx.orgId },
        include: { driver: { select: { userId: true } } },
      });
      const isStaff = auth.roles.includes('owner') || auth.roles.includes('manager');
      if (!trip || (!isStaff && trip.driver?.userId !== auth.userId)) throw notFound('Trip');
      const { kept, dropped } = filterPoints(await this.repo.pointsForTrip(tx, tripId));
      const step = Math.max(1, Math.ceil(kept.length / MAX_ROUTE_POINTS));
      const thinned = kept.filter((_, i) => i % step === 0 || i === kept.length - 1);
      return {
        points: thinned.map((p) => ({ lat: p.lat, lng: p.lng, recordedAt: p.recordedAt })),
        dropped,
      };
    });
  }

  async distanceCheck(auth: TenantAuth, tripId: string) {
    return this.db.tenant(auth.orgId, async (tx) => {
      if (!(await tx.trip.count({ where: { id: tripId, orgId: tx.orgId } })))
        throw notFound('Trip');
      const check = await tx.tripDistanceCheck.findFirst({ where: { tripId, orgId: tx.orgId } });
      return check ? { ...check, result: DistanceResult.parse(check.result) } : null;
    });
  }

  @OnJob('trip.closed')
  async onTripClosed(event: JobEvent): Promise<void> {
    if (!event.orgId) throw new Error('trip.closed without org');
    const { tripId } = TripClosed.parse(event.payload);
    await this.db.tenant(event.orgId, (tx) => this.checkDistance(tx, tripId));
  }

  /** Odometer distance vs the PostGIS length of the cleaned GPS track. */
  async checkDistance(tx: TenantTx, tripId: string): Promise<void> {
    const trip = await tx.trip.findFirst({
      where: { id: tripId, orgId: tx.orgId },
      include: { vehicle: { select: { registrationNo: true } } },
    });
    if (!trip?.startedAt || !trip.startOdometerId || !trip.endOdometerId) return;
    const readings = await tx.odometerReading.findMany({
      where: { id: { in: [trip.startOdometerId, trip.endOdometerId] } },
    });
    const startKm = readings.find((r) => r.id === trip.startOdometerId)?.typedKm;
    const endKm = readings.find((r) => r.id === trip.endOdometerId)?.typedKm;
    if (startKm === undefined || endKm === undefined) return;
    const closedAt = trip.endedAt ?? trip.cancelledAt ?? new Date();

    const raw = await this.repo.pointsForTrip(tx, tripId);
    const { kept, dropped } = filterPoints(raw);
    const cov = coverage(kept, trip.startedAt, closedAt);
    const gpsKm = await this.repo.lineLengthKm(
      tx,
      tripId,
      kept.map((p) => p.id),
    );
    const odometerKm = endKm - startKm;
    const { audit } = await this.settings.get(tx);
    const verdict = odoGpsVerdict({
      odometerKm,
      gpsKm,
      coverageRatio: cov.coverageRatio,
      pointsUsed: kept.length,
      tolerancePct: audit.odoGpsTolerancePct,
    });

    const check = {
      orgId: tx.orgId,
      odometerKm,
      gpsKm,
      pointsTotal: raw.length,
      pointsUsed: kept.length,
      maxGapSeconds: cov.maxGapSeconds,
      coverageRatio: cov.coverageRatio,
      result: verdict.result,
      computedAt: new Date(),
    };
    await tx.tripDistanceCheck.upsert({
      where: { tripId },
      update: check,
      create: { tripId, ...check },
    });

    const dedupeKey = `odo-gps:${tripId}`;
    if (verdict.result === 'flagged' && verdict.excessPct !== null) {
      const date = trip.startedAt.toLocaleDateString('en-IN', {
        day: 'numeric',
        month: 'short',
        timeZone: 'Asia/Kolkata',
      });
      const route = trip.toText ? `${trip.fromText} → ${trip.toText}` : trip.fromText;
      const text = explainOdoGps({
        tripLabel: `Trip on ${date} (${route}, ${trip.vehicle?.registrationNo ?? 'vehicle'})`,
        odometerKm,
        gpsKm,
        excessPct: verdict.excessPct,
        tolerancePct: audit.odoGpsTolerancePct,
      });
      await this.alerts.raise(tx, {
        kind: 'odo_gps_mismatch',
        severity: verdict.severity ?? 'warning',
        ...text,
        subjectType: 'trip',
        subjectId: tripId,
        tripId,
        vehicleId: trip.vehicleId,
        driverId: trip.driverId,
        data: { odometerKm, gpsKm, excessPct: verdict.excessPct, coverageRatio: cov.coverageRatio },
        dedupeKey,
      });
    } else {
      await this.alerts.autoResolve(tx, dedupeKey);
    }
    if (dropped.mock > 0) {
      await this.reviews.raise(tx, {
        kind: 'mock_location',
        subjectType: 'trip',
        subjectId: tripId,
        context: {
          mockPoints: dropped.mock,
          reason: 'The phone reported mock (fake) GPS locations during this trip',
        },
      });
    }
  }
}
