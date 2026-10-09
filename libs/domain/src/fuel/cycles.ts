import { metricFor, type AuditTrack, type Fill, type Metric } from './types.js';

export interface Cycle {
  track: AuditTrack;
  openingFillId: string;
  closingFillId: string;
  /** Fills counted in the cycle: after the opening fill, up to and including the closing fill. */
  fillIds: string[];
  startedAt: Date;
  endedAt: Date;
  distanceKm: number;
  /** Fuel used (ml or g); null for bi-fuel cycles, where units are mixed. */
  fuelMilli: number | null;
  costPaise: number;
  metric: Metric;
  /** km per litre/kg, or paise per km. Null when distance or fuel is zero or negative. */
  value: number | null;
}

function chronological(a: Fill, b: Fill): number {
  return a.filledAt.getTime() - b.filledAt.getTime() || a.odometerKm - b.odometerKm;
}

/**
 * Full-tank-to-full-tank cycles.
 *
 * Single-fuel tracks: a cycle runs between consecutive full fills of that fuel.
 * Distance is the odometer difference; fuel is the sum of every fill after the
 * opening full fill up to and including the closing one (partials in between
 * count); efficiency = distance / fuel. Fills before the first full fill are
 * ignored, because the starting level is unknown.
 *
 * Bi-fuel (bifuel_cost): anchors are consecutive full CNG fills, and the metric is
 * the cost of every fill of either fuel in the cycle divided by distance.
 */
export function buildCycles(fills: readonly Fill[], track: AuditTrack): Cycle[] {
  const sorted = [...fills].sort(chronological);
  const anchorFuel = track === 'bifuel_cost' ? 'cng' : track;
  const counts = (fill: Fill) => track === 'bifuel_cost' || fill.fuel === track;
  const isAnchor = (fill: Fill) => fill.fuel === anchorFuel && fill.isFullTank;

  const cycles: Cycle[] = [];
  let opening: Fill | undefined;
  let pending: Fill[] = [];

  for (const fill of sorted) {
    if (!counts(fill)) continue;
    if (!opening) {
      if (isAnchor(fill)) opening = fill;
      continue;
    }
    pending.push(fill);
    if (!isAnchor(fill)) continue;

    const distanceKm = fill.odometerKm - opening.odometerKm;
    const costPaise = pending.reduce((sum, f) => sum + f.costPaise, 0);
    const fuelMilli =
      track === 'bifuel_cost' ? null : pending.reduce((sum, f) => sum + f.quantityMilli, 0);
    const metric = metricFor(track);
    let value: number | null = null;
    if (distanceKm > 0) {
      if (metric === 'km_per_unit' && fuelMilli !== null && fuelMilli > 0)
        value = distanceKm / (fuelMilli / 1000);
      if (metric === 'paise_per_km') value = costPaise / distanceKm;
    }
    cycles.push({
      track,
      openingFillId: opening.id,
      closingFillId: fill.id,
      fillIds: pending.map((f) => f.id),
      startedAt: opening.filledAt,
      endedAt: fill.filledAt,
      distanceKm,
      fuelMilli,
      costPaise,
      metric,
      value,
    });
    opening = fill;
    pending = [];
  }
  return cycles;
}
