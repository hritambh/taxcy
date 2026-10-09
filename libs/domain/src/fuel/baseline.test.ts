import { describe, expect, it } from 'vitest';
import { effectiveStd, seedBaseline, updateBaseline } from './baseline.js';

describe('EWMA baseline', () => {
  it('starts from the seed with no accepted cycles', () => {
    expect(seedBaseline(24, 2.5)).toEqual({ mean: 24, variance: 6.25, n: 0 });
  });

  it('applies the incremental update: mean += αδ, var = (1−α)(var + αδ²)', () => {
    const next = updateBaseline({ mean: 10, variance: 1, n: 4 }, 12, 0.3);
    expect(next.mean).toBeCloseTo(10.6, 10);
    expect(next.variance).toBeCloseTo(1.54, 10);
    expect(next.n).toBe(5);
  });

  it('converges to a steady value', () => {
    let b = seedBaseline(20, 3);
    for (let i = 0; i < 40; i++) b = updateBaseline(b, 14, 0.3);
    expect(b.mean).toBeCloseTo(14, 3);
  });

  it('floors σ at 3% of the mean so identical cycles cannot make it vanish', () => {
    let b = seedBaseline(14, 0.01);
    for (let i = 0; i < 20; i++) b = updateBaseline(b, 14, 0.3);
    expect(effectiveStd(b)).toBeCloseTo(0.42, 2);
  });
});
