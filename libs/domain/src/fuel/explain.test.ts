import { describe, expect, it } from 'vitest';
import type { Cycle } from './cycles.js';
import { evaluateCycle } from './evaluate.js';
import { explainFuelCycle, explainInvalidCycle } from './explain.js';
import { DEFAULT_AUDIT_SETTINGS } from './types.js';

const period = {
  startedAt: new Date('2026-10-03T04:30:00Z'),
  endedAt: new Date('2026-10-08T04:30:00Z'),
};

describe('explainFuelCycle', () => {
  it('worked example: Dzire CNG using more fuel than usual', () => {
    const cycle: Cycle = {
      track: 'cng',
      openingFillId: 'a',
      closingFillId: 'b',
      fillIds: ['b'],
      ...period,
      distanceKm: 520,
      fuelMilli: 28_600,
      costPaise: 257_400, // ₹90/kg
      metric: 'km_per_unit',
      value: 520 / 28.6,
    };
    const evaluation = evaluateCycle(
      cycle,
      { mean: 24, variance: 2.25, n: 6 },
      DEFAULT_AUDIT_SETTINGS,
    );
    const text = explainFuelCycle({
      cycle,
      evaluation,
      vehicle: { registrationNo: 'MH12 AB 1234', model: 'Dzire', fuelType: 'cng' },
      driverNames: ['Ramesh K.'],
    });
    expect(text.title).toBe('MH12 AB 1234 (Dzire, CNG) used more fuel than usual');
    expect(text.explanation).toBe(
      'Between 3 Oct and 8 Oct it ran 520 km on 28.6 kg of CNG, which is 18.2 km/kg. ' +
        'This car usually does about 24.0 km/kg, so this is 24% worse than normal. ' +
        "That's roughly 6.9 kg (about ₹620) more CNG than expected. " +
        'Fills in this period were logged by Ramesh K. Check the receipts and odometer photos.',
    );
    expect(text.message).toEqual({
      key: 'fuel_efficiency_low',
      params: {
        vehicle: { registrationNo: 'MH12 AB 1234', model: 'Dzire', fuelType: 'cng' },
        from: '2026-10-03',
        to: '2026-10-08',
        distanceKm: 520,
        percentWorse: 24,
        drivers: ['Ramesh K.'],
        fuel: 'cng',
        used: 28.6,
        value: 18.2,
        baseline: 24,
        extraUnits: 6.9,
        extraCostPaise: 62_000,
      },
    });
  });

  it('worked example: bi-fuel Ertiga costing more to run', () => {
    const cycle: Cycle = {
      track: 'bifuel_cost',
      openingFillId: 'c1',
      closingFillId: 'c2',
      fillIds: ['p1', 'c2'],
      ...period,
      distanceKm: 400,
      fuelMilli: null,
      costPaise: 285_000,
      metric: 'paise_per_km',
      value: 712.5,
    };
    const evaluation = evaluateCycle(
      cycle,
      { mean: 420, variance: 900, n: 5 },
      DEFAULT_AUDIT_SETTINGS,
    );
    const text = explainFuelCycle({
      cycle,
      evaluation,
      vehicle: { registrationNo: 'MH12 CD 5678', model: 'Ertiga', fuelType: 'petrol_cng' },
      driverNames: [],
      petrolCostPaise: 200_000,
    });
    expect(text.title).toBe('MH12 CD 5678 (Ertiga, petrol + CNG) cost more to run than usual');
    expect(text.explanation).toBe(
      'Between 3 Oct and 8 Oct it ran 400 km for ₹2,850 of fuel, which is ₹7.13/km. ' +
        'This car usually costs about ₹4.20/km, so this is 70% more than normal. ₹2,000 of that was petrol. ' +
        'Check whether the car was run on petrol unnecessarily, and check the receipts.',
    );
    expect(text.message).toMatchObject({
      key: 'fuel_cost_high',
      params: {
        costPaise: 285_000,
        paisePerKm: 713,
        baselinePaisePerKm: 420,
        percentWorse: 70,
        petrolCostPaise: 200_000,
        drivers: [],
      },
    });
  });

  it('lists several drivers naturally', () => {
    const cycle: Cycle = {
      track: 'diesel',
      openingFillId: 'a',
      closingFillId: 'b',
      fillIds: ['b'],
      ...period,
      distanceKm: 400,
      fuelMilli: 50_000,
      costPaise: 450_000,
      metric: 'km_per_unit',
      value: 8,
    };
    const evaluation = evaluateCycle(
      cycle,
      { mean: 12, variance: 1, n: 5 },
      DEFAULT_AUDIT_SETTINGS,
    );
    const text = explainFuelCycle({
      cycle,
      evaluation,
      vehicle: { registrationNo: 'MH12 EF 9012', model: 'Innova Crysta', fuelType: 'diesel' },
      driverNames: ['Ramesh', 'Suresh', 'Imran'],
    });
    expect(text.explanation).toContain('logged by Ramesh, Suresh and Imran.');
    expect(text.explanation).toContain('of diesel, which is 8.0 km/L');
  });
});

describe('explainInvalidCycle', () => {
  it('explains a probable missed fill', () => {
    expect(explainInvalidCycle('implausibly_good')).toMatch(/fill was not logged/);
  });
});
