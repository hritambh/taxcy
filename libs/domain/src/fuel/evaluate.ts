import { effectiveStd, type Baseline } from './baseline.js';
import type { Cycle } from './cycles.js';
import type { AuditSettings } from './types.js';

export type Verdict = 'ok' | 'flagged' | 'invalid';
export type Severity = 'warning' | 'critical';
export type InvalidReason =
  'odometer_not_increasing' | 'implausibly_good' | 'distance_too_long' | 'no_fuel';

/** A cycle longer than this almost certainly spans missed fill logs. */
export const MAX_CYCLE_KM = 3000;
/** Values this much better than baseline usually mean a fill wasn't logged. */
export const IMPLAUSIBLY_GOOD_FACTOR = 1.5;

export interface Evaluation {
  verdict: Verdict;
  method: 'sigma' | 'percent';
  /** sigma: standard deviations in the bad direction; percent: % worse than baseline. */
  deviation: number | null;
  severity: Severity | null;
  invalidReason: InvalidReason | null;
  /** Baseline the cycle was judged against (before this cycle). */
  baselineMean: number;
  baselineStd: number;
  priorCycles: number;
  /** Percent worse than the baseline mean (positive = worse), for explanations. */
  percentWorse: number | null;
}

/**
 * Judges one cycle against the vehicle's baseline.
 *
 * - invalid: distance ≤ 0, > 3,000 km, no fuel, or implausibly good (likely a
 *   missed fill). These go to the review queue, not the alerts inbox.
 * - with ≥ minCycles accepted cycles: flag when worse than baseline by > k·σ.
 * - before that: flag when worse than the baseline mean by > pctThreshold %.
 *
 * "Worse" is lower km/unit, or higher paise/km for bi-fuel cost tracking.
 */
export function evaluateCycle(
  cycle: Cycle,
  baseline: Baseline,
  settings: AuditSettings,
): Evaluation {
  const std = effectiveStd(baseline);
  const method = baseline.n >= settings.minCycles ? 'sigma' : 'percent';
  const base = {
    method,
    baselineMean: baseline.mean,
    baselineStd: std,
    priorCycles: baseline.n,
  } as const;
  const invalid = (reason: InvalidReason): Evaluation => ({
    ...base,
    verdict: 'invalid',
    deviation: null,
    severity: null,
    invalidReason: reason,
    percentWorse: null,
  });

  if (cycle.distanceKm <= 0) return invalid('odometer_not_increasing');
  if (cycle.distanceKm > MAX_CYCLE_KM) return invalid('distance_too_long');
  if (cycle.value === null) return invalid('no_fuel');

  const higherIsBetter = cycle.metric === 'km_per_unit';
  const x = cycle.value;
  const implausiblyGood = higherIsBetter
    ? x > baseline.mean * IMPLAUSIBLY_GOOD_FACTOR
    : x < baseline.mean / IMPLAUSIBLY_GOOD_FACTOR;
  if (implausiblyGood) return invalid('implausibly_good');

  const worseBy = higherIsBetter ? baseline.mean - x : x - baseline.mean;
  const percentWorse = (worseBy / baseline.mean) * 100;

  const deviation = method === 'sigma' ? worseBy / std : percentWorse;
  const threshold = method === 'sigma' ? settings.kSigma : settings.pctThreshold;
  // Exactly at the threshold is fine; the epsilon absorbs floating-point noise (20.000000000000004%).
  if (deviation <= threshold + 1e-9) {
    return { ...base, verdict: 'ok', deviation, severity: null, invalidReason: null, percentWorse };
  }
  return {
    ...base,
    verdict: 'flagged',
    deviation,
    severity: deviation > threshold * 1.5 ? 'critical' : 'warning',
    invalidReason: null,
    percentWorse,
  };
}
