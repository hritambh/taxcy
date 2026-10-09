/** How a driver is paid, configured per org with optional per-driver overrides (decision D3). */
export type PayRule = (
  | { kind: 'none' }
  | { kind: 'percent_of_fare'; percent: number; base: 'quoted' | 'expected' }
  | { kind: 'per_trip'; amountPaise: number }
  | { kind: 'per_km'; paisePerKm: number }
  | { kind: 'fixed_daily'; amountPaise: number }
) & {
  /** Driver-allowance (bata) charges go to the driver. Default true. */
  allowanceToDriver: boolean;
};

export const DEFAULT_PAY_RULE: PayRule = { kind: 'none', allowanceToDriver: true };
