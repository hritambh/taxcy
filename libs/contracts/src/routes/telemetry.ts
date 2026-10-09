import { z } from 'zod';
import { DateTime, Id } from '../common.js';
import { access, defineRoute } from '../http.js';

export const GpsPointInput = z.object({
  /** Client UUID; re-sending a batch is safe. */
  id: Id,
  recordedAt: DateTime,
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  accuracyM: z.number().nonnegative().optional(),
  speedMps: z.number().nonnegative().optional(),
  heading: z.number().min(0).max(360).optional(),
  isMock: z.boolean().optional(),
});

export const DistanceCheck = z.object({
  tripId: Id,
  odometerKm: z.number().int(),
  gpsKm: z.number().nullable(),
  pointsTotal: z.number().int().nullable(),
  pointsUsed: z.number().int().nullable(),
  maxGapSeconds: z.number().int().nullable(),
  coverageRatio: z.number().nullable(),
  /** ok, flagged (odometer well above GPS), or inconclusive (GPS too patchy to judge). */
  result: z.enum(['ok', 'flagged', 'inconclusive']),
  computedAt: DateTime,
});

export const telemetryRoutes = {
  uploadBatch: defineRoute({
    method: 'POST',
    path: '/trips/{id}/gps-batches',
    summary: 'Upload recorded GPS points for a trip (deduplicated by point id)',
    tag: 'telemetry',
    access: access.anyMember,
    params: z.object({ id: Id }),
    body: z.object({ points: z.array(GpsPointInput).min(1).max(500) }),
    response: z.object({
      accepted: z.number().int(),
      duplicates: z.number().int(),
      /** Points outside the trip's time window (start − 5 min to end + 30 min). */
      outOfWindow: z.number().int(),
    }),
  }),
  route: defineRoute({
    method: 'GET',
    path: '/trips/{id}/route',
    summary: 'The cleaned GPS route of a trip (bad points removed, thinned for display)',
    tag: 'telemetry',
    access: access.anyMember,
    params: z.object({ id: Id }),
    response: z.object({
      points: z.array(z.object({ lat: z.number(), lng: z.number(), recordedAt: DateTime })),
      dropped: z.object({
        inaccurate: z.number().int(),
        mock: z.number().int(),
        duplicate: z.number().int(),
        impossibleSpeed: z.number().int(),
      }),
    }),
  }),
  distanceCheck: defineRoute({
    method: 'GET',
    path: '/trips/{id}/distance-check',
    summary: 'Odometer vs GPS distance verdict (null until the trip ends)',
    tag: 'telemetry',
    access: access.staff,
    params: z.object({ id: Id }),
    response: DistanceCheck.nullable(),
  }),
};
