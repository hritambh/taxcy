import { describe, expect, it } from 'vitest';
import type { AppConfig } from '../../platform/config.js';
import {
  DevGoogleVerifier,
  DisabledGoogleVerifier,
  GoogleTokenVerifier,
  googleVerifierFor,
} from './google.verifier.js';

const config = (overrides: Partial<AppConfig>) =>
  ({
    NODE_ENV: 'development',
    GOOGLE_WEB_CLIENT_ID: '',
    GOOGLE_EXTRA_CLIENT_IDS: [],
    ...overrides,
  }) as AppConfig;

describe('googleVerifierFor', () => {
  it('verifies against Google once a web client id is configured', () => {
    expect(
      googleVerifierFor(config({ GOOGLE_WEB_CLIENT_ID: 'web.apps.googleusercontent.com' })),
    ).toBeInstanceOf(GoogleTokenVerifier);
  });

  it('uses the stand-in in development, and switches Google off in production', () => {
    expect(googleVerifierFor(config({}))).toBeInstanceOf(DevGoogleVerifier);
    expect(googleVerifierFor(config({ NODE_ENV: 'production' }))).toBeInstanceOf(
      DisabledGoogleVerifier,
    );
  });
});

describe('DevGoogleVerifier', () => {
  it('maps the same email to the same account and rejects anything else', async () => {
    const dev = new DevGoogleVerifier();
    const a = await dev.verify('dev-google:Priya@Example.com');
    expect(a).toEqual({
      sub: (await dev.verify('dev-google:priya@example.com')).sub,
      email: 'priya@example.com',
      name: 'priya',
    });
    await expect(dev.verify('eyJhbGciOi.real.token')).rejects.toMatchObject({
      code: 'GOOGLE_TOKEN_INVALID',
    });
  });
});
