import { Controller } from '@nestjs/common';
import { mediaRoutes as r, type RouteInput, type RouteOutput } from '@taxcy/contracts';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { Input, Route, Tenant } from '../../platform/http/route.js';
import { MediaService } from './media.service.js';

@Controller()
export class MediaController {
  constructor(private readonly media: MediaService) {}

  @Route(r.create)
  create(
    @Tenant() auth: TenantAuth,
    @Input() { body }: RouteInput<typeof r.create>,
  ): Promise<RouteOutput<typeof r.create>> {
    return this.media.create(auth, body);
  }

  @Route(r.complete)
  async complete(
    @Tenant() auth: TenantAuth,
    @Input() { params }: RouteInput<typeof r.complete>,
  ): Promise<RouteOutput<typeof r.complete>> {
    const row = await this.media.complete(auth, params.id);
    return {
      id: row.id,
      kind: row.kind,
      status: row.status,
      contentType: row.contentType,
      capturedAt: row.capturedAt,
      uploadedAt: row.uploadedAt,
    };
  }

  @Route(r.url)
  url(
    @Tenant() auth: TenantAuth,
    @Input() { params }: RouteInput<typeof r.url>,
  ): Promise<RouteOutput<typeof r.url>> {
    return this.media.viewUrl(auth, params.id);
  }
}
