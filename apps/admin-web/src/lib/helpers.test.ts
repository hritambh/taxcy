import { describe, expect, it } from 'vitest';
import type { FuelCycle } from './api-types.js';
import {
  fmtDate,
  fmtInr,
  fmtKm,
  fmtPhone,
  fmtRegistration,
  istDayRange,
  istLocalToIso,
  isoToIstLocal,
  istToday,
  paiseToRupeesInput,
  rupeesToPaise,
} from './format.js';
import { chartPoints } from './fuel-chart.js';
import { normalizeIndianMobile } from './labels.js';
import { describePayRule, netPayableText } from './money.js';

describe('money formatting', () => {
  it.each([
    [129_000, '₹1,290'],
    [12_345_678, '₹1,23,456.78'],
    [71_250, '₹712.50'],
    [0, '₹0'],
  ])('fmtInr(%i) → %s', (paise, text) => {
    expect(fmtInr(paise)).toBe(text);
  });

  it.each([
    ['3500', 350_000],
    ['3,500', 350_000],
    ['₹ 2,850.5', 285_050],
    ['0.05', 5],
    ['12.345', null],
    ['abc', null],
    ['', null],
    ['-5', null],
  ])('rupeesToPaise(%j) → %j', (input, paise) => {
    expect(rupeesToPaise(input)).toBe(paise);
  });

  it('round-trips paise through the rupee input format', () => {
    expect(paiseToRupeesInput(350_000)).toBe('3500');
    expect(paiseToRupeesInput(71_250)).toBe('712.50');
    expect(rupeesToPaise(paiseToRupeesInput(71_250))).toBe(71_250);
  });
});

describe('IST dates and times', () => {
  it('reads datetime-local input as IST', () => {
    expect(istLocalToIso('2026-10-09T08:30')).toBe('2026-10-09T03:00:00.000Z');
    expect(isoToIstLocal('2026-10-09T03:00:00.000Z')).toBe('2026-10-09T08:30');
  });

  it('IST day boundaries', () => {
    expect(istDayRange('2026-10-09')).toEqual({
      from: '2026-10-08T18:30:00.000Z',
      to: '2026-10-09T18:30:00.000Z',
    });
  });

  it('today in IST rolls over at 18:30 UTC', () => {
    expect(istToday(new Date('2026-10-09T18:29:00Z'))).toBe('2026-10-09');
    expect(istToday(new Date('2026-10-09T18:31:00Z'))).toBe('2026-10-10');
  });

  it('shows calendar dates as written', () => {
    expect(fmtDate('2026-10-14')).toBe('14 Oct 2026');
  });
});

describe('display helpers', () => {
  it('spaces registration numbers', () => {
    expect(fmtRegistration('MH12AB1234')).toBe('MH 12 AB 1234');
    expect(fmtRegistration('22BH1234AA')).toBe('22BH1234AA');
  });

  it('formats Indian numbers', () => {
    expect(fmtPhone('+919812345678')).toBe('+91 98123 45678');
    expect(normalizeIndianMobile('098123 45678')).toBe('+919812345678');
    expect(normalizeIndianMobile('+91 98123-45678')).toBe('+919812345678');
    expect(fmtKm(48210)).toBe('48,210 km');
  });
});

describe('settlement wording', () => {
  it('says who hands money to whom', () => {
    expect(netPayableText(129_000)).toEqual({ text: 'Driver pays you ₹1,290', tone: 'owes' });
    expect(netPayableText(-200_000)).toEqual({ text: 'You pay the driver ₹2,000', tone: 'owed' });
    expect(netPayableText(0).tone).toBe('even');
  });

  it('describes pay rules', () => {
    expect(
      describePayRule({
        kind: 'percent_of_fare',
        percent: 20,
        base: 'quoted',
        allowanceToDriver: true,
      }),
    ).toBe('20% of quoted fare + driver allowance');
    expect(
      describePayRule({ kind: 'per_trip', amountPaise: 30_000, allowanceToDriver: false }),
    ).toBe('₹300 per trip');
  });
});

describe('fuel chart points', () => {
  const cycle = (overrides: Partial<FuelCycle>): FuelCycle => ({
    id: 'c',
    openingFillId: 'a',
    closingFillId: 'b',
    startedAt: '2026-10-01T10:00:00.000Z',
    endedAt: '2026-10-05T10:00:00.000Z',
    distanceKm: 480,
    fuelMilli: 40_000,
    costPaise: 360_000,
    metric: 'km_per_unit',
    metricValue: 12,
    baselineMean: 12,
    baselineStd: 0.5,
    priorCycles: 5,
    method: 'sigma',
    deviation: 0,
    verdict: 'ok',
    includedInBaseline: true,
    ...overrides,
  });

  it('uses mean ± kσ for established vehicles and mean ± p% for new ones', () => {
    const settings = { fuelKSigma: 2, fuelPctThreshold: 20 };
    const [sigma, percent] = chartPoints(
      {
        metric: 'km_per_unit',
        cycles: [cycle({}), cycle({ method: 'percent', baselineMean: 10 })],
      },
      settings,
    );
    expect(sigma?.band).toEqual([11, 13]);
    expect(percent?.band).toEqual([8, 12]);
  });

  it('shows cost tracking in ₹/km and skips cycles without a value', () => {
    const points = chartPoints(
      {
        metric: 'paise_per_km',
        cycles: [
          cycle({ metric: 'paise_per_km', metricValue: 462.5, baselineMean: 420, baselineStd: 30 }),
          cycle({ metricValue: null }),
        ],
      },
      { fuelKSigma: 2, fuelPctThreshold: 20 },
    );
    expect(points).toHaveLength(1);
    expect(points[0]?.value).toBeCloseTo(4.625);
    expect(points[0]?.band?.[0]).toBeCloseTo(3.6);
  });
});
