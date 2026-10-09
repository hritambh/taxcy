import { z } from 'zod';
import { CalendarDate, DateTime, Id, Paise, PhoneE164 } from '../common.js';
import { access, defineRoute } from '../http.js';

export const FuelType = z.enum(['petrol', 'diesel', 'cng', 'petrol_cng']);
export type FuelType = z.infer<typeof FuelType>;

/** Indian registration numbers, stored without spaces or dashes: "MH 12 AB 1234" → "MH12AB1234". */
export const RegistrationNo = z
  .string()
  .transform((v) => v.toUpperCase().replace(/[\s-]/g, ''))
  .pipe(z.string().regex(/^[A-Z0-9]{6,11}$/, 'Expected a registration number like MH12AB1234'));

const ActiveStatus = z.enum(['active', 'inactive']);

export const Vehicle = z.object({
  id: Id,
  registrationNo: z.string(),
  make: z.string(),
  model: z.string(),
  year: z.number().int().nullable(),
  fuelType: FuelType,
  vehicleModelId: Id.nullable(),
  lastOdometerKm: z.number().int().nullable(),
  status: ActiveStatus,
  createdAt: DateTime,
});
export type Vehicle = z.infer<typeof Vehicle>;

export const VehicleModel = z.object({
  id: Id,
  make: z.string(),
  model: z.string(),
  fuelType: FuelType,
});

const VehicleInput = z.object({
  registrationNo: RegistrationNo,
  make: z.string().trim().min(1).max(50),
  model: z.string().trim().min(1).max(50),
  year: z.number().int().min(1990).max(2100).optional(),
  fuelType: FuelType,
  vehicleModelId: Id.optional(),
  lastOdometerKm: z.number().int().nonnegative().optional(),
});

export const PayRule = z.intersection(
  z.discriminatedUnion('kind', [
    z.object({ kind: z.literal('none') }),
    z.object({
      kind: z.literal('percent_of_fare'),
      percent: z.number().min(0).max(100),
      base: z.enum(['quoted', 'expected']),
    }),
    z.object({ kind: z.literal('per_trip'), amountPaise: Paise }),
    z.object({ kind: z.literal('per_km'), paisePerKm: z.number().int().nonnegative() }),
    z.object({ kind: z.literal('fixed_daily'), amountPaise: Paise }),
  ]),
  z.object({ allowanceToDriver: z.boolean() }),
);
export type PayRule = z.infer<typeof PayRule>;

export const Driver = z.object({
  id: Id,
  userId: Id,
  name: z.string(),
  phone: PhoneE164,
  status: ActiveStatus,
  /** 'invited' until the driver signs in for the first time. */
  membershipStatus: z.enum(['invited', 'active', 'suspended']),
  /** Overrides the org's default pay rule; null uses the default. */
  payRule: PayRule.nullable(),
  createdAt: DateTime,
});
export type Driver = z.infer<typeof Driver>;

export const DocType = z.enum(['rc', 'insurance', 'permit', 'puc', 'driving_licence']);
export type DocType = z.infer<typeof DocType>;

export const Document = z.object({
  id: Id,
  docType: DocType,
  vehicleId: Id.nullable(),
  driverId: Id.nullable(),
  number: z.string().nullable(),
  validFrom: CalendarDate.nullable(),
  expiresOn: CalendarDate,
  mediaId: Id.nullable(),
  supersededBy: Id.nullable(),
  /** Days until expiry in IST; negative once expired. */
  daysLeft: z.number().int(),
  status: z.enum(['valid', 'expiring', 'expired', 'superseded']),
  createdAt: DateTime,
});
export type Document = z.infer<typeof Document>;

const DocumentDetails = z.object({
  number: z.string().trim().max(50).optional(),
  validFrom: CalendarDate.optional(),
  expiresOn: CalendarDate,
  mediaId: Id.optional(),
});

export const AuditSettings = z.object({
  fuelKSigma: z.number().min(0.5).max(5),
  fuelMinCycles: z.number().int().min(1).max(20),
  fuelPctThreshold: z.number().min(1).max(80),
  fuelEwmaAlpha: z.number().min(0.05).max(0.9),
  odoGpsTolerancePct: z.number().min(1).max(50),
  docAlertDays: z.array(z.number().int().min(0).max(365)).min(1).max(5),
});
export type AuditSettings = z.infer<typeof AuditSettings>;

const IdParam = z.object({ id: Id });

