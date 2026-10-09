import { z } from 'zod';
import { DateTime, Id, Paise } from '../common.js';
import { access, defineRoute } from '../http.js';
import { OdometerInput, OdometerReading } from './trips.js';

export const FuelKind = z.enum(['petrol', 'diesel', 'cng']);
export const AuditTrack = z.enum(['petrol', 'diesel', 'cng', 'bifuel_cost']);
export const PaidBy = z.enum(['driver_cash', 'owner', 'fuel_card']);

export const FuelFill = z.object({
  id: Id,
  vehicleId: Id,
  driverId: Id.nullable(),
  driverName: z.string().nullable(),
  tripId: Id.nullable(),
  fuel: FuelKind,
  /** Millilitres (petrol, diesel) or grams (CNG). */
  quantityMilli: z.number().int(),
  unit: z.enum(['L', 'kg']),
  costPaise: Paise,
  odometer: OdometerReading,
  isFullTank: z.boolean(),
  receiptMediaId: Id.nullable(),
  ocrCostPaise: Paise.nullable(),
  paidBy: PaidBy,
  filledAt: DateTime,
  voidedAt: DateTime.nullable(),
  createdAt: DateTime,
});
export type FuelFill = z.infer<typeof FuelFill>;

export const FuelCycle = z.object({
  id: Id,
  openingFillId: Id,
  closingFillId: Id,
  startedAt: DateTime,
  endedAt: DateTime,
  distanceKm: z.number().int(),
  fuelMilli: z.number().int().nullable(),
  costPaise: Paise,
  metric: z.enum(['km_per_unit', 'paise_per_km']),
  /** km/L, km/kg, or paise/km. */
  metricValue: z.number().nullable(),
  baselineMean: z.number().nullable(),
  baselineStd: z.number().nullable(),
  priorCycles: z.number().int(),
  method: z.enum(['sigma', 'percent']),
  deviation: z.number().nullable(),
  verdict: z.enum(['ok', 'flagged', 'invalid']),
  includedInBaseline: z.boolean(),
});
export type FuelCycle = z.infer<typeof FuelCycle>;

export const VehicleFuelAudit = z.object({
  vehicleId: Id,
  track: AuditTrack,
  metric: z.enum(['km_per_unit', 'paise_per_km']),
  /** Unit label for charts: "km/L", "km/kg" or "₹/km". */
  unitLabel: z.string(),
  baseline: z.object({ mean: z.number(), std: z.number(), cycles: z.number().int() }).nullable(),
  cycles: z.array(FuelCycle),
});

export const fuelRoutes = {
  record: defineRoute({
    method: 'POST',
    path: '/fuel-fills',
    summary: 'Record a fuel fill (idempotent on id; fills may arrive late from offline phones)',
    tag: 'fuel',
    access: access.anyMember,
    status: 201,
    body: z.object({
      id: Id,
      vehicleId: Id,
      tripId: Id.optional(),
      /** Staff recording on a driver's behalf; drivers are always recorded as themselves. */
      driverId: Id.optional(),
      fuel: FuelKind,
      quantityMilli: z.number().int().positive().max(200_000),
      costPaise: Paise,
      odometer: OdometerInput,
      isFullTank: z.boolean(),
      receiptMediaId: Id.optional(),
      paidBy: PaidBy,
      filledAt: DateTime,
    }),
    response: FuelFill,
  }),
  list: defineRoute({
    method: 'GET',
    path: '/fuel-fills',
    summary: 'Fuel fills, newest first',
    tag: 'fuel',
    access: access.staff,
    query: z.object({
      vehicleId: Id.optional(),
      driverId: Id.optional(),
      from: DateTime.optional(),
      to: DateTime.optional(),
      includeVoided: z.stringbool().optional(),
      limit: z.coerce.number().int().min(1).max(500).default(100),
    }),
    response: z.array(FuelFill),
  }),
  void: defineRoute({
    method: 'POST',
    path: '/fuel-fills/{id}/void',
    summary: 'Void a wrong fill; the vehicle audit is recomputed',
    tag: 'fuel',
    access: access.staff,
    params: z.object({ id: Id }),
    body: z.object({ reason: z.string().trim().min(1).max(200) }),
    response: FuelFill,
  }),
  vehicleAudit: defineRoute({
    method: 'GET',
    path: '/vehicles/{id}/fuel-cycles',
    summary: "A vehicle's fuel cycles, baseline and verdicts",
    tag: 'fuel',
    access: access.staff,
    params: z.object({ id: Id }),
    response: VehicleFuelAudit,
  }),
};
