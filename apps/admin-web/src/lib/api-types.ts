import type { paths } from '@taxcy/api-client';

/** The JSON body of a response object from the generated OpenAPI types. */
type Json<R> = R extends { content: { 'application/json': infer B } } ? B : never;

type Get<P extends keyof paths> = paths[P] extends { get: { responses: { 200: infer R } } }
  ? Json<R>
  : never;
type Post<P extends keyof paths> = paths[P] extends { post: { responses: { 200: infer R } } }
  ? Json<R>
  : never;

type Body<P extends keyof paths, M extends 'post' | 'patch' | 'put'> =
  paths[P] extends Record<M, { requestBody?: { content: { 'application/json': infer B } } }>
    ? B
    : never;

export type CreateTripBody = Body<'/trips', 'post'>;
export type CreateVehicleBody = Body<'/vehicles', 'post'>;
export type UpdateVehicleBody = Body<'/vehicles/{id}', 'patch'>;

// Wire types (dates are ISO strings), derived from the API's OpenAPI document.
export type Session = Post<'/auth/otp/verify'>;
export type Membership = Session['memberships'][number];
export type AuthConfig = Get<'/auth/config'>;
export type Me = Get<'/me'>;
export type Vehicle = Get<'/vehicles/{id}'>;
export type VehicleModel = Get<'/vehicle-models'>[number];
export type Driver = Get<'/drivers/{id}'>;
export type DocumentRow = Get<'/documents'>[number];
export type Trip = Get<'/trips/{id}'>;
export type TripEvent = Get<'/trips/{id}/events'>[number];
export type TripRoute = Get<'/trips/{id}/route'>;
export type DistanceCheck = NonNullable<Get<'/trips/{id}/distance-check'>>;
export type FuelFill = Get<'/fuel-fills'>[number];
export type VehicleFuelAudit = Get<'/vehicles/{id}/fuel-cycles'>;
export type FuelCycle = VehicleFuelAudit['cycles'][number];
export type Alert = Get<'/alerts'>[number];
export type AlertSummary = Get<'/alerts/summary'>;
export type ReviewItem = Get<'/review-items'>[number];
export type SettlementSummary = Get<'/settlements'>[number];
export type SettlementDetail = Get<'/settlements/{date}/drivers/{driverId}'>;
export type SettlementLine = SettlementDetail['lines'][number];
export type AuditSettings = Get<'/settings/audit'>;
export type PayRule = Get<'/settings/driver-pay'>;
export type TripStatus = Trip['status'];
export type TripCommand = Trip['allowedCommands'][number];
