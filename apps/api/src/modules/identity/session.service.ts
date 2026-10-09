import { Inject, Injectable } from '@nestjs/common';
import type { Membership, Session } from '@taxcy/contracts';
import type { SystemTx } from '@taxcy/db';
import { createHash, randomBytes } from 'node:crypto';
import type { AuthContext } from '../../platform/auth/auth-context.js';
import { AccessTokens } from '../../platform/auth/tokens.js';
import { APP_CONFIG, type AppConfig } from '../../platform/config.js';
import { AppError } from '../../platform/errors.js';
import { newId } from '../../platform/ids.js';
import { Db } from '../../platform/prisma.service.js';
import { IdentityRepository, type UserRow } from './identity.repository.js';
import { OtpService } from './otp.service.js';

const hashToken = (token: string): string => createHash('sha256').update(token).digest('hex');

/** Thrown inside a transaction when a rotated refresh token is presented again. */
class RefreshTokenReuse extends Error {
  constructor(readonly familyId: string) {
    super('Refresh token reuse');
  }
}

interface IssueOptions {
  userId: string;
  orgId: string | null;
  deviceId: string | null;
  /** Continue an existing rotation family (refresh, switch-org) or start a new one (login). */
  familyId?: string;
}

/**
 * Sessions are an access token (JWT, 15 min) plus an opaque refresh token stored
 * hashed. Every refresh rotates the token; presenting an already-rotated token is
 * treated as theft and revokes the whole family.
 */
@Injectable()
export class SessionService {
  constructor(
    @Inject(APP_CONFIG) private readonly config: AppConfig,
    private readonly db: Db,
    private readonly repo: IdentityRepository,
    private readonly otp: OtpService,
    private readonly accessTokens: AccessTokens,
  ) {}

  async login(input: {
    phone: string;
    code: string;
    deviceId: string;
    platform: string;
    appVersion: string | undefined;
  }): Promise<Session> {
    await this.otp.verify(input.phone, input.code);
    return this.db.system(async (tx) => {
      const user = await this.repo.upsertUserByPhone(tx, input.phone);
      await this.repo.upsertDevice(tx, {
        id: input.deviceId,
        userId: user.id,
        platform: input.platform,
        appVersion: input.appVersion,
      });
      await this.repo.activateInvitedMemberships(tx, user.id);
      const memberships = await this.repo.activeMemberships(tx, user.id);
      return this.issue(tx, user, memberships, {
        userId: user.id,
        orgId: memberships[0]?.orgId ?? null,
        deviceId: input.deviceId,
      });
    });
  }

  async refresh(refreshToken: string): Promise<Session> {
    return this.withReuseDetection(() =>
      this.db.system(async (tx) => {
        const current = await this.useRefreshToken(tx, refreshToken);
        return this.rotate(tx, current, current.orgId);
      }),
    );
  }

  async switchOrg(auth: AuthContext, refreshToken: string, orgId: string): Promise<Session> {
    return this.withReuseDetection(() =>
      this.db.system(async (tx) => {
        const current = await this.useRefreshToken(tx, refreshToken);
        if (current.userId !== auth.userId) {
          throw new AppError('UNAUTHENTICATED', 'Refresh token belongs to another user');
        }
        return this.rotate(tx, current, orgId, { requireOrg: true });
      }),
    );
  }

  /**
   * Reuse is detected inside the rotation transaction, which then rolls back. The
   * family revocation must survive that, so it runs in its own transaction.
   */
  private async withReuseDetection(fn: () => Promise<Session>): Promise<Session> {
    try {
      return await fn();
    } catch (error) {
      if (!(error instanceof RefreshTokenReuse)) throw error;
      await this.db.system((tx) => this.repo.revokeFamily(tx, error.familyId));
      throw new AppError('UNAUTHENTICATED', 'Refresh token has been revoked');
    }
  }

