import { describe, expect, it } from 'vitest';
import { istBusinessDate } from './time.js';

describe('istBusinessDate', () => {
  it.each([
    ['2026-10-09T18:29:59.999Z', '2026-10-09'],
    ['2026-10-09T18:30:00.000Z', '2026-10-10'],
    ['2026-10-09T00:00:00.000Z', '2026-10-09'],
    ['2026-12-31T18:30:00.000Z', '2027-01-01'],
    ['2028-02-28T19:00:00.000Z', '2028-02-29'],
  ])('maps %s to IST date %s', (utc, expected) => {
    expect(istBusinessDate(new Date(utc))).toBe(expected);
  });

  it('rejects an invalid date', () => {
    expect(() => istBusinessDate(new Date('nope'))).toThrow(RangeError);
  });
});
