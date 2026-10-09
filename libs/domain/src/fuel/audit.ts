import { seedBaseline, updateBaseline, type Baseline } from './baseline.js';
import { buildCycles, type Cycle } from './cycles.js';
import { evaluateCycle, type Evaluation } from './evaluate.js';
import type { AuditSettings, AuditTrack, Fill } from './types.js';

export interface AuditedCycle {
  cycle: Cycle;
  evaluation: Evaluation;
  /** Whether this cycle's value was folded into the baseline. */
  includedInBaseline: boolean;
}

export interface VehicleAudit {
  cycles: AuditedCycle[];
  baseline: Baseline;
}

/**
 * Recomputes a vehicle's whole fuel history for one track. Deterministic and cheap
 * (a vehicle has a few hundred fills a year), so it's rerun whenever a fill is added,
 * voided, or arrives out of order from an offline phone.
 *
 * Only `ok` cycles train the baseline, so steady theft never becomes "normal". A
 * flagged cycle a reviewer dismissed as a false alarm (in `acceptedClosingFillIds`)
 * is treated as ok and does train it.
 */
export function auditVehicle(input: {
  fills: readonly Fill[];
  track: AuditTrack;
  seed: { mean: number; std: number };
  settings: AuditSettings;
  acceptedClosingFillIds?: ReadonlySet<string>;
}): VehicleAudit {
  let baseline = seedBaseline(input.seed.mean, input.seed.std);
  const cycles: AuditedCycle[] = [];
  for (const cycle of buildCycles(input.fills, input.track)) {
    const evaluation = evaluateCycle(cycle, baseline, input.settings);
    const reviewerAccepted = input.acceptedClosingFillIds?.has(cycle.closingFillId) ?? false;
    const include =
      cycle.value !== null &&
      (evaluation.verdict === 'ok' || (evaluation.verdict === 'flagged' && reviewerAccepted));
    if (include && cycle.value !== null)
      baseline = updateBaseline(baseline, cycle.value, input.settings.ewmaAlpha);
    cycles.push({ cycle, evaluation, includedInBaseline: include });
  }
  return { cycles, baseline };
}
