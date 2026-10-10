import type { DocType } from './documents/expiry.js';
import type { FuelKind, VehicleFuelType } from './fuel/types.js';

/**
 * What an alert says, as a key plus the values to fill in, so each app can show it
 * in the user's language. The alert's English title and explanation stay as the
 * fallback for clients that don't know a key. Numbers are already rounded the way
 * they should be shown; dates are IST calendar dates (YYYY-MM-DD).
 */
export type AlertMessage =
  | { key: 'fuel_efficiency_low'; params: FuelEfficiencyParams }
  | { key: 'fuel_cost_high'; params: FuelCostParams }
  | { key: 'odo_gps_mismatch'; params: OdoGpsParams }
  | { key: 'document_expiring'; params: DocumentExpiryParams }
  | { key: 'document_expired'; params: DocumentExpiryParams }
  | { key: 'cancellation_requested'; params: CancellationRequestedParams };

export interface VehicleRef {
  registrationNo: string;
  model: string;
  fuelType: VehicleFuelType;
}

interface FuelCycleParams {
  vehicle: VehicleRef;
  from: string;
  to: string;
  distanceKm: number;
  /** Whole percent worse than the baseline. */
  percentWorse: number;
  /** Drivers who logged fills in the cycle. */
  drivers: string[];
}

export interface FuelEfficiencyParams extends FuelCycleParams {
  /** Litres for petrol and diesel, kg for CNG. */
  fuel: FuelKind;
  used: number;
  /** km per litre or kg, one decimal. */
  value: number;
  baseline: number;
  extraUnits: number;
  extraCostPaise: number;
}

export interface FuelCostParams extends FuelCycleParams {
  costPaise: number;
  paisePerKm: number;
  baselinePaisePerKm: number;
  /** How much of the cost was petrol; 0 when none. */
  petrolCostPaise: number;
}

export interface OdoGpsParams {
  /** When the trip started (ISO instant). */
  tripStartedAt: string;
  from: string;
  to: string | null;
  registrationNo: string | null;
  odometerKm: number;
  gpsKm: number;
  excessPct: number;
  tolerancePct: number;
}

export interface DocumentExpiryParams {
  docType: DocType;
  subjectKind: 'vehicle' | 'driver';
  /** Registration number or driver name. */
  subject: string;
  expiresOn: string;
  /** Days left when the alert was raised; negative once expired. */
  daysLeft: number;
}

export interface CancellationRequestedParams {
  from: string;
  driverName: string | null;
  reason: string;
  endKm: number;
}

/** Fallback text plus the translatable message. */
export interface AlertText {
  title: string;
  explanation: string;
  message: AlertMessage;
}
