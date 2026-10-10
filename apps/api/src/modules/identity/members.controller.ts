import { Controller } from '@nestjs/common';
import { memberRoutes as r, type RouteInput, type RouteOutput } from '@taxcy/contracts';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { Input, Route, Tenant } from '../../platform/http/route.js';
import { Db } from '../../platform/prisma.service.js';
import { MembersService } from './members.service.js';

@Controller()
export class MembersController {
  constructor(
    private readonly db: Db,
    private readonly members: MembersService,
  ) {}

  @Route(r.listMembers)
  listMembers(@Tenant() a: TenantAuth): Promise<RouteOutput<typeof r.listMembers>> {
    return this.db.tenant(a.orgId, (tx) => this.members.list(tx));
  }

  @Route(r.inviteManager)
  inviteManager(
    @Tenant() a: TenantAuth,
    @Input() { body }: RouteInput<typeof r.inviteManager>,
  ): Promise<RouteOutput<typeof r.inviteManager>> {
    return this.db.tenant(a.orgId, (tx) => this.members.inviteManager(tx, body));
  }

  @Route(r.removeManager)
  removeManager(
    @Tenant() a: TenantAuth,
    @Input() { params }: RouteInput<typeof r.removeManager>,
  ): Promise<RouteOutput<typeof r.removeManager>> {
    return this.db.tenant(a.orgId, (tx) => this.members.removeManager(tx, params.id));
  }
}
