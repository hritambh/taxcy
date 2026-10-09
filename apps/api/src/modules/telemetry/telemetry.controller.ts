import { Controller } from '@nestjs/common';
import { telemetryRoutes as r, type RouteInput, type RouteOutput } from '@taxcy/contracts';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { Input, Route, Tenant } from '../../platform/http/route.js';
import { TelemetryService } from './telemetry.service.js';

@Controller()
export class TelemetryController {
  constructor(private readonly telemetry: TelemetryService) {}

  @Route(r.uploadBatch)
  upload(
    @Tenant() a: TenantAuth,
    @Input() { params, body }: RouteInput<typeof r.uploadBatch>,
  ): Promise<RouteOutput<typeof r.uploadBatch>> {
    return this.telemetry.ingest(a, params.id, body.points);
  }

  @Route(r.route)
  route(
    @Tenant() a: TenantAuth,
    @Input() { params }: RouteInput<typeof r.route>,
  ): Promise<RouteOutput<typeof r.route>> {
    return this.telemetry.route(a, params.id);
  }

  @Route(r.distanceCheck)
  distanceCheck(
    @Tenant() a: TenantAuth,
    @Input() { params }: RouteInput<typeof r.distanceCheck>,
  ): Promise<RouteOutput<typeof r.distanceCheck>> {
    return this.telemetry.distanceCheck(a, params.id);
  }
}
