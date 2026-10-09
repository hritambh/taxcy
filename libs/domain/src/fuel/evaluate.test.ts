import { describe, expect, it } from 'vitest';
import type { Cycle } from './cycles.js';
import { evaluateCycle } from './evaluate.js';
import { DEFAULT_AUDIT_SETTINGS } from './types.js';

function kmCycle(distanceKm: number, units: number): Cycle {
  return {
    track: 'cng',
    openingFillId: 'a',
    closingFillId: 'b',
    fillIds: ['b'],
    startedAt: new Date('2026-10-03T04:00:00Z'),
    endedAt: new Date('2026-10-08T04:00:00Z'),
    distanceKm,
    fuelMilli: Math.round(units * 1000),
    costPaise: Math.round(units * 9000),
    metric: 'km_per_unit',
    value: distanceKm > 0 && units > 0 ? distanceKm / units : null,
  };
}

function costCycle(distanceKm: number, rupees: number): Cycle {
  return {
    ...kmCycle(distanceKm, 0),
    track: 'bifuel_cost',
    fuelMilli: null,
    costPaise: rupees * 100,
    metric: 'paise_per_km',
    value: distanceKm > 0 ? (rupees * 100) / distanceKm : null,
  };
}

const established = { mean: 24, variance: 1.5 ** 2, n: 6 };

describe('evaluateCycle: sigma rule (enough history)', () => {
  it('worked example: 18.2 km/kg against 24 ± 1.5 is 3.9σ worse, which is critical', () => {
    const e = evaluateCycle(kmCycle(520, 28.6), established, DEFAULT_AUDIT_SETTINGS);
    expect(e).toMatchObject({
      verdict: 'flagged',
      method: 'sigma',
      severity: 'critical',
      priorCycles: 6,
    });
    expect(e.deviation).toBeCloseTo(3.88, 2);
    expect(e.percentWorse).toBeCloseTo(24.2, 1);
  });

  it.each([
    [23.0, 'ok', null],
    [21.1, 'ok', null], // 1.93σ
    [20.5, 'flagged', 'warning'], // 2.33σ
    [19.6, 'flagged', 'warning'], // 2.93σ
    [19.4, 'flagged', 'critical'], // 3.07σ
  ])('%s km/kg → %s %s', (value, verdict, severity) => {
    const e = evaluateCycle(kmCycle(value * 10, 10), established, DEFAULT_AUDIT_SETTINGS);
    expect([e.verdict, e.severity]).toEqual([verdict, severity]);
  });

  it('never flags a better-than-usual cycle (unless implausibly good)', () => {
    expect(evaluateCycle(kmCycle(300, 10), established, DEFAULT_AUDIT_SETTINGS).verdict).toBe('ok');
  });

  it('respects a custom k', () => {
    const strict = { ...DEFAULT_AUDIT_SETTINGS, kSigma: 1 };
    expect(evaluateCycle(kmCycle(220, 10), established, strict).verdict).toBe('flagged');
  });
});

describe('evaluateCycle: percent rule (new vehicle)', () => {
  const young = { mean: 24, variance: 4, n: 2 };

  it('uses the percent rule until the vehicle has enough accepted cycles', () => {
    expect(evaluateCycle(kmCycle(200, 10), young, DEFAULT_AUDIT_SETTINGS).method).toBe('percent');
    expect(evaluateCycle(kmCycle(200, 10), { ...young, n: 3 }, DEFAULT_AUDIT_SETTINGS).method).toBe(
      'sigma',
    );
  });

  it('flags only beyond 20% worse than the baseline mean', () => {
    expect(evaluateCycle(kmCycle(192, 10), young, DEFAULT_AUDIT_SETTINGS).verdict).toBe('ok'); // exactly 20%
    const flagged = evaluateCycle(kmCycle(190, 10), young, DEFAULT_AUDIT_SETTINGS); // 20.8%
    expect(flagged).toMatchObject({ verdict: 'flagged', method: 'percent', severity: 'warning' });
    const critical = evaluateCycle(kmCycle(160, 10), young, DEFAULT_AUDIT_SETTINGS); // 33%
    expect(critical.severity).toBe('critical');
  });
});

describe('evaluateCycle: invalid cycles go to review, not alerts', () => {
  it.each([
    ['odometer not increasing', kmCycle(0, 10), 'odometer_not_increasing'],
    ['more than 3,000 km', kmCycle(3_200, 150), 'distance_too_long'],
    ['implausibly good (missed fill)', kmCycle(400, 10), 'implausibly_good'],
    ['no fuel recorded', kmCycle(300, 0), 'no_fuel'],
  ])('%s', (_name, cycle, reason) => {
    expect(evaluateCycle(cycle, established, DEFAULT_AUDIT_SETTINGS)).toMatchObject({
      verdict: 'invalid',
      invalidReason: reason,
      severity: null,
    });
  });
});

describe('evaluateCycle: bi-fuel cost per km (higher is worse)', () => {
  const baseline = { mean: 420, variance: 30 ** 2, n: 5 };

  it('worked example: ₹1,850 over 400 km = 462.5 paise/km is within 2σ', () => {
    const e = evaluateCycle(costCycle(400, 1_850), baseline, DEFAULT_AUDIT_SETTINGS);
    expect(e.verdict).toBe('ok');
    expect(e.deviation).toBeCloseTo(1.42, 2);
  });

  it('worked example: ₹2,850 over 400 km = 712.5 paise/km is critical', () => {
    const e = evaluateCycle(costCycle(400, 2_850), baseline, DEFAULT_AUDIT_SETTINGS);
    expect(e).toMatchObject({ verdict: 'flagged', severity: 'critical' });
    expect(e.deviation).toBeCloseTo(9.75, 2);
    expect(e.percentWorse).toBeCloseTo(69.6, 1);
  });

  it('a suspiciously cheap cycle means a missed fill', () => {
    expect(evaluateCycle(costCycle(400, 1_000), baseline, DEFAULT_AUDIT_SETTINGS)).toMatchObject({
      verdict: 'invalid',
      invalidReason: 'implausibly_good',
    });
  });
});
