import { createHash } from 'node:crypto';
import { OAuth2Client } from 'google-auth-library';
import type { AppConfig } from '../../platform/config.js';
import { AppError } from '../../platform/errors.js';

export interface GoogleIdentity {
  /** Google's stable account id. */
  sub: string;
  email: string | null;
  name: string | null;
}

/** Verifies a Google ID token from the web or the app. */
export interface GoogleVerifier {
  readonly mode: 'google' | 'dev' | 'off';
  verify(idToken: string): Promise<GoogleIdentity>;
}

export const GOOGLE_VERIFIER = Symbol('GOOGLE_VERIFIER');

const invalid = () =>
  new AppError('GOOGLE_TOKEN_INVALID', 'Google sign-in could not be verified; try again');

/** Real verification: Google's signature, expiry, and our client ids as the audience. */
export class GoogleTokenVerifier implements GoogleVerifier {
  readonly mode = 'google';
  private readonly client = new OAuth2Client();

  constructor(private readonly audiences: string[]) {}

  async verify(idToken: string): Promise<GoogleIdentity> {
    try {
      const ticket = await this.client.verifyIdToken({ idToken, audience: this.audiences });
      const payload = ticket.getPayload();
      if (!payload?.sub) throw invalid();
      return {
        sub: payload.sub,
        email: payload.email && payload.email_verified ? payload.email.toLowerCase() : null,
        name: payload.name ?? null,
      };
    } catch {
      throw invalid();
    }
  }
}

/**
 * Local stand-in until Google client ids are configured: accepts "dev-google:<email>"
 * and derives a stable account id from the email. Never used in production.
 */
export class DevGoogleVerifier implements GoogleVerifier {
  readonly mode = 'dev';

  verify(idToken: string): Promise<GoogleIdentity> {
    const match = /^dev-google:([^\s@]+@[^\s@]+)$/.exec(idToken.trim());
    const email = match?.[1]?.toLowerCase();
    if (!email) return Promise.reject(invalid());
    return Promise.resolve({
      sub: `dev-${createHash('sha256').update(email).digest('hex').slice(0, 24)}`,
      email,
      name: email.split('@')[0] ?? null,
    });
  }
}

export class DisabledGoogleVerifier implements GoogleVerifier {
  readonly mode = 'off';

  verify(): Promise<GoogleIdentity> {
    return Promise.reject(
      new AppError('GOOGLE_TOKEN_INVALID', 'Google sign-in is not set up on this server'),
    );
  }
}

export function googleVerifierFor(config: AppConfig): GoogleVerifier {
  if (config.GOOGLE_WEB_CLIENT_ID) {
    return new GoogleTokenVerifier([
      config.GOOGLE_WEB_CLIENT_ID,
      ...config.GOOGLE_EXTRA_CLIENT_IDS,
    ]);
  }
  return config.NODE_ENV === 'production' ? new DisabledGoogleVerifier() : new DevGoogleVerifier();
}
