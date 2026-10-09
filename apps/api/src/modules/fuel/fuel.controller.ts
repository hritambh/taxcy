import { Controller } from '@nestjs/common';
import { fuelRoutes as r, type RouteInput, type RouteOutput } from '@taxcy/contracts';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { Input, Route, Tenant } from '../../platform/http/route.js';
import { FuelService } from './fuel.service.js';

@Controller()
export class FuelController {
  constructor(private readonly fuel: FuelService) {}

  @Route(r.record)
  record(
    @Tenant() a: TenantAuth,
    @Input() { body }: RouteInput<typeof r.record>,
  ): Promise<RouteOutput<typeof r.record>> {
    return this.fuel.record(a, body);
  }

  @Route(r.list)
  list(
    @Tenant() a: TenantAuth,
    @Input() { query }: RouteInput<typeof r.list>,
  ): Promise<RouteOutput<typeof r.list>> {
    return this.fuel.list(a, query);
  }

  @Route(r.void)
  void(
    @Tenant() a: TenantAuth,
    @Input() { params, body }: RouteInput<typeof r.void>,
  ): Promise<RouteOutput<typeof r.void>> {
    return this.fuel.void(a, params.id, body.reason);
  }

  @Route(r.vehicleAudit)
  vehicleAudit(
    @Tenant() a: TenantAuth,
    @Input() { params }: RouteInput<typeof r.vehicleAudit>,
  ): Promise<RouteOutput<typeof r.vehicleAudit>> {
    return this.fuel.vehicleAudit(a, params.id);
  }
}
