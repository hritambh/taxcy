import type { Session } from '@taxcy/contracts';
import request from 'supertest';
import { randomUUID } from 'node:crypto';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
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

describe('OTP login', () => {
  it('creates the user on first login, with no org yet', async () => {
    const phone = randomPhone();
    const session = await login(h, phone);
    expect(session.user.phone).toBe(phone);
    expect(session.activeOrgId).toBeNull();
    expect(session.memberships).toEqual([]);
  });

  it('rejects a wrong code and counts the attempt', async () => {
    const phone = randomPhone();
    await request(h.http).post('/v1/auth/otp/request').send({ phone }).expect(202);
    const wrong = lastOtp(h, phone) === '000000' ? '111111' : '000000';
    const res = await request(h.http)
      .post('/v1/auth/otp/verify')
      .send({ phone, code: wrong, deviceId: randomUUID(), platform: 'android' })
      .expect(401);
    expect(res.body).toMatchObject({
      error: { code: 'OTP_INVALID', details: { attemptsLeft: 4 } },
    });
  });

  it('a code works only once', async () => {
    const phone = randomPhone();
    await request(h.http).post('/v1/auth/otp/request').send({ phone }).expect(202);
    const body = { phone, code: lastOtp(h, phone), deviceId: randomUUID(), platform: 'android' };
    await request(h.http).post('/v1/auth/otp/verify').send(body).expect(200);
    const again = await request(h.http).post('/v1/auth/otp/verify').send(body).expect(401);
    expect(again.body).toMatchObject({ error: { code: 'OTP_EXPIRED' } });
  });

  it('rate-limits repeated requests for the same phone', async () => {
    const phone = randomPhone();
    await request(h.http).post('/v1/auth/otp/request').send({ phone }).expect(202);
    const res = await request(h.http).post('/v1/auth/otp/request').send({ phone }).expect(429);
    expect(res.body).toMatchObject({
      error: { code: 'RATE_LIMITED', details: { retryAfterSeconds: expect.any(Number) as number } },
    });
  });

  it('validates the phone format', async () => {
    const res = await request(h.http)
      .post('/v1/auth/otp/request')
      .send({ phone: '98123' })
      .expect(400);
    expect(res.body).toMatchObject({ error: { code: 'VALIDATION_FAILED' } });
  });
});

describe('orgs and memberships', () => {
  it('makes the creator the owner of a fleet and scopes the session to it', async () => {
    const session = await ownerSession(h, 'fleet', 'Sharma Travels');
    expect(session.activeOrgId).not.toBeNull();
    expect(session.memberships).toEqual([
      { orgId: session.activeOrgId, orgName: 'Sharma Travels', orgKind: 'fleet', roles: ['owner'] },
    ]);
    const me = await request(h.http)
      .get('/v1/me')
      .set(...bearer(session))
      .expect(200);
    expect(me.body).toMatchObject({ activeOrgId: session.activeOrgId, roles: ['owner'] });
  });

  it('makes a DCO owner also its driver, with a driver profile', async () => {
    const session = await ownerSession(h, 'dco', 'Ravi Cabs');
    expect(session.memberships[0]?.roles).toEqual(['owner', 'driver']);
    const drivers = await h.owner.driver.findMany({ where: { orgId: session.activeOrgId ?? '' } });
    expect(drivers).toHaveLength(1);
  });

  it('switches only into orgs the user belongs to', async () => {
    const a = await ownerSession(h);
    const res = await request(h.http)
      .post('/v1/auth/switch-org')
      .set(...bearer(a))
      .send({ refreshToken: a.refreshToken, orgId: randomUUID() })
      .expect(404);
    expect(res.body).toMatchObject({ error: { code: 'NOT_FOUND' } });
  });

  it('requires a token for user routes', async () => {
    const res = await request(h.http).get('/v1/me').expect(401);
    expect(res.body).toMatchObject({ error: { code: 'UNAUTHENTICATED' } });
  });
});

describe('refresh token rotation', () => {
  it('rotates on every refresh', async () => {
    const session = await login(h);
    const res = await request(h.http)
      .post('/v1/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(200);
    const next = res.body as Session;
    expect(next.refreshToken).not.toBe(session.refreshToken);
    expect(next.user.id).toBe(session.user.id);
  });

  it('treats reuse of a rotated token as theft and revokes the whole family', async () => {
    const session = await login(h);
    const rotated = (
      await request(h.http)
        .post('/v1/auth/refresh')
        .send({ refreshToken: session.refreshToken })
        .expect(200)
    ).body as Session;
    await request(h.http)
      .post('/v1/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(401);
    // The legitimate holder's newer token is now dead too.
    await request(h.http)
      .post('/v1/auth/refresh')
      .send({ refreshToken: rotated.refreshToken })
      .expect(401);
  });

  it('logout revokes the session', async () => {
    const session = await login(h);
    await request(h.http)
      .post('/v1/auth/logout')
      .send({ refreshToken: session.refreshToken })
      .expect(204);
    await request(h.http)
      .post('/v1/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(401);
  });
});
