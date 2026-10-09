import { describe, expect, it } from 'vitest';
import { auditVehicle } from './audit.js';
import { fill } from './test-helpers.js';
import { DEFAULT_AUDIT_SETTINGS, type Fill } from './types.js';

/** Full-tank fills `distances` km apart, each burning `litres[i]`. */
function history(distances: number[], litres: number[]): Fill[] {
  const fills = [fill(10_000, 40, true, { id: 'open' })];
  let odo = 10_000;
  distances.forEach((d, i) => {
    odo += d;
    fills.push(fill(odo, litres[i] ?? 40, true, { id: `c${i}` }));
  });
  return fills;
}

const seed = { mean: 12, std: 1.2 };

describe('auditVehicle', () => {
  it('evaluates each cycle against the baseline as it stood before that cycle', () => {
    const { cycles, baseline } = auditVehicle({
      fills: history([480, 500, 470, 490], [40, 41, 40, 40]),
      track: 'diesel',
      seed,
      settings: DEFAULT_AUDIT_SETTINGS,
    });
    expect(cycles.map((c) => c.evaluation.verdict)).toEqual(['ok', 'ok', 'ok', 'ok']);
    expect(cycles.map((c) => c.evaluation.priorCycles)).toEqual([0, 1, 2, 3]);
    expect(cycles.map((c) => c.evaluation.method)).toEqual([
      'percent',
      'percent',
      'percent',
      'sigma',
    ]);
    expect(baseline.n).toBe(4);
    expect(baseline.mean).toBeGreaterThan(11.8);
  });

  it('does not let theft train the baseline: repeated bad cycles stay flagged', () => {
    const good = [480, 500, 470, 490, 485];
    const { cycles, baseline } = auditVehicle({
      fills: history([...good, 480, 480, 480], [40, 41, 40, 40, 40, 55, 55, 55]),
      track: 'diesel',
      seed,
      settings: DEFAULT_AUDIT_SETTINGS,
    });
    expect(cycles.slice(-3).map((c) => c.evaluation.verdict)).toEqual([
      'flagged',
      'flagged',
      'flagged',
    ]);
    expect(cycles.slice(-3).every((c) => !c.includedInBaseline)).toBe(true);
    expect(baseline.n).toBe(5);
  });

  it('includes a flagged cycle the reviewer accepted as a false alarm', () => {
    const fills = history([480, 500, 470, 490, 480], [40, 41, 40, 40, 55]);
    const flaggedOnly = auditVehicle({
      fills,
      track: 'diesel',
      seed,
      settings: DEFAULT_AUDIT_SETTINGS,
    });
    expect(flaggedOnly.cycles.at(-1)?.evaluation.verdict).toBe('flagged');
    const accepted = auditVehicle({
      fills,
      track: 'diesel',
      seed,
      settings: DEFAULT_AUDIT_SETTINGS,
      acceptedClosingFillIds: new Set(['c4']),
    });
    expect(accepted.cycles.at(-1)?.includedInBaseline).toBe(true);
    expect(accepted.baseline.n).toBe(flaggedOnly.baseline.n + 1);
  });

  it('never includes invalid cycles', () => {
    const { cycles, baseline } = auditVehicle({
      fills: history([480, -20, 500], [40, 40, 40]),
      track: 'diesel',
      seed,
      settings: DEFAULT_AUDIT_SETTINGS,
    });
    expect(cycles.map((c) => c.evaluation.verdict)).toEqual(['ok', 'invalid', 'ok']);
    expect(baseline.n).toBe(2);
  });
});
