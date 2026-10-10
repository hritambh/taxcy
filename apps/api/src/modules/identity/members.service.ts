import { Injectable } from '@nestjs/common';
import { MemberStatus, type Member } from '@taxcy/contracts';
import type { Prisma, TenantTx } from '@taxcy/db';
import { AppError, notFound } from '../../platform/errors.js';
import { newId } from '../../platform/ids.js';

const memberSelect = {
  id: true,
  userId: true,
  roles: true,
  status: true,
  createdAt: true,
  user: { select: { name: true, phoneE164: true } },
} as const satisfies Prisma.MembershipSelect;
type MemberRow = Prisma.MembershipGetPayload<{ select: typeof memberSelect }>;

const toMember = (row: MemberRow): Member => ({
  id: row.id,
  userId: row.userId,
  name: row.user.name,
  phone: row.user.phoneE164,
  roles: row.roles,
  status: MemberStatus.parse(row.status),
  createdAt: row.createdAt,
});

/**
 * Who has access to the org. Drivers are added through the drivers routes (they
 * need a driver profile); this covers manager access. A removed manager keeps
 * their current access token until it expires (at most 15 minutes); refreshing
 * it no longer includes this org.
 */
@Injectable()
export class MembersService {
  async list(tx: TenantTx): Promise<Member[]> {
    const rows = await tx.membership.findMany({
      where: { orgId: tx.orgId },
      select: memberSelect,
      orderBy: { createdAt: 'asc' },
    });
    return rows.map(toMember);
  }

  async inviteManager(tx: TenantTx, input: { name: string; phone: string }): Promise<Member> {
    const user = await tx.user.upsert({
      where: { phoneE164: input.phone },
      update: {},
      create: { id: newId(), phoneE164: input.phone, name: input.name },
    });
    if (!user.name) await tx.user.update({ where: { id: user.id }, data: { name: input.name } });

    const existing = await tx.membership.findUnique({
      where: { orgId_userId: { orgId: tx.orgId, userId: user.id } },
    });
    if (!existing) {
      const id = newId();
      await tx.membership.create({
        data: { id, orgId: tx.orgId, userId: user.id, roles: ['manager'], status: 'invited' },
      });
      return this.require(tx, id);
    }
    if (existing.status === 'suspended') {
      // Suspended members keep their last role on record; they come back as managers only.
      await tx.membership.update({
        where: { id: existing.id },
        data: { roles: ['manager'], status: 'invited' },
      });
      return this.require(tx, existing.id);
    }
    if (existing.roles.includes('owner') || existing.roles.includes('manager')) {
      throw new AppError('CONFLICT', `${input.phone} can already manage this organization`);
    }
    await tx.membership.update({
      where: { id: existing.id },
      data: { roles: [...existing.roles, 'manager'] },
    });
    return this.require(tx, existing.id);
  }

  async removeManager(tx: TenantTx, id: string): Promise<Member> {
    const member = await this.require(tx, id);
    if (member.status === 'suspended' || !member.roles.includes('manager')) {
      throw new AppError('CONFLICT', 'This member is not a manager');
    }
    const roles = member.roles.filter((r) => r !== 'manager');
    // A membership always keeps at least one role (a database check), so removing the
    // last one suspends the membership instead and leaves the role on record.
    await tx.membership.update({
      where: { id },
      data: roles.length > 0 ? { roles } : { status: 'suspended' },
    });
    return this.require(tx, id);
  }

  private async require(tx: TenantTx, id: string): Promise<Member> {
    const row = await tx.membership.findFirst({
      where: { id, orgId: tx.orgId },
      select: memberSelect,
    });
    if (!row) throw notFound('Member');
    return toMember(row);
  }
}
