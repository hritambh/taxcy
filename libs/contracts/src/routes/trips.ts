import { z } from 'zod';
import { DateTime, FuelKind, Id, PaidBy, Paise, PhoneE164 } from '../common.js';
import { access, defineRoute, MembershipRole } from '../http.js';
import { GeoPoint } from './media.js';

export const TripType = z.enum(['one_way', 'round_trip', 'local_rental']);
export type TripType = z.infer<typeof TripType>;
export const TripStatus = z.enum([
  'created',
  'assigned',
  'started',
  'ended',
  'settled',
  'cancelled',
]);
export type TripStatus = z.infer<typeof TripStatus>;
export const TripCommand = z.enum([
  'assign',
  'reassign',
  'unassign',
  'start',
  'end',
  'requestCancel',
  'approveCancel',
  'rejectCancel',
  'withdrawCancel',
  'cancel',
  'settle',
]);
export const ChargeKind = z.enum([
  'toll',
  'parking',
  'state_tax',
  'driver_allowance',
  'night_charge',
  'extra_km',
  'other',
]);
export const CollectionMethod = z.enum(['cash', 'upi', 'card']);

const Place = z.object({
  text: z.string().trim().min(1).max(200),
  point: GeoPoint.nullable().optional(),
});

export const OdometerReading = z.object({
  id: Id,
  typedKm: z.number().int(),
  ocrKm: z.number().int().nullable(),
  mediaId: Id,
  capturedAt: DateTime,
});

/** An odometer reading as captured on the phone: photo (already registered via /media) + typed km. */
export const OdometerInput = z.object({
  id: Id,
  typedKm: z.number().int().nonnegative().max(9_999_999),
  mediaId: Id,
  capturedAt: DateTime,
});

export const ChargeInput = z.object({
  id: Id,
  kind: ChargeKind,
  amountPaise: Paise,
  /**
   * True when the driver paid it out of pocket; reimbursed in settlement. Ignored
   * (stored as false) for extra fare: night_charge, extra_km and driver_allowance,
   * which the customer pays on top of the quoted fare.
   */
  paidByDriver: z.boolean(),
  mediaId: Id.optional(),
  note: z.string().max(200).optional(),
});

export const CollectionInput = z.object({
  id: Id,
  method: CollectionMethod,
  amountPaise: Paise,
  reference: z.string().max(100).optional(),
  collectedAt: DateTime.optional(),
});

export const TripCharge = ChargeInput.extend({
  mediaId: Id.nullable(),
  note: z.string().nullable(),
  enteredBy: Id,
  enteredRole: MembershipRole,
  voidedAt: DateTime.nullable(),
  createdAt: DateTime,
});

export const TripCollection = z.object({
  id: Id,
  method: CollectionMethod,
  amountPaise: Paise,
  reference: z.string().nullable(),
  collectedAt: DateTime,
});

/** A fuel fill logged during the trip (voided fills are left out). */
export const TripFuelFill = z.object({
  id: Id,
  fuel: FuelKind,
  /** Millilitres (petrol, diesel) or grams (CNG). */
  quantityMilli: z.number().int(),
  costPaise: Paise,
  paidBy: PaidBy,
  isFullTank: z.boolean(),
  filledAt: DateTime,
});

export const CancellationRequest = z.object({
  id: Id,
  status: z.enum(['pending', 'approved', 'rejected', 'withdrawn']),
  reason: z.string(),
  requestedBy: Id,
  requestedRole: MembershipRole,
  endOdometer: OdometerReading.nullable(),
  decidedBy: Id.nullable(),
  decidedAt: DateTime.nullable(),
  decisionNote: z.string().nullable(),
  createdAt: DateTime,
});