export const fleetRoutes = {
  listVehicles: defineRoute({
    method: 'GET',
    path: '/vehicles',
    summary: 'Vehicles in the org',
    tag: 'fleet',
    access: access.anyMember,
    query: z.object({ status: ActiveStatus.optional() }),
    response: z.array(Vehicle),
  }),
  createVehicle: defineRoute({
    method: 'POST',
    path: '/vehicles',
    summary: 'Add a vehicle',
    tag: 'fleet',
    access: access.staff,
    status: 201,
    body: VehicleInput,
    response: Vehicle,
  }),
  getVehicle: defineRoute({
    method: 'GET',
    path: '/vehicles/{id}',
    summary: 'A vehicle',
    tag: 'fleet',
    access: access.anyMember,
    params: IdParam,
    response: Vehicle,
  }),
  updateVehicle: defineRoute({
    method: 'PATCH',
    path: '/vehicles/{id}',
    summary: 'Update a vehicle',
    tag: 'fleet',
    access: access.staff,
    params: IdParam,
    body: VehicleInput.partial().extend({ status: ActiveStatus.optional() }),
    response: Vehicle,
  }),
  listVehicleModels: defineRoute({
    method: 'GET',
    path: '/vehicle-models',
    summary: 'Known vehicle models (used to seed fuel baselines)',
    tag: 'fleet',
    access: access.anyMember,
    response: z.array(VehicleModel),
  }),
  listDrivers: defineRoute({
    method: 'GET',
    path: '/drivers',
    summary: 'Drivers in the org',
    tag: 'fleet',
    access: access.staff,
    query: z.object({ status: ActiveStatus.optional() }),
    response: z.array(Driver),
  }),
  inviteDriver: defineRoute({
    method: 'POST',
    path: '/drivers',
    summary: 'Invite a driver by phone; they sign in to the app with that number',
    tag: 'fleet',
    access: access.staff,
    status: 201,
    body: z.object({ name: z.string().trim().min(1).max(100), phone: PhoneE164 }),
    response: Driver,
  }),
  getDriver: defineRoute({
    method: 'GET',
    path: '/drivers/{id}',
    summary: 'A driver',
    tag: 'fleet',
    access: access.staff,
    params: IdParam,
    response: Driver,
  }),
  updateDriver: defineRoute({
    method: 'PATCH',
    path: '/drivers/{id}',
    summary: 'Update a driver',
    tag: 'fleet',
    access: access.staff,
    params: IdParam,
    body: z.object({
      name: z.string().trim().min(1).max(100).optional(),
      status: ActiveStatus.optional(),
    }),
    response: Driver,
  }),
  setDriverPayRule: defineRoute({
    method: 'PUT',
    path: '/drivers/{id}/pay-rule',
    summary: "Override a driver's pay rule (null = use the org default)",
    tag: 'fleet',
    access: access.roles('owner'),
    params: IdParam,
    body: z.object({ payRule: PayRule.nullable() }),
    response: Driver,
  }),
  listDocuments: defineRoute({
    method: 'GET',
    path: '/documents',
    summary: 'Current documents (renewed ones are hidden unless includeSuperseded)',
    tag: 'fleet',
    access: access.staff,
    query: z.object({
      vehicleId: Id.optional(),
      driverId: Id.optional(),
      expiringWithinDays: z.coerce.number().int().min(0).max(365).optional(),
      includeSuperseded: z.stringbool().optional(),
    }),
    response: z.array(Document),
  }),
  createDocument: defineRoute({
    method: 'POST',
    path: '/documents',
    summary: 'Add a document to a vehicle (RC, insurance, permit, PUC) or a driver (licence)',
    tag: 'fleet',
    access: access.staff,
    status: 201,
    body: DocumentDetails.extend({
      docType: DocType,
      vehicleId: Id.optional(),
      driverId: Id.optional(),
    }),
    response: Document,
  }),
  renewDocument: defineRoute({
    method: 'POST',
    path: '/documents/{id}/renew',
    summary: 'Replace a document with its renewed copy (keeps history, clears its alerts)',
    tag: 'fleet',
    access: access.staff,
    status: 201,
    params: IdParam,
    body: DocumentDetails,
    response: Document,
  }),
  getAuditSettings: defineRoute({
    method: 'GET',
    path: '/settings/audit',
    summary: 'Fuel and distance audit thresholds',
    tag: 'settings',
    access: access.staff,
    response: AuditSettings,
  }),
  updateAuditSettings: defineRoute({
    method: 'PATCH',
    path: '/settings/audit',
    summary: 'Change audit thresholds',
    tag: 'settings',
    access: access.roles('owner'),
    body: AuditSettings.partial(),
    response: AuditSettings,
  }),
  getDriverPay: defineRoute({
    method: 'GET',
    path: '/settings/driver-pay',
    summary: 'Default driver pay rule',
    tag: 'settings',
    access: access.staff,
    response: PayRule,
  }),
  updateDriverPay: defineRoute({
    method: 'PUT',
    path: '/settings/driver-pay',
    summary: 'Change the default driver pay rule (affects unsettled days only)',
    tag: 'settings',
    access: access.roles('owner'),
    body: PayRule,
    response: PayRule,
  }),
};
