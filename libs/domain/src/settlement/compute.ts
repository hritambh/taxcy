import type { PayRule } from './pay-rules.js';

export type CollectionMethod = 'cash' | 'upi' | 'card';
export type PaidBy = 'driver_cash' | 'owner' | 'fuel_card';

export interface SettlementTrip {
  id: string;
  /** Quoted fare, or the cancellation fare for an approved cancellation of a started trip. */
  farePaise: number;
  /** Odometer distance, for per-km pay. Null when unknown. */
  odometerKm: number | null;
  charges: readonly { id: string; kind: string; amountPaise: number; paidByDriver: boolean }[];
  collections: readonly { id: string; method: CollectionMethod; amountPaise: number }[];
}

export interface SettlementInput {
  trips: readonly SettlementTrip[];
  fuelFills: readonly { id: string; costPaise: number; paidBy: PaidBy }[];
  payRule: PayRule;
  /** Late items from already-settled days, carried into this one (positive = driver owes more). */
  adjustments: readonly { id: string; amountPaise: number }[];
}

export type SettlementLineType = 'trip' | 'trip_charge' | 'collection' | 'fuel_fill' | 'adjustment';

export interface SettlementResult {
  expectedFarePaise: number;
  cashPaise: number;
  onlinePaise: number;
  driverExpensesPaise: number;
  driverEarningsPaise: number;
  carriedAdjustmentPaise: number;
  /** cash − driver expenses − driver earnings + adjustments. Positive: the driver hands this to the owner. */
  netPayablePaise: number;
  /** expected fare − everything collected. Shown to the owner; should be zero. */
  shortfallPaise: number;
  /** Every item the settlement covers, so each is settled exactly once. */
  lines: { refType: SettlementLineType; refId: string; amountPaise: number }[];
}

const sum = (values: readonly number[]) => values.reduce((a, b) => a + b, 0);

export function driverEarnings(input: Pick<SettlementInput, 'trips' | 'payRule'>): number {
  const { trips, payRule } = input;
  const quoted = sum(trips.map((t) => t.farePaise));
  const expected = sum(trips.map((t) => t.farePaise + sum(t.charges.map((c) => c.amountPaise))));
  let base: number;
  switch (payRule.kind) {
    case 'none':
      base = 0;
      break;
    case 'percent_of_fare':
      base = Math.round(((payRule.base === 'quoted' ? quoted : expected) * payRule.percent) / 100);
      break;
    case 'per_trip':
      base = payRule.amountPaise * trips.length;
      break;
    case 'per_km':
      base = Math.round(payRule.paisePerKm * sum(trips.map((t) => t.odometerKm ?? 0)));
      break;
    case 'fixed_daily':
      base = trips.length > 0 ? payRule.amountPaise : 0;
      break;
  }
  const allowance = payRule.allowanceToDriver
    ? sum(
        trips.flatMap((t) =>
          t.charges.filter((c) => c.kind === 'driver_allowance').map((c) => c.amountPaise),
        ),
      )
    : 0;
  return base + allowance;
}

/** A driver's daily settlement. Pure: the API snapshots the result and its lines when marked settled. */
export function computeSettlement(input: SettlementInput): SettlementResult {
  const lines: SettlementResult['lines'] = [];
  let expectedFarePaise = 0;
  let cashPaise = 0;
  let onlinePaise = 0;
  let driverExpensesPaise = 0;

  for (const trip of input.trips) {
    expectedFarePaise += trip.farePaise;
    lines.push({ refType: 'trip', refId: trip.id, amountPaise: trip.farePaise });
    for (const charge of trip.charges) {
      expectedFarePaise += charge.amountPaise;
      if (charge.paidByDriver) driverExpensesPaise += charge.amountPaise;
      lines.push({ refType: 'trip_charge', refId: charge.id, amountPaise: charge.amountPaise });
    }
    for (const collection of trip.collections) {
      if (collection.method === 'cash') cashPaise += collection.amountPaise;
      else onlinePaise += collection.amountPaise;
      lines.push({
        refType: 'collection',
        refId: collection.id,
        amountPaise: collection.amountPaise,
      });
    }
  }
  for (const fill of input.fuelFills) {
    if (fill.paidBy === 'driver_cash') driverExpensesPaise += fill.costPaise;
    lines.push({ refType: 'fuel_fill', refId: fill.id, amountPaise: fill.costPaise });
  }
  const carriedAdjustmentPaise = sum(input.adjustments.map((a) => a.amountPaise));
  for (const adjustment of input.adjustments) {
    lines.push({
      refType: 'adjustment',
      refId: adjustment.id,
      amountPaise: adjustment.amountPaise,
    });
  }

  const driverEarningsPaise = driverEarnings(input);
  return {
    expectedFarePaise,
    cashPaise,
    onlinePaise,
    driverExpensesPaise,
    driverEarningsPaise,
    carriedAdjustmentPaise,
    netPayablePaise: cashPaise - driverExpensesPaise - driverEarningsPaise + carriedAdjustmentPaise,
    shortfallPaise: expectedFarePaise - (cashPaise + onlinePaise),
    lines,
  };
}