export const Trip = z.object({
  id: Id,
  tripType: TripType,
  status: TripStatus,
  channel: z.string(),
  customer: z.object({ name: z.string(), phone: z.string().nullable() }).nullable(),
  from: z.object({ text: z.string(), point: GeoPoint.nullable() }),
  to: z.object({ text: z.string(), point: GeoPoint.nullable() }).nullable(),
  scheduledStartAt: DateTime,
  scheduledEndAt: DateTime,
  vehicle: z.object({ id: Id, registrationNo: z.string(), model: z.string() }).nullable(),
  driver: z.object({ id: Id, name: z.string() }).nullable(),
  quotedFarePaise: Paise,
  cancellationFarePaise: Paise.nullable(),
  startOdometer: OdometerReading.nullable(),
  endOdometer: OdometerReading.nullable(),
  startedAt: DateTime.nullable(),
  endedAt: DateTime.nullable(),
  cancelledAt: DateTime.nullable(),
  cancelReason: z.string().nullable(),
  /** The pending (or most recent) cancellation request, if any. */
  cancellationRequest: CancellationRequest.nullable(),
  charges: z.array(TripCharge),
  collections: z.array(TripCollection),
  fuelFills: z.array(TripFuelFill),
  /** Commands valid right now, for showing the right buttons. */
  allowedCommands: z.array(TripCommand),
  version: z.number().int(),
  createdAt: DateTime,
  updatedAt: DateTime,
});
export type Trip = z.infer<typeof Trip>;

export const TripEvent = z.object({
  id: Id,
  seq: z.number().int(),
  eventType: z.string(),
  fromStatus: TripStatus.nullable(),
  toStatus: TripStatus.nullable(),
  actorUserId: Id.nullable(),
  actorRole: MembershipRole.nullable(),
  occurredAt: DateTime,
  recordedAt: DateTime,
  payload: z.record(z.string(), z.unknown()),
});

const IdParam = z.object({ id: Id });
/** When the action happened on the device (may be well before it syncs). */
const OccurredAt = { occurredAt: DateTime };

const TripDetails = z.object({
  tripType: TripType,
  customer: z
    .object({ name: z.string().trim().min(1).max(100), phone: PhoneE164.optional() })
    .optional(),
  from: Place,
  to: Place.optional(),
  scheduledStartAt: DateTime,
  scheduledEndAt: DateTime,
  quotedFarePaise: Paise,
});

