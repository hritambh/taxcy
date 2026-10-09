import type { Fill, FuelKind } from './types.js';

let seq = 0;

/** Builds a fill; quantities in litres/kg and rupees for readability. */
export function fill(
  odometerKm: number,
  quantity: number,
  isFullTank: boolean,
  options: { fuel?: FuelKind; rupees?: number; at?: string; id?: string } = {},
): Fill {
  seq += 1;
  return {
    id: options.id ?? `f${seq}`,
    fuel: options.fuel ?? 'diesel',
    odometerKm,
    quantityMilli: Math.round(quantity * 1000),
    costPaise: Math.round((options.rupees ?? quantity * 90) * 100),
    isFullTank,
    filledAt: new Date(
      options.at ?? new Date(Date.UTC(2026, 0, 1) + seq * 86_400_000).toISOString(),
    ),
  };
}
