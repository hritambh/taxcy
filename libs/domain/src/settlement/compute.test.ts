import { describe, expect, it } from 'vitest';
import { computeSettlement, type SettlementInput, type SettlementTrip } from './compute.js';
import type { PayRule } from './pay-rules.js';

const rupees = (r: number) => r * 100;

const tripA: SettlementTrip = {
  id: 'A',
  farePaise: rupees(3_500),
  odometerKm: 155,
  charges: [{ id: 'A-toll', kind: 'toll', amountPaise: rupees(250), paidByDriver: true }],
  collections: [
    { id: 'A-cash', method: 'cash', amountPaise: rupees(2_000) },
    { id: 'A-upi', method: 'upi', amountPaise: rupees(1_750) },
  ],
};
const tripB: SettlementTrip = {
  id: 'B',
  farePaise: rupees(1_800),
  odometerKm: 45,
  charges: [],
  collections: [{ id: 'B-cash', method: 'cash', amountPaise: rupees(1_800) }],
};
const dieselByDriver = { id: 'fill', costPaise: rupees(1_200), paidBy: 'driver_cash' as const };

function input(payRule: PayRule, extra: Partial<SettlementInput> = {}): SettlementInput {
  return { trips: [tripA, tripB], fuelFills: [dieselByDriver], payRule, adjustments: [], ...extra };
}

describe('computeSettlement', () => {
  it('worked example: 20% of quoted fare, Ramesh hands over ₹1,290', () => {
    const r = computeSettlement(
      input({ kind: 'percent_of_fare', percent: 20, base: 'quoted', allowanceToDriver: true }),
    );
    expect(r).toMatchObject({
      expectedFarePaise: rupees(5_550),
      cashPaise: rupees(3_800),
      onlinePaise: rupees(1_750),
      driverExpensesPaise: rupees(1_450),
      driverEarningsPaise: rupees(1_060),
      carriedAdjustmentPaise: 0,
      netPayablePaise: rupees(1_290),
      shortfallPaise: 0,
    });
  });

  it.each<[string, PayRule, number]>([
    ['none (salaried)', { kind: 'none', allowanceToDriver: true }, 0],
    [
      '20% of expected fare',
      { kind: 'percent_of_fare', percent: 20, base: 'expected', allowanceToDriver: true },
      rupees(1_110),
    ],
    [
      '₹300 per trip',
      { kind: 'per_trip', amountPaise: rupees(300), allowanceToDriver: true },
      rupees(600),
    ],
    ['₹2 per km', { kind: 'per_km', paisePerKm: 200, allowanceToDriver: true }, rupees(400)],
    [
      '₹800 fixed daily',
      { kind: 'fixed_daily', amountPaise: rupees(800), allowanceToDriver: true },
      rupees(800),
    ],
  ])('pay rule: %s', (_name, payRule, earnings) => {
    const r = computeSettlement(input(payRule));
    expect(r.driverEarningsPaise).toBe(earnings);
    expect(r.netPayablePaise).toBe(rupees(3_800) - rupees(1_450) - earnings);
  });

  it('fixed daily pay is zero on a day with no trips', () => {
    const r = computeSettlement(
      input(
        { kind: 'fixed_daily', amountPaise: rupees(800), allowanceToDriver: true },
        { trips: [] },
      ),
    );
    expect(r.driverEarningsPaise).toBe(0);
  });

  it('driver allowance goes to the driver only when configured', () => {
    const withBata: SettlementTrip = {
      ...tripB,
      charges: [
        { id: 'bata', kind: 'driver_allowance', amountPaise: rupees(300), paidByDriver: false },
      ],
      collections: [{ id: 'B-cash', method: 'cash', amountPaise: rupees(2_100) }],
    };
    const toDriver = computeSettlement(
      input({ kind: 'none', allowanceToDriver: true }, { trips: [withBata], fuelFills: [] }),
    );
    const toOwner = computeSettlement(
      input({ kind: 'none', allowanceToDriver: false }, { trips: [withBata], fuelFills: [] }),
    );
    expect(toDriver.driverEarningsPaise).toBe(rupees(300));
    expect(toOwner.driverEarningsPaise).toBe(0);
    expect(toDriver.netPayablePaise).toBe(rupees(1_800));
  });

  it('fuel paid by the owner or a fuel card is not a driver expense', () => {
    const r = computeSettlement(
      input(
        { kind: 'none', allowanceToDriver: true },
        { fuelFills: [{ id: 'f', costPaise: rupees(1_200), paidBy: 'fuel_card' }] },
      ),
    );
    expect(r.driverExpensesPaise).toBe(rupees(250));
  });

  it('shows a shortfall when collections do not cover the expected fare', () => {
    const short: SettlementTrip = {
      ...tripB,
      collections: [{ id: 'B-cash', method: 'cash', amountPaise: rupees(1_500) }],
    };
    expect(
      computeSettlement(input({ kind: 'none', allowanceToDriver: true }, { trips: [short] }))
        .shortfallPaise,
    ).toBe(rupees(300));
  });

  it('net payable is negative when the owner owes the driver', () => {
    const r = computeSettlement(
      input(
        { kind: 'none', allowanceToDriver: true },
        { trips: [], fuelFills: [{ id: 'f', costPaise: rupees(2_000), paidBy: 'driver_cash' }] },
      ),
    );
    expect(r.netPayablePaise).toBe(-rupees(2_000));
  });

  it('carries adjustments from already-settled days', () => {
    const r = computeSettlement(
      input(
        { kind: 'none', allowanceToDriver: true },
        { adjustments: [{ id: 'late-cash', amountPaise: rupees(500) }] },
      ),
    );
    expect(r.carriedAdjustmentPaise).toBe(rupees(500));
    expect(r.netPayablePaise).toBe(rupees(3_800) - rupees(1_450) + rupees(500));
  });

  it('lists every covered item exactly once', () => {
    const r = computeSettlement(input({ kind: 'none', allowanceToDriver: true }));
    const keys = r.lines.map((l) => `${l.refType}:${l.refId}`);
    expect(keys).toEqual([
      'trip:A',
      'trip_charge:A-toll',
      'collection:A-cash',
      'collection:A-upi',
      'trip:B',
      'collection:B-cash',
      'fuel_fill:fill',
    ]);
    expect(new Set(keys).size).toBe(keys.length);
  });
});