export const tripRoutes = {
  list: defineRoute({
    method: 'GET',
    path: '/trips',
    summary: 'Trips, newest scheduled first',
    tag: 'trips',
    access: access.staff,
    query: z.object({
      status: TripStatus.optional(),
      driverId: Id.optional(),
      vehicleId: Id.optional(),
      from: DateTime.optional(),
      to: DateTime.optional(),
      limit: z.coerce.number().int().min(1).max(200).default(50),
    }),
    response: z.array(Trip),
  }),
  create: defineRoute({
    method: 'POST',
    path: '/trips',
    summary: 'Create a trip, optionally assigning it straight away',
    tag: 'trips',
    access: access.staff,
    status: 201,
    body: TripDetails.extend({ vehicleId: Id.optional(), driverId: Id.optional() }),
    response: Trip,
  }),
  get: defineRoute({
    method: 'GET',
    path: '/trips/{id}',
    summary: 'A trip (drivers see only their own)',
    tag: 'trips',
    access: access.anyMember,
    params: IdParam,
    response: Trip,
  }),
  update: defineRoute({
    method: 'PATCH',
    path: '/trips/{id}',
    summary: 'Edit trip details before it starts',
    tag: 'trips',
    access: access.staff,
    params: IdParam,
    body: TripDetails.partial(),
    response: Trip,
  }),
  events: defineRoute({
    method: 'GET',
    path: '/trips/{id}/events',
    summary: 'Every transition, with actor and device/server times',
    tag: 'trips',
    access: access.anyMember,
    params: IdParam,
    response: z.array(TripEvent),
  }),
  assign: defineRoute({
    method: 'POST',
    path: '/trips/{id}/assign',
    summary: 'Assign or reassign a vehicle and driver',
    tag: 'trips',
    access: access.staff,
    idempotencyKey: true,
    params: IdParam,
    body: z.object({ vehicleId: Id, driverId: Id }),
    response: Trip,
  }),
  unassign: defineRoute({
    method: 'POST',
    path: '/trips/{id}/unassign',
    summary: 'Remove the assignment',
    tag: 'trips',
    access: access.staff,
    idempotencyKey: true,
    params: IdParam,
    response: Trip,
  }),
  start: defineRoute({
    method: 'POST',
    path: '/trips/{id}/start',
    summary: 'Start the trip with an odometer reading',
    tag: 'trips',
    access: access.anyMember,
    idempotencyKey: true,
    params: IdParam,
    body: z.object({ odometer: OdometerInput, ...OccurredAt }),
    response: Trip,
  }),
  end: defineRoute({
    method: 'POST',
    path: '/trips/{id}/end',
    summary: 'End the trip with an odometer reading, plus what was collected and spent',
    tag: 'trips',
    access: access.anyMember,
    idempotencyKey: true,
    params: IdParam,
    body: z.object({
      odometer: OdometerInput,
      ...OccurredAt,
      collections: z.array(CollectionInput).max(10).default([]),
      charges: z.array(ChargeInput).max(20).default([]),
    }),
    response: Trip,
  }),
  cancel: defineRoute({
    method: 'POST',
    path: '/trips/{id}/cancel',
    summary: 'Cancel a trip that has not started',
    tag: 'trips',
    access: access.staff,
    idempotencyKey: true,
    params: IdParam,
    body: z.object({ reason: z.string().trim().min(1).max(500) }),
    response: Trip,
  }),
  requestCancellation: defineRoute({
    method: 'POST',
    path: '/trips/{id}/cancellation-requests',
    summary: 'Ask to cancel a started trip (needs a reason and the end odometer; staff approve)',
    tag: 'trips',
    access: access.anyMember,
    idempotencyKey: true,
    params: IdParam,
    body: z.object({
      id: Id,
      reason: z.string().trim().min(1).max(500),
      endOdometer: OdometerInput,
      ...OccurredAt,
    }),
    response: Trip,
  }),
  approveCancellation: defineRoute({
    method: 'POST',
    path: '/cancellation-requests/{id}/approve',
    summary: 'Approve a cancellation request; optionally charge a cancellation fare',
    tag: 'trips',
    access: access.staff,
    idempotencyKey: true,
    params: IdParam,
    body: z.object({
      cancellationFarePaise: Paise.default(0),
      note: z.string().max(500).optional(),
    }),
    response: Trip,
  }),
  rejectCancellation: defineRoute({
    method: 'POST',
    path: '/cancellation-requests/{id}/reject',
    summary: 'Reject a cancellation request; the trip continues',
    tag: 'trips',
    access: access.staff,
    idempotencyKey: true,
    params: IdParam,
    body: z.object({ note: z.string().trim().min(1).max(500) }),
    response: Trip,
  }),
  withdrawCancellation: defineRoute({
    method: 'POST',
    path: '/cancellation-requests/{id}/withdraw',
    summary: 'Withdraw your cancellation request',
    tag: 'trips',
    access: access.anyMember,
    idempotencyKey: true,
    params: IdParam,
    response: Trip,
  }),
  addCharge: defineRoute({
    method: 'POST',
    path: '/trips/{id}/charges',
    summary: 'Add a toll, parking, allowance or other charge (driver or staff; idempotent on id)',
    tag: 'trips',
    access: access.anyMember,
    status: 201,
    params: IdParam,
    body: ChargeInput,
    response: Trip,
  }),
  voidCharge: defineRoute({
    method: 'POST',
    path: '/trips/{id}/charges/{chargeId}/void',
    summary: 'Void a wrong charge before the day is settled',
    tag: 'trips',
    access: access.staff,
    params: z.object({ id: Id, chargeId: Id }),
    response: Trip,
  }),
  myTrips: defineRoute({
    method: 'GET',
    path: '/me/trips',
    summary: "The signed-in driver's current and recent trips (for the app to sync)",
    tag: 'trips',
    access: access.roles('driver'),
    query: z.object({ since: DateTime.optional() }),
    response: z.array(Trip),
  }),
};
