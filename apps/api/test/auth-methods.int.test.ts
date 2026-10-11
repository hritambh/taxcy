import type { GoogleSignInResult, Session } from '@taxcy/contracts';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { RedisService } from '../src/platform/redis.service.js';
import {
  bearer,
  driverSession,
  lastOtp,
  login,
  ownerSession,
  randomPhone,
  startHarness,
  type Harness,
} from './harness.js';

let h: Harness;

beforeAll(async () => {
  h = await startHarness();
});

afterAll(async () => {
  await h.close();
});

const device = () => ({ deviceId: randomUUID(), platform: 'web' });

/** Sends a fresh SMS code (skipping the 30-second resend wait) and returns it. */
async function smsCode(phone: string): Promise<string> {
  await h.app.get(RedisService).client.del(`rl:otp:resend:${phone}`);
  await request(h.http).post('/v1/auth/otp/request').send({ phone }).expect(202);
  return lastOtp(h, phone);
}

async function signup(phone: string, password = 'correct horse 42') {
  return request(h.http)
    .post('/v1/auth/signup')
    .send({ phone, code: await smsCode(phone), password, name: 'Anil Sharma', ...device() });
}

function passwordLogin(phone: string, password: string) {
  return request(h.http)
    .post('/v1/auth/password/login')
    .send({ phone, password, ...device() });
}

describe('sign-in methods', () => {
  it('reports what the login screens can offer', async () => {
    const res = await request(h.http).get('/v1/auth/config').expect(200);
    // No Google client id in tests: the local stand-in is used.
    expect(res.body).toEqual({ password: true, google: { mode: 'dev', webClientId: null } });
  });
});

describe('phone and password', () => {
  it('signs up after an SMS code, then logs in with the password', async () => {
    const phone = randomPhone();
    const created = (await signup(phone)).body as Session;
    expect(created).toMatchObject({ user: { phone, name: 'Anil Sharma' }, activeOrgId: null });

    const session = (await passwordLogin(phone, 'correct horse 42').expect(200)).body as Session;
    expect(session.user.id).toBe(created.user.id);
    const me = await request(h.http)
      .get('/v1/me')
      .set(...bearer(session))
      .expect(200);
    expect(me.body).toMatchObject({ user: { hasPassword: true, googleLinked: false } });
  });

  it('needs a valid SMS code and a long enough password to sign up', async () => {
    const phone = randomPhone();
    await smsCode(phone);
    await request(h.http)
      .post('/v1/auth/signup')
      .send({ phone, code: '000000', password: 'long enough 1', ...device() })
      .expect(401);
    const short = await request(h.http)
      .post('/v1/auth/signup')
      .send({ phone, code: lastOtp(h, phone), password: 'short', ...device() })
      .expect(400);
    expect(short.body).toMatchObject({ error: { code: 'VALIDATION_FAILED' } });
  });

  it('does not let a second sign-up take over an account', async () => {
    const phone = randomPhone();
    await signup(phone);
    const again = await signup(phone, 'someone else 99');
    expect(again.status).toBe(409);
    expect(again.body).toMatchObject({ error: { code: 'ACCOUNT_EXISTS' } });
    await passwordLogin(phone, 'someone else 99').expect(401);
  });

  it('gives the same answer for a wrong password and an unknown number', async () => {
    const phone = randomPhone();
    await signup(phone);
    const wrong = await passwordLogin(phone, 'not the password').expect(401);
    const unknown = await passwordLogin(randomPhone(), 'not the password').expect(401);
    expect(wrong.body).toMatchObject({ error: { code: 'INVALID_CREDENTIALS' } });
    expect((unknown.body as { error: { message: string } }).error.message).toBe(
      (wrong.body as { error: { message: string } }).error.message,
    );
  });

  it('locks out repeated guessing for a number', async () => {
    const phone = randomPhone();
    await signup(phone);
    for (let i = 0; i < 10; i++) await passwordLogin(phone, `guess ${String(i)}xxxx`).expect(401);
    const blocked = await passwordLogin(phone, 'correct horse 42').expect(429);
    expect(blocked.body).toMatchObject({ error: { code: 'RATE_LIMITED' } });
  });

  it('an invited driver who signs up gets their fleet, like an SMS login', async () => {
    const owner = await ownerSession(h, 'fleet', 'Sharma Travels');
    const phone = randomPhone();
    await request(h.http)
      .post('/v1/drivers')
      .set(...bearer(owner))
      .send({ name: 'Ramesh Kumar', phone })
      .expect(201);
    const session = (await signup(phone)).body as Session;
    expect(session.activeOrgId).toBe(owner.activeOrgId);
    expect(session.memberships[0]?.roles).toEqual(['driver']);
  });

  it('resets a forgotten password with an SMS code and signs out other sessions', async () => {
    const phone = randomPhone();
    const old = (await signup(phone)).body as Session;
    const reset = await request(h.http)
      .post('/v1/auth/password/reset')
      .send({ phone, code: await smsCode(phone), password: 'brand new pass 7', ...device() })
      .expect(200);
    expect((reset.body as Session).user.id).toBe(old.user.id);
    await passwordLogin(phone, 'correct horse 42').expect(401);
    await passwordLogin(phone, 'brand new pass 7').expect(200);
    await request(h.http)
      .post('/v1/auth/refresh')
      .send({ refreshToken: old.refreshToken })
      .expect(401);
  });

  it('SMS-only users can add a password; changing one needs the current one', async () => {
    const session = await login(h);
    await request(h.http)
      .post('/v1/me/password')
      .set(...bearer(session))
      .send({ newPassword: 'first password 1' })
      .expect(204);
    const wrong = await request(h.http)
      .post('/v1/me/password')
      .set(...bearer(session))
      .send({ currentPassword: 'nope nope nope', newPassword: 'second password 2' })
      .expect(401);
    expect(wrong.body).toMatchObject({ error: { code: 'INVALID_CREDENTIALS' } });
    await request(h.http)
      .post('/v1/me/password')
      .set(...bearer(session))
      .send({ currentPassword: 'first password 1', newPassword: 'second password 2' })
      .expect(204);
    await passwordLogin(session.user.phone, 'second password 2').expect(200);
  });
});

