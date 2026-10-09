import { describe, expect, it } from 'vitest';
import { explainOdoGps, odoGpsVerdict } from './odo-gps.js';

const good = { coverageRatio: 0.95, pointsUsed: 400, tolerancePct: 10 };

describe('odoGpsVerdict', () => {
  it.each([
    [151, 151, 'ok', null],
    [160, 151, 'ok', null], // 6%
    [166, 151, 'ok', null], // 9.9%
    [170, 151, 'flagged', 'warning'], // 12.6%
    [182, 151, 'flagged', 'critical'], // 20.5%, worked example
  ])('odometer %i km vs GPS %i km → %s', (odometerKm, gpsKm, result, severity) => {
    const v = odoGpsVerdict({ ...good, odometerKm, gpsKm });
    expect([v.result, v.severity]).toEqual([result, severity]);
  });

  it('odometer below GPS is never flagged', () => {
    expect(odoGpsVerdict({ ...good, odometerKm: 140, gpsKm: 151 }).result).toBe('ok');
  });

  it.each([
    ['low coverage', { coverageRatio: 0.5 }],
    ['too few points', { pointsUsed: 8 }],
    ['no GPS distance', { gpsKm: 0 }],
  ])('is inconclusive with %s rather than accusing the driver', (_name, override) => {
    expect(odoGpsVerdict({ ...good, odometerKm: 300, gpsKm: 151, ...override })).toMatchObject({
      result: 'inconclusive',
      severity: null,
    });
  });
});

describe('explainOdoGps', () => {
  it('worked example', () => {
    const v = odoGpsVerdict({ ...good, odometerKm: 182, gpsKm: 151 });
    const text = explainOdoGps({
      tripLabel: 'Trip on 9 Oct (Pune → Mumbai, MH12 AB 1234)',
      odometerKm: 182,
      gpsKm: 151,
      excessPct: v.excessPct ?? 0,
      tolerancePct: 10,
    });
    expect(text.title).toBe(
      'Trip on 9 Oct (Pune → Mumbai, MH12 AB 1234) shows more km on the odometer than the GPS route',
    );
    expect(text.explanation).toBe(
      "The odometer readings say 182 km, but the phone's GPS recorded 151 km. " +
        'The odometer distance is 21% higher; the allowed difference is 10%. Check the start and end odometer photos.',
    );
  });
});
