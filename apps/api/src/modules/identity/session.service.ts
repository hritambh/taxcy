import { Inject, Injectable } from '@nestjs/common';
import type { Membership, Session } from '@taxcy/contracts';
import type { SystemTx } from '@taxcy/db';
import { createHash, randomBytes } from 'node:crypto';
import { z } from 'zod';
import type { AuthContext } from '../../platform/auth/auth-context.js';
import { AccessTokens } from '../../platform/auth/tokens.js';
import { APP_CONFIG, type AppConfig } from '../../platform/config.js';
import { AppError } from '../../platform/errors.js';
import { newId } from '../../platform/ids.js';
import { Db } from '../../platform/prisma.service.js';
import { RateLimiter } from '../../platform/rate-limit.js';
import { RedisService } from '../../platform/redis.service.js';
import { GOOGLE_VERIFIER, type GoogleIdentity, type GoogleVerifier } from './google.verifier.js';
import { IdentityRepository, type AccountRow, type UserRow } from './identity.repository.js';
import { OtpService } from './otp.service.js';
import { hashPassword, verifyPassword } from './passwords.js';

const hashToken = (token: string): string => createHash('sha256').update(token).digest('hex');

/** Thrown inside a transaction when a rotated refresh token is presented again. */
class RefreshTokenReuse extends Error {
  constructor(readonly familyId: string) {
    super('Refresh token reuse');
  }
}

interface DeviceInput {
  deviceId: string;
  platform: string;
  appVersion: string | undefined;
}

