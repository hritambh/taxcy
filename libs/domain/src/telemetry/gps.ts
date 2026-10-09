export interface GpsPoint {
  id: string;
  recordedAt: Date;
  lat: number;
  lng: number;
  accuracyM: number | null;
  isMock: boolean;
}

export interface FilterOptions {
  /** Points less accurate than this are dropped. Default 100 m. */
  maxAccuracyM: number;
  /** A point implying a faster jump from the previous kept point is dropped. Default 150 km/h. */
  maxSpeedKmh: number;
}

export const DEFAULT_FILTER: FilterOptions = { maxAccuracyM: 100, maxSpeedKmh: 150 };

export interface FilterResult {
  kept: GpsPoint[];
  dropped: { inaccurate: number; mock: number; duplicate: number; impossibleSpeed: number };
}

const EARTH_RADIUS_KM = 6371.0088;
const rad = (deg: number) => (deg * Math.PI) / 180;

/** Great-circle distance in km. PostGIS computes the authoritative distance; this is for checks and tests. */
export function haversineKm(
  a: Pick<GpsPoint, 'lat' | 'lng'>,
  b: Pick<GpsPoint, 'lat' | 'lng'>,
): number {
  const dLat = rad(b.lat - a.lat);
  const dLng = rad(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(h)));
}

export function pathLengthKm(points: readonly Pick<GpsPoint, 'lat' | 'lng'>[]): number {
  let total = 0;
  for (let i = 1; i < points.length; i++) {
    const prev = points[i - 1];
    const curr = points[i];
    if (prev && curr) total += haversineKm(prev, curr);
  }
  return total;
}

/**
 * Drops obviously bad points: poor accuracy, mock locations, duplicate timestamps,
 * and teleports (implied speed from the last kept point above the limit).
 */
export function filterPoints(
  points: readonly GpsPoint[],
  options: FilterOptions = DEFAULT_FILTER,
): FilterResult {
  const sorted = [...points].sort((a, b) => a.recordedAt.getTime() - b.recordedAt.getTime());
  const dropped = { inaccurate: 0, mock: 0, duplicate: 0, impossibleSpeed: 0 };
  const kept: GpsPoint[] = [];
  for (const point of sorted) {
    if (point.isMock) {
      dropped.mock++;
      continue;
    }
    if (point.accuracyM !== null && point.accuracyM > options.maxAccuracyM) {
      dropped.inaccurate++;
      continue;
    }
    const last = kept.at(-1);
    if (last) {
      const seconds = (point.recordedAt.getTime() - last.recordedAt.getTime()) / 1000;
      if (seconds <= 0) {
        dropped.duplicate++;
        continue;
      }
      if ((haversineKm(last, point) / seconds) * 3600 > options.maxSpeedKmh) {
        dropped.impossibleSpeed++;
        continue;
      }
    }
    kept.push(point);
  }
  return { kept, dropped };
}

export interface Coverage {
  /** Share of the trip's duration covered by point-to-point intervals no longer than the gap limit. */
  coverageRatio: number;
  maxGapSeconds: number;
}

/**
 * How continuously the phone tracked the trip. Gaps (from the trip start to the first
 * point, between points, and from the last point to the trip end) longer than
 * `gapSeconds` count as uncovered. The line between points across a gap still
 * contributes straight-line distance, a lower bound on the road distance.
 */
export function coverage(
  kept: readonly GpsPoint[],
  startedAt: Date,
  endedAt: Date,
  gapSeconds = 300,
): Coverage {
  const duration = (endedAt.getTime() - startedAt.getTime()) / 1000;
  if (duration <= 0) return { coverageRatio: kept.length ? 1 : 0, maxGapSeconds: 0 };
  const marks = [startedAt.getTime(), ...kept.map((p) => p.recordedAt.getTime()), endedAt.getTime()]
    .map((t) => Math.min(Math.max(t, startedAt.getTime()), endedAt.getTime()))
    .sort((a, b) => a - b);
  let covered = 0;
  let maxGap = 0;
  for (let i = 1; i < marks.length; i++) {
    const gap = ((marks[i] ?? 0) - (marks[i - 1] ?? 0)) / 1000;
    maxGap = Math.max(maxGap, gap);
    if (gap <= gapSeconds) covered += gap;
  }
  return { coverageRatio: Math.min(covered / duration, 1), maxGapSeconds: Math.round(maxGap) };
}
