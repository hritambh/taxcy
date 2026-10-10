import type { Member, Session } from '@taxcy/contracts';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
  driverSession,
  login,
  ownerSession,
  randomPhone,
  startHarness,
  type Harness,
} from './harness.js';

let h: Harness;
let owner: Session;

beforeAll(async () => {
  h = await startHarness();
  owner = await ownerSession(h, 'fleet', 'Sharma Travels');
});

afterAll(async () => {
  await h.close();
});

function invite(phone: string, name = 'Priya Manager') {
  return request(h.http)
    .post('/v1/members/managers')
    .set(...bearer(owner))
    .send({ name, phone });
}

describe('managers', () => {
  it('an invited manager signs in to a manager session and can run the fleet, but not settings', async () => {
    const phone = randomPhone();
    const invited = (await invite(phone).expect(201)).body as Member;
    expect(invited).toMatchObject({ name: 'Priya Manager', roles: ['manager'], status: 'invited' });

    const manager = await login(h, phone);
    expect(manager.activeOrgId).toBe(owner.activeOrgId);
    expect(manager.memberships[0]?.roles).toEqual(['manager']);

    await request(h.http)
      .post('/v1/vehicles')
      .set(...bearer(manager))
      .send({ registrationNo: 'MH12MG0001', make: 'Maruti', model: 'Dzire', fuelType: 'cng' })
      .expect(201);
    await request(h.http)
      .patch('/v1/settings/audit')
      .set(...bearer(manager))
      .send({ fuelKSigma: 3 })
      .expect(403);
    // Only the owner manages who else can manage.
    await request(h.http)
      .post('/v1/members/managers')
      .set(...bearer(manager))
      .send({ name: 'X', phone: randomPhone() })
      .expect(403);

    const members = (
      await request(h.http)
        .get('/v1/members')
        .set(...bearer(manager))
        .expect(200)
    ).body as Member[];
    expect(members.map((m) => [m.roles, m.status])).toEqual([
      [['owner'], 'active'],
      [['manager'], 'active'],
    ]);
  });

  it('rejects inviting someone who can already manage', async () => {
    const phone = randomPhone();
    await invite(phone).expect(201);
    const again = await invite(phone).expect(409);
    expect(again.body).toMatchObject({ error: { code: 'CONFLICT' } });
    await invite(owner.user.phone).expect(409);
  });

  it('a driver can also be made a manager, and removing it leaves them a driver', async () => {
    const { session } = await driverSession(h, owner, 'Imran Shaikh');
    const member = (await invite(session.user.phone, 'Imran Shaikh').expect(201)).body as Member;
    expect(member.roles).toEqual(['driver', 'manager']);

    const removed = await request(h.http)
      .delete(`/v1/members/${member.id}/manager`)
      .set(...bearer(owner))
      .expect(200);
    expect(removed.body).toMatchObject({ roles: ['driver'], status: 'active' });
    await request(h.http)
      .delete(`/v1/members/${member.id}/manager`)
      .set(...bearer(owner))
      .expect(409);
  });

  it('removing the only role suspends the member, so their next refresh drops the org', async () => {
    const phone = randomPhone();
    const member = (await invite(phone).expect(201)).body as Member;
    const manager = await login(h, phone);
    const removed = await request(h.http)
      .delete(`/v1/members/${member.id}/manager`)
      .set(...bearer(owner))
      .expect(200);
    expect(removed.body).toMatchObject({ roles: ['manager'], status: 'suspended' });

    const refreshed = (
      await request(h.http)
        .post('/v1/auth/refresh')
        .send({ refreshToken: manager.refreshToken })
        .expect(200)
    ).body as Session;
    expect(refreshed.activeOrgId).toBeNull();
    expect(refreshed.memberships).toEqual([]);

    // Inviting them again restores manager access.
    expect((await invite(phone).expect(201)).body).toMatchObject({
      roles: ['manager'],
      status: 'invited',
    });
  });

  it('is scoped to the org', async () => {
    const other = await ownerSession(h, 'fleet', 'Other Fleet');
    const mine = (await invite(randomPhone()).expect(201)).body as Member;
    await request(h.http)
      .delete(`/v1/members/${mine.id}/manager`)
      .set(...bearer(other))
      .expect(404);
  });
});