const PendingGoogleLink = z.object({
  sub: z.string(),
  email: z.string().nullable(),
  name: z.string().nullable(),
});
const GOOGLE_LINK_TTL_SECONDS = 600;
const linkKey = (token: string) => `google:link:${hashToken(token)}`;

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
    private readonly redis: RedisService,
    private readonly limiter: RateLimiter,
    @Inject(GOOGLE_VERIFIER) private readonly google: GoogleVerifier,
  ) {}

  get googleMode(): GoogleVerifier['mode'] {
    return this.google.mode;
  }

  /** SMS-code sign-in; creates the user on first sign-in. */
  async login(input: { phone: string; code: string } & DeviceInput): Promise<Session> {
    await this.otp.verify(input.phone, input.code);
    return this.db.system(async (tx) => {
      const user = await this.repo.upsertUserByPhone(tx, input.phone);
      return this.startSession(tx, user, input);
    });
  }

  /**
   * Phone + password sign-up. The SMS code proves the phone is theirs, which matters
   * because invites are matched by phone. A phone that already has a password must
   * log in or reset it; one that only used SMS codes (e.g. an invited driver) gets
   * the password added.
   */
  async signup(
    input: {
      phone: string;
      code: string;
      password: string;
      name: string | undefined;
    } & DeviceInput,
  ): Promise<Session> {
    await this.otp.verify(input.phone, input.code);
    const passwordHash = await hashPassword(input.password);
    return this.db.system(async (tx) => {
      const existing = await this.repo.findAccount(tx, { phoneE164: input.phone });
      if (existing?.passwordHash) {
        throw new AppError(
          'ACCOUNT_EXISTS',
          'This number already has an account; log in or reset your password',
        );
      }
      let user = await this.repo.upsertUserByPhone(tx, input.phone);
      await this.repo.setPassword(tx, user.id, passwordHash);
      if (input.name && !user.name) user = await this.repo.updateUserName(tx, user.id, input.name);
      return this.startSession(tx, user, input);
    });
  }

  async passwordLogin(
    input: { phone: string; password: string; ip: string } & DeviceInput,
  ): Promise<Session> {
    await this.limiter.consume([
      { key: `pwd:phone:${input.phone}:15m`, max: 10, windowSeconds: 900 },
      { key: `pwd:ip:${input.ip}:1h`, max: 100, windowSeconds: 3_600 },
    ]);
    const account = await this.db.system((tx) =>
      this.repo.findAccount(tx, { phoneE164: input.phone }),
    );
    if (!(await verifyPassword(account?.passwordHash ?? null, input.password)) || !account) {
      throw new AppError('INVALID_CREDENTIALS', 'Wrong phone number or password');
    }
    return this.db.system((tx) => this.startSession(tx, account, input));
  }

  /** Sets a new password after an SMS code, and signs out every other session. */
  async resetPassword(
    input: { phone: string; code: string; password: string } & DeviceInput,
  ): Promise<Session> {
    await this.otp.verify(input.phone, input.code);
    const passwordHash = await hashPassword(input.password);
    return this.db.system(async (tx) => {
      const user = await this.repo.upsertUserByPhone(tx, input.phone);
      await this.repo.setPassword(tx, user.id, passwordHash);
      await this.repo.revokeAllForUser(tx, user.id);
      return this.startSession(tx, user, input);
    });
  }

  async changePassword(
    auth: AuthContext,
    input: { currentPassword: string | undefined; newPassword: string },
  ): Promise<void> {
    const account = await this.requireAccount(auth.userId);
    if (account.passwordHash) {
      await this.limiter.consume([
        { key: `pwd:user:${auth.userId}:15m`, max: 10, windowSeconds: 900 },
      ]);
      if (!(await verifyPassword(account.passwordHash, input.currentPassword ?? ''))) {
        throw new AppError('INVALID_CREDENTIALS', 'Your current password is wrong');
      }
    }
    const passwordHash = await hashPassword(input.newPassword);
    await this.db.system((tx) => this.repo.setPassword(tx, auth.userId, passwordHash));
  }

  /**
   * Google sign-in. A Google account already linked to a phone signs straight in.
   * Otherwise the caller must verify a phone (googleLink) with the returned token:
   * the phone is the identity that invites and fleets use.
   */
  async googleSignIn(
    input: { idToken: string } & DeviceInput,
  ): Promise<
    | { status: 'signed_in'; session: Session }
    | { status: 'phone_required'; linkToken: string; email: string | null; name: string | null }
  > {
    const google = await this.google.verify(input.idToken);
    const linked = await this.db.system((tx) =>
      this.repo.findAccount(tx, { googleSub: google.sub }),
    );
    if (linked) {
      return {
        status: 'signed_in',
        session: await this.db.system((tx) => this.startSession(tx, linked, input)),
      };
    }
    const linkToken = randomBytes(32).toString('base64url');
    await this.redis.client.set(
      linkKey(linkToken),
      JSON.stringify(google satisfies GoogleIdentity),
      'EX',
      GOOGLE_LINK_TTL_SECONDS,
    );
    return { status: 'phone_required', linkToken, email: google.email, name: google.name };
  }

  /** Finishes a first Google sign-in: links the Google account to a verified phone. */
  async googleLink(
    input: { linkToken: string; phone: string; code: string } & DeviceInput,
  ): Promise<Session> {
    const key = linkKey(input.linkToken);
    const raw = await this.redis.client.get(key);
    if (!raw) {
      throw new AppError('GOOGLE_TOKEN_INVALID', 'That took too long; sign in with Google again');
    }
    const google = PendingGoogleLink.parse(JSON.parse(raw));
    // The token stays valid until the code is right, so a mistyped code can be retried.
    await this.otp.verify(input.phone, input.code);
    await this.redis.client.del(key);
    return this.db.system(async (tx) => {
      const user = await this.repo.upsertUserByPhone(tx, input.phone);
      const account = await this.repo.findAccount(tx, { id: user.id });
      if (account?.googleSub && account.googleSub !== google.sub) {
        throw new AppError(
          'GOOGLE_ACCOUNT_CONFLICT',
          'This number is already linked to a different Google account',
        );
      }
      const owner = await this.repo.findAccount(tx, { googleSub: google.sub });
      if (owner && owner.id !== user.id) {
        throw new AppError(
          'GOOGLE_ACCOUNT_CONFLICT',
          'This Google account is already linked to another number',
        );
      }
      const linked = await this.repo.linkGoogle(tx, user.id, google, user.name);
      return this.startSession(tx, linked, input);
    });
  }

  /** Records the device, activates pending invites, and issues a session. */
  private async startSession(tx: SystemTx, user: UserRow, device: DeviceInput): Promise<Session> {
    await this.repo.upsertDevice(tx, {
      id: device.deviceId,
      userId: user.id,
      platform: device.platform,
      appVersion: device.appVersion,
    });
    await this.repo.activateInvitedMemberships(tx, user.id);
    const memberships = await this.repo.activeMemberships(tx, user.id);
    return this.issue(tx, user, memberships, {
      userId: user.id,
      orgId: memberships[0]?.orgId ?? null,
      deviceId: device.deviceId,
    });
  }

  private async requireAccount(userId: string): Promise<AccountRow> {
    const account = await this.db.system((tx) => this.repo.findAccount(tx, { id: userId }));
    if (!account) throw new AppError('UNAUTHENTICATED', 'User no longer exists');
    return account;
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

  async me(auth: AuthContext): Promise<{ user: AccountRow; memberships: Membership[] }> {
    return this.db.system(async (tx) => {
      const user = await this.repo.findAccount(tx, { id: auth.userId });
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
