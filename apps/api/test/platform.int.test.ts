import { withTenant } from '@taxcy/db';
import request from 'supertest';
import { v7 as uuid } from 'uuid';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { Db } from '../src/platform/prisma.service.js';
import { startHarness, type Harness } from './harness.js';

let h: Harness;

beforeAll(async () => {
  h = await startHarness();
});

afterAll(async () => {
  await h.close();
});

describe('platform', () => {
  it('reports all dependencies ready', async () => {
    const res = await request(h.http).get('/v1/health/ready').expect(200);
    expect(res.body).toEqual({ status: 'ok', checks: { postgres: 'ok', redis: 'ok', s3: 'ok' } });
  });

  it('echoes an incoming request id and generates one otherwise', async () => {
    const echoed = await request(h.http).get('/v1/health/live').set('X-Request-Id', 'req-abc-123');
    expect(echoed.headers['x-request-id']).toBe('req-abc-123');
    const generated = await request(h.http).get('/v1/health/live');
    expect(generated.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
  });

  it('renders unknown routes in the standard error envelope', async () => {
    const res = await request(h.http).get('/v1/does-not-exist').expect(404);
    expect(res.body).toMatchObject({ error: { code: 'NOT_FOUND' } });
  });

  it('serves the OpenAPI document built from contracts', async () => {
    const res = await request(h.http).get('/v1/openapi.json').expect(200);
    const body = res.body as { openapi: string; paths: Record<string, Record<string, unknown>> };
    expect(body.openapi).toBe('3.1.0');
    expect(body.paths['/health/live']?.['get']).toBeDefined();
  });
});

describe('row-level security', () => {
  const orgA = uuid();
  const orgB = uuid();

  beforeAll(async () => {
    await h.owner.organization.createMany({
      data: [
        { id: orgA, name: 'Org A', kind: 'fleet' },
        { id: orgB, name: 'Org B', kind: 'fleet' },
      ],
    });
    await h.owner.vehicle.createMany({
      data: [
        {
          id: uuid(),
          orgId: orgA,
          registrationNo: 'MH12AA0001',
          make: 'Toyota',
          model: 'Innova',
          fuelType: 'diesel',
        },
        {
          id: uuid(),
          orgId: orgB,
          registrationNo: 'MH12BB0002',
          make: 'Maruti',
          model: 'Dzire',
          fuelType: 'cng',
        },
      ],
    });
  });

  it('shows the app role only the current org, even without a WHERE clause', async () => {
    const db = h.app.get(Db);
    const seenByA = await withTenant(db.client, orgA, (tx) => tx.vehicle.findMany());
    expect(seenByA.map((v) => v.registrationNo)).toEqual(['MH12AA0001']);
  });

  it('shows nothing when no org is set', async () => {
    const db = h.app.get(Db);
    expect(await db.client.vehicle.findMany()).toEqual([]);
  });

  it('rejects writes into another org', async () => {
    const db = h.app.get(Db);
    await expect(
      withTenant(db.client, orgA, (tx) =>
        tx.vehicle.create({
          data: {
            id: uuid(),
            orgId: orgB,
            registrationNo: 'MH12XX9999',
            make: 'Tata',
            model: 'Nexon',
            fuelType: 'petrol',
          },
        }),
      ),
    ).rejects.toThrow();
  });
});
