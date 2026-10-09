/** Exponentially weighted mean and variance of accepted cycle values. */
export interface Baseline {
  mean: number;
  variance: number;
  /** Accepted cycles folded in so far (the seed doesn't count). */
  n: number;
}

export function seedBaseline(mean: number, std: number): Baseline {
  return { mean, variance: std * std, n: 0 };
}

/**
 * Incremental EWMA update (West/Finch):
 *   δ = x − mean;  mean' = mean + αδ;  var' = (1 − α)(var + αδ²)
 */
export function updateBaseline(baseline: Baseline, x: number, alpha: number): Baseline {
  const delta = x - baseline.mean;
  return {
    mean: baseline.mean + alpha * delta,
    variance: (1 - alpha) * (baseline.variance + alpha * delta * delta),
    n: baseline.n + 1,
  };
}

/**
 * Standard deviation used for flagging. Floored at 3% of the mean so a run of near-
 * identical cycles can't shrink σ to almost zero and turn ordinary noise into alerts.
 */
export function effectiveStd(baseline: Baseline): number {
  return Math.max(Math.sqrt(baseline.variance), Math.abs(baseline.mean) * 0.03);
}