describe('Google', () => {
  async function google(email: string): Promise<GoogleSignInResult> {
    const res = await request(h.http)
      .post('/v1/auth/google')
      .send({ idToken: `dev-google:${email}`, ...device() })
      .expect(200);
    return res.body as GoogleSignInResult;
  }

  async function link(linkToken: string, phone: string) {
    return request(h.http)
      .post('/v1/auth/google/link')
      .send({ linkToken, phone, code: await smsCode(phone), ...device() });
  }

  it('a first Google sign-in verifies a phone once; after that Google signs straight in', async () => {
    const email = `owner-${randomUUID()}@example.com`;
    const first = await google(email);
    expect(first).toMatchObject({ status: 'phone_required', email });
    if (first.status !== 'phone_required') throw new Error('expected phone_required');

    const phone = randomPhone();
    const session = (await link(first.linkToken, phone)).body as Session;
    expect(session.user.phone).toBe(phone);

    const again = await google(email);
    expect(again).toMatchObject({ status: 'signed_in', session: { user: { phone } } });
    const me = await request(h.http)
      .get('/v1/me')
      .set(...bearer(session))
      .expect(200);
    expect(me.body).toMatchObject({ user: { email, googleLinked: true, hasPassword: false } });
  });

  it('linking to an invited driver phone joins their fleet', async () => {
    const owner = await ownerSession(h, 'fleet', 'Patil Cabs');
    const { session: driver } = await driverSession(h, owner, 'Suresh Patil');
    const first = await google(`suresh-${randomUUID()}@example.com`);
    if (first.status !== 'phone_required') throw new Error('expected phone_required');
    const session = (await link(first.linkToken, driver.user.phone)).body as Session;
    expect(session.user.id).toBe(driver.user.id);
    expect(session.activeOrgId).toBe(owner.activeOrgId);
  });

  it('a mistyped code can be retried; a used or unknown link token cannot', async () => {
    const first = await google(`retry-${randomUUID()}@example.com`);
    if (first.status !== 'phone_required') throw new Error('expected phone_required');
    const phone = randomPhone();
    await smsCode(phone);
    await request(h.http)
      .post('/v1/auth/google/link')
      .send({ linkToken: first.linkToken, phone, code: '000000', ...device() })
      .expect(401);
    await request(h.http)
      .post('/v1/auth/google/link')
      .send({ linkToken: first.linkToken, phone, code: lastOtp(h, phone), ...device() })
      .expect(200);
    const reused = await link(first.linkToken, randomPhone());
    expect(reused.status).toBe(401);
    expect(reused.body).toMatchObject({ error: { code: 'GOOGLE_TOKEN_INVALID' } });
  });

  it('a phone stays linked to one Google account', async () => {
    const phone = randomPhone();
    const a = await google(`a-${randomUUID()}@example.com`);
    if (a.status !== 'phone_required') throw new Error('expected phone_required');
    expect((await link(a.linkToken, phone)).status).toBe(200);
    const b = await google(`b-${randomUUID()}@example.com`);
    if (b.status !== 'phone_required') throw new Error('expected phone_required');
    const conflict = await link(b.linkToken, phone);
    expect(conflict.status).toBe(409);
    expect(conflict.body).toMatchObject({ error: { code: 'GOOGLE_ACCOUNT_CONFLICT' } });
  });

  it('rejects a token that does not verify', async () => {
    const res = await request(h.http)
      .post('/v1/auth/google')
      .send({ idToken: 'not-a-google-token', ...device() })
      .expect(401);
    expect(res.body).toMatchObject({ error: { code: 'GOOGLE_TOKEN_INVALID' } });
  });
});
