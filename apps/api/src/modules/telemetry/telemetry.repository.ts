import { Injectable } from '@nestjs/common';
import type { TenantTx } from '@taxcy/db';
import type { GpsPoint } from '@taxcy/domain';

export interface PointInput {
  id: string;
  recordedAt: Date;
  lat: number;
  lng: number;
  accuracyM?: number | undefined;
  speedMps?: number | undefined;
  heading?: number | undefined;
  isMock?: boolean | undefined;
}

/** gps_points is partitioned and not modelled by Prisma, so it's accessed with SQL here. */
@Injectable()
export class TelemetryRepository {
  /** Inserts points, skipping ones already stored (same recorded_at + client id). Returns rows inserted. */
  async insertPoints(
    tx: TenantTx,
    tripId: string,
    driverId: string,
    points: readonly PointInput[],
  ): Promise<number> {
    if (!points.length) return 0;
    return tx.$executeRaw`
      INSERT INTO gps_points (org_id, trip_id, driver_id, client_point_id, recorded_at, location, accuracy_m, speed_mps, heading, is_mock)
      SELECT ${tx.orgId}::uuid, ${tripId}::uuid, ${driverId}::uuid, p.id, p.ts,
             ST_SetSRID(ST_MakePoint(p.lng, p.lat), 4326)::geography, p.acc, p.spd, p.hdg, p.mock
      FROM unnest(
        ${points.map((p) => p.id)}::uuid[],
        ${points.map((p) => p.recordedAt)}::timestamptz[],
        ${points.map((p) => p.lat)}::float8[],
        ${points.map((p) => p.lng)}::float8[],
        ${points.map((p) => p.accuracyM ?? null)}::real[],
        ${points.map((p) => p.speedMps ?? null)}::real[],
        ${points.map((p) => p.heading ?? null)}::real[],
        ${points.map((p) => p.isMock ?? false)}::boolean[]
      ) AS p(id, ts, lat, lng, acc, spd, hdg, mock)
      ON CONFLICT DO NOTHING`;
  }

  async pointsForTrip(tx: TenantTx, tripId: string): Promise<GpsPoint[]> {
    const rows = await tx.$queryRaw<
      {
        id: string;
        recorded_at: Date;
        lat: number;
        lng: number;
        accuracy_m: number | null;
        is_mock: boolean;
      }[]
    >`
      SELECT client_point_id AS id, recorded_at, ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
             accuracy_m, is_mock
      FROM gps_points WHERE trip_id = ${tripId}::uuid AND org_id = ${tx.orgId}::uuid
      ORDER BY recorded_at`;
    return rows.map((r) => ({
      id: r.id,
      recordedAt: r.recorded_at,
      lat: r.lat,
      lng: r.lng,
      accuracyM: r.accuracy_m,
      isMock: r.is_mock,
    }));
  }

  /** Length of the line through the given points (in time order) on the spheroid, in km. */
  async lineLengthKm(tx: TenantTx, tripId: string, pointIds: readonly string[]): Promise<number> {
    if (pointIds.length < 2) return 0;
    const rows = await tx.$queryRaw<{ km: number | null }[]>`
      SELECT ST_Length(ST_MakeLine(location::geometry ORDER BY recorded_at)::geography) / 1000.0 AS km
      FROM gps_points
      WHERE trip_id = ${tripId}::uuid AND org_id = ${tx.orgId}::uuid AND client_point_id = ANY(${pointIds}::uuid[])`;
    return rows[0]?.km ?? 0;
  }
}
