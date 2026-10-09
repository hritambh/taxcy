import { Inject, Injectable } from '@nestjs/common';
import { MembershipRole } from '@taxcy/contracts';
import { errors, jwtVerify, SignJWT } from 'jose';
import { z } from 'zod';
import { AppError } from '../errors.js';
import { APP_CONFIG, type AppConfig } from '../config.js';
import type { AuthContext } from './auth-context.js';

const AccessClaims = z.object({
  sub: z.string(),
  org: z.string().nullable(),
  roles: z.array(MembershipRole),
});

const ISSUER = 'taxcy-api';

/** Signs and verifies short-lived access tokens (HS256). Refresh tokens are opaque, see identity. */
@Injectable()
export class AccessTokens {
  private readonly key: Uint8Array;

  constructor(@Inject(APP_CONFIG) private readonly config: AppConfig) {
    this.key = new TextEncoder().encode(config.JWT_ACCESS_SECRET);
  }

  async sign(auth: AuthContext): Promise<{ token: string; expiresAt: Date }> {
    const expiresAt = new Date(Date.now() + this.config.JWT_ACCESS_TTL_SECONDS * 1000);
    const token = await new SignJWT({ org: auth.orgId, roles: auth.roles })
      .setProtectedHeader({ alg: 'HS256' })
      .setSubject(auth.userId)
      .setIssuer(ISSUER)
      .setIssuedAt()
      .setExpirationTime(expiresAt)
      .sign(this.key);
    return { token, expiresAt };
  }

  async verify(token: string): Promise<AuthContext> {
    try {
      const { payload } = await jwtVerify(token, this.key, {
        issuer: ISSUER,
        algorithms: ['HS256'],
      });
      const claims = AccessClaims.parse(payload);
      return { userId: claims.sub, orgId: claims.org, roles: claims.roles };
    } catch (error) {
      if (error instanceof errors.JWTExpired) {
        throw new AppError('TOKEN_EXPIRED', 'Access token has expired');
      }
      throw new AppError('UNAUTHENTICATED', 'Invalid access token');
    }
  }
}
