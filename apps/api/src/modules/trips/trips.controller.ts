import { Controller } from '@nestjs/common';
import { tripRoutes as r, type RouteInput, type RouteOutput } from '@taxcy/contracts';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { Input, Route, Tenant } from '../../platform/http/route.js';
import { IdempotencyKey } from './idempotency-key.js';
import { TripsService } from './trips.service.js';

type Out<R extends (typeof r)[keyof typeof r]> = Promise<RouteOutput<R>>;

@Controller()
export class TripsController {
  constructor(private readonly trips: TripsService) {}

  @Route(r.list)
  list(@Tenant() a: TenantAuth, @Input() { query }: RouteInput<typeof r.list>): Out<typeof r.list> {
    return this.trips.list(a, query);
  }

  @Route(r.create)
  create(
    @Tenant() a: TenantAuth,
    @Input() { body }: RouteInput<typeof r.create>,
  ): Out<typeof r.create> {
    return this.trips.create(a, body);
  }

  @Route(r.get)
  get(@Tenant() a: TenantAuth, @Input() { params }: RouteInput<typeof r.get>): Out<typeof r.get> {
    return this.trips.get(a, params.id);
  }

  @Route(r.update)
  update(
    @Tenant() a: TenantAuth,
    @Input() { params, body }: RouteInput<typeof r.update>,
  ): Out<typeof r.update> {
    return this.trips.update(a, params.id, body);
  }

  @Route(r.events)
  events(
    @Tenant() a: TenantAuth,
    @Input() { params }: RouteInput<typeof r.events>,
  ): Out<typeof r.events> {
    return this.trips.events(a, params.id);
  }

  @Route(r.assign)
  assign(
    @Tenant() a: TenantAuth,
    @IdempotencyKey() key: string,
    @Input() { params, body }: RouteInput<typeof r.assign>,
  ): Out<typeof r.assign> {
    return this.trips.assign(a, params.id, key, body);
  }

  @Route(r.unassign)
  unassign(
    @Tenant() a: TenantAuth,
    @IdempotencyKey() key: string,
    @Input() { params }: RouteInput<typeof r.unassign>,
  ): Out<typeof r.unassign> {
    return this.trips.unassign(a, params.id, key);
  }

  @Route(r.start)
  start(
    @Tenant() a: TenantAuth,
    @IdempotencyKey() key: string,
    @Input() { params, body }: RouteInput<typeof r.start>,
  ): Out<typeof r.start> {
    return this.trips.start(a, params.id, key, body);
  }

  @Route(r.end)
  end(
    @Tenant() a: TenantAuth,
    @IdempotencyKey() key: string,
    @Input() { params, body }: RouteInput<typeof r.end>,
  ): Out<typeof r.end> {
    return this.trips.end(a, params.id, key, body);
  }

  @Route(r.cancel)
  cancel(
    @Tenant() a: TenantAuth,
    @IdempotencyKey() key: string,
    @Input() { params, body }: RouteInput<typeof r.cancel>,
  ): Out<typeof r.cancel> {
    return this.trips.cancel(a, params.id, key, body.reason);
  }

  @Route(r.requestCancellation)
  requestCancellation(
    @Tenant() a: TenantAuth,
    @IdempotencyKey() key: string,
    @Input() { params, body }: RouteInput<typeof r.requestCancellation>,
  ): Out<typeof r.requestCancellation> {
    return this.trips.requestCancellation(a, params.id, key, body);
  }

  @Route(r.approveCancellation)
  approveCancellation(
    @Tenant() a: TenantAuth,
    @IdempotencyKey() key: string,
    @Input() { params, body }: RouteInput<typeof r.approveCancellation>,
  ): Out<typeof r.approveCancellation> {
    return this.trips.approveCancellation(a, params.id, key, body);
  }

  @Route(r.rejectCancellation)
  rejectCancellation(
    @Tenant() a: TenantAuth,
    @IdempotencyKey() key: string,
    @Input() { params, body }: RouteInput<typeof r.rejectCancellation>,
  ): Out<typeof r.rejectCancellation> {
    return this.trips.rejectCancellation(a, params.id, key, body.note);
  }

  @Route(r.withdrawCancellation)
  withdrawCancellation(
    @Tenant() a: TenantAuth,
    @IdempotencyKey() key: string,
    @Input() { params }: RouteInput<typeof r.withdrawCancellation>,
  ): Out<typeof r.withdrawCancellation> {
    return this.trips.withdrawCancellation(a, params.id, key);
  }

  @Route(r.addCharge)
  addCharge(
    @Tenant() a: TenantAuth,
    @Input() { params, body }: RouteInput<typeof r.addCharge>,
  ): Out<typeof r.addCharge> {
    return this.trips.addCharge(a, params.id, body);
  }

  @Route(r.voidCharge)
  voidCharge(
    @Tenant() a: TenantAuth,
    @Input() { params }: RouteInput<typeof r.voidCharge>,
  ): Out<typeof r.voidCharge> {
    return this.trips.voidCharge(a, params.id, params.chargeId);
  }

  @Route(r.myTrips)
  myTrips(
    @Tenant() a: TenantAuth,
    @Input() { query }: RouteInput<typeof r.myTrips>,
  ): Out<typeof r.myTrips> {
    return this.trips.myTrips(a, query.since);
  }
}
