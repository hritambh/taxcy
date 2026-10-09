export type FuelKind = 'petrol' | 'diesel' | 'cng';
export type VehicleFuelType = FuelKind | 'petrol_cng';

/**
 * What a vehicle is audited on. Single-fuel vehicles track efficiency (km per litre
 * or kg, higher is better); bi-fuel vehicles track running cost (paise per km, lower
 * is better), because the km driven on each fuel can't be separated.
 */
export type AuditTrack = FuelKind | 'bifuel_cost';
export type Metric = 'km_per_unit' | 'paise_per_km';

export interface Fill {
  id: string;
  fuel: FuelKind;
  odometerKm: number;
  /** Millilitres (petrol, diesel) or grams (CNG). */
  quantityMilli: number;
  costPaise: number;
  isFullTank: boolean;
  filledAt: Date;
}

export interface AuditSettings {
  /** Standard deviations below (or above, for cost) baseline before flagging. Default 2. */
  kSigma: number;
  /** Accepted cycles needed before the sigma rule applies. Default 3. */
  minCycles: number;
  /** Percent threshold used before minCycles. Default 20. */
  pctThreshold: number;
  /** EWMA smoothing factor. Default 0.3. */
  ewmaAlpha: number;
}

export const DEFAULT_AUDIT_SETTINGS: AuditSettings = {
  kSigma: 2,
  minCycles: 3,
  pctThreshold: 20,
  ewmaAlpha: 0.3,
};

export function trackFor(fuelType: VehicleFuelType): AuditTrack {
  return fuelType === 'petrol_cng' ? 'bifuel_cost' : fuelType;
}

export function metricFor(track: AuditTrack): Metric {
  return track === 'bifuel_cost' ? 'paise_per_km' : 'km_per_unit';
}

/** Fuels a vehicle may be filled with. */
export function allowedFuels(fuelType: VehicleFuelType): readonly FuelKind[] {
  return fuelType === 'petrol_cng' ? ['petrol', 'cng'] : [fuelType];
}
