import { Controller, Req } from '@nestjs/common';
import { identityRoutes as r, type RouteInput, type RouteOutput } from '@taxcy/contracts';
import type { Request } from 'express';
import type { AuthContext } from '../../platform/auth/auth-context.js';
import { Auth, Input, Route } from '../../platform/http/route.js';
import { OrgsService } from './orgs.service.js';
import { OtpService } from './otp.service.js';
import { SessionService } from './session.service.js';

@Controller()
export class AuthController {
  constructor(
    private readonly otp: OtpService,
    private readonly sessions: SessionService,
    private readonly orgs: OrgsService,
  ) {}

  @Route(r.requestOtp)
  requestOtp(
    @Input() { body }: RouteInput<typeof r.requestOtp>,
    @Req() req: Request,
  ): Promise<RouteOutput<typeof r.requestOtp>> {
    return this.otp.request(body.phone, req.ip ?? 'unknown');
  }

  @Route(r.verifyOtp)
  verifyOtp(
    @Input() { body }: RouteInput<typeof r.verifyOtp>,
  ): Promise<RouteOutput<typeof r.verifyOtp>> {
    return this.sessions.login({
      phone: body.phone,
      code: body.code,
      deviceId: body.deviceId,
      platform: body.platform,
      appVersion: body.appVersion,
    });
  }

  @Route(r.refresh)
  refresh(@Input() { body }: RouteInput<typeof r.refresh>): Promise<RouteOutput<typeof r.refresh>> {
    return this.sessions.refresh(body.refreshToken);
  }

  @Route(r.logout)
  async logout(@Input() { body }: RouteInput<typeof r.logout>): Promise<void> {
    await this.sessions.logout(body.refreshToken);
  }

  @Route(r.switchOrg)
  switchOrg(
    @Auth() auth: AuthContext,
    @Input() { body }: RouteInput<typeof r.switchOrg>,
  ): Promise<RouteOutput<typeof r.switchOrg>> {
    return this.sessions.switchOrg(auth, body.refreshToken, body.orgId);
  }

  @Route(r.me)
  async me(@Auth() auth: AuthContext): Promise<RouteOutput<typeof r.me>> {
    const { user, memberships } = await this.sessions.me(auth);
    return {
      user: { id: user.id, phone: user.phoneE164, name: user.name },
      activeOrgId: auth.orgId,
      roles: auth.roles,
      memberships,
    };
  }

  @Route(r.updateMe)
  async updateMe(
    @Auth() auth: AuthContext,
    @Input() { body }: RouteInput<typeof r.updateMe>,
  ): Promise<RouteOutput<typeof r.updateMe>> {
    const user = await this.sessions.updateName(auth, body.name);
    return { id: user.id, phone: user.phoneE164, name: user.name };
  }

  @Route(r.createOrg)
  createOrg(
    @Auth() auth: AuthContext,
    @Input() { body }: RouteInput<typeof r.createOrg>,
  ): Promise<RouteOutput<typeof r.createOrg>> {
    return this.orgs.create(auth, body);
  }
}
