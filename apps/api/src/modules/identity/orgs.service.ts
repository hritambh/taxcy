import { Injectable } from '@nestjs/common';
import type { OrgKind, Session } from '@taxcy/contracts';
import type { AuthContext } from '../../platform/auth/auth-context.js';
import { newId } from '../../platform/ids.js';
import { Db } from '../../platform/prisma.service.js';
import { SessionService } from './session.service.js';

@Injectable()
export class OrgsService {
  constructor(
    private readonly db: Db,
    private readonly sessions: SessionService,
  ) {}

  /**
   * Creates an org with the caller as owner. A DCO (owner-driver) is an org of one:
   * the owner is also its driver, with a driver profile so trips can be assigned to them.
   */
  async create(
    auth: AuthContext,
    input: { name: string; kind: OrgKind; refreshToken: string },
  ): Promise<Session> {
    const orgId = newId();
    await this.db.tenant(orgId, async (tx) => {
      const user = await tx.user.findUniqueOrThrow({ where: { id: auth.userId } });
      await tx.organization.create({ data: { id: orgId, name: input.name, kind: input.kind } });
      await tx.orgSettings.create({ data: { orgId } });
      const membership = await tx.membership.create({
        data: {
          id: newId(),
          orgId,
          userId: auth.userId,
          roles: input.kind === 'dco' ? ['owner', 'driver'] : ['owner'],
        },
      });
      if (input.kind === 'dco') {
        await tx.driver.create({
          data: {
            id: newId(),
            orgId,
            membershipId: membership.id,
            userId: auth.userId,
            name: user.name ?? input.name,
          },
        });
      }
    });
    return this.sessions.rotateInto(auth, input.refreshToken, orgId);
  }
}