  async logout(refreshToken: string): Promise<void> {
    await this.db.system(async (tx) => {
      const token = await this.repo.findRefreshToken(tx, hashToken(refreshToken));
      if (token) await this.repo.revokeFamily(tx, token.familyId);
    });
  }

  async me(auth: AuthContext): Promise<{ user: UserRow; memberships: Membership[] }> {
    return this.db.system(async (tx) => {
      const user = await this.repo.findUser(tx, auth.userId);
      if (!user) throw new AppError('UNAUTHENTICATED', 'User no longer exists');
      return { user, memberships: await this.repo.activeMemberships(tx, auth.userId) };
    });
  }

  async updateName(auth: AuthContext, name: string): Promise<UserRow> {
    return this.db.system((tx) => this.repo.updateUserName(tx, auth.userId, name));
  }

  /** Rotates `refreshToken` into a new session for `orgId` (used after creating an org). */
  async rotateInto(auth: AuthContext, refreshToken: string, orgId: string): Promise<Session> {
    return this.switchOrg(auth, refreshToken, orgId);
  }

  private async useRefreshToken(tx: SystemTx, refreshToken: string) {
    const token = await this.repo.findRefreshToken(tx, hashToken(refreshToken));
    if (!token) throw new AppError('UNAUTHENTICATED', 'Unknown refresh token');
    if (token.revokedAt) {
      // A rotated token came back: someone else may hold a copy. End the whole family.
      if (token.replacedBy) throw new RefreshTokenReuse(token.familyId);
      throw new AppError('UNAUTHENTICATED', 'Refresh token has been revoked');
    }
    if (token.expiresAt <= new Date())
      throw new AppError('UNAUTHENTICATED', 'Refresh token has expired');
    return token;
  }

  private async rotate(
    tx: SystemTx,
    current: { id: string; userId: string; familyId: string; deviceId: string | null },
    wantedOrgId: string | null,
    options: { requireOrg?: boolean } = {},
  ): Promise<Session> {
    const user = await this.repo.findUser(tx, current.userId);
    if (!user) throw new AppError('UNAUTHENTICATED', 'User no longer exists');
    const memberships = await this.repo.activeMemberships(tx, user.id);
    const stillMember = memberships.some((m) => m.orgId === wantedOrgId);
    if (options.requireOrg && !stillMember)
      throw new AppError('NOT_FOUND', 'Organization not found');
    const orgId = stillMember ? wantedOrgId : (memberships[0]?.orgId ?? null);
    const session = await this.issue(tx, user, memberships, {
      userId: user.id,
      orgId,
      deviceId: current.deviceId,
      familyId: current.familyId,
    });
    const next = await this.repo.findRefreshToken(tx, hashToken(session.refreshToken));
    if (next) await this.repo.markRotated(tx, current.id, next.id);
    return session;
  }

  private async issue(
    tx: SystemTx,
    user: UserRow,
    memberships: Membership[],
    options: IssueOptions,
  ): Promise<Session> {
    const roles = memberships.find((m) => m.orgId === options.orgId)?.roles ?? [];
    const access = await this.accessTokens.sign({ userId: user.id, orgId: options.orgId, roles });
    const refreshToken = randomBytes(32).toString('base64url');
    const refreshTokenExpiresAt = new Date(
      Date.now() + this.config.JWT_REFRESH_TTL_DAYS * 86_400_000,
    );
    await this.repo.insertRefreshToken(tx, {
      id: newId(),
      userId: user.id,
      orgId: options.orgId,
      familyId: options.familyId ?? newId(),
      tokenHash: hashToken(refreshToken),
      deviceId: options.deviceId,
      expiresAt: refreshTokenExpiresAt,
    });
    return {
      accessToken: access.token,
      accessTokenExpiresAt: access.expiresAt,
      refreshToken,
      refreshTokenExpiresAt,
      user: { id: user.id, phone: user.phoneE164, name: user.name },
      activeOrgId: options.orgId,
      memberships,
    };
  }
}
