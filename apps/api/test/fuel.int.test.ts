import type { FuelFill, Session } from '@taxcy/contracts';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
  createVehicle,
  driverSession,
  odometer,
  ownerSession,
  registerPhoto,
  runJobs,
  startHarness,
  type Harness,
} from './harness.js';

let h: Harness;
let owner: Session;
let driver: { session: Session; driverId: string };
let seq = 0;

const day = (n: number) => new Date(Date.UTC(2026, 8, 1) + n * 86_400_000).toISOString();

async function fill(
  session: Session,
  vehicleId: string,
  odoKm: number,
  quantity: number,
  isFullTank: boolean,
  options: { fuel?: string; rupees?: number; at?: string; id?: string } = {},
): Promise<FuelFill> {
  const res = await request(h.http)
    .post('/v1/fuel-fills')
    .set(...bearer(session))
    .send({
      id: options.id ?? randomUUID(),
      vehicleId,
      fuel: options.fuel ?? 'diesel',
      quantityMilli: Math.round(quantity * 1000),
      costPaise: Math.round((options.rupees ?? quantity * 90) * 100),
      odometer: await odometer(h, session, odoKm),
      isFullTank,
      receiptMediaId: await registerPhoto(h, session, 'fuel_receipt'),
      paidBy: 'driver_cash',
      filledAt: options.at ?? day(++seq),
    })
    .expect(201);
  return res.body as FuelFill;
}

interface Audit {
  track: string;
  unitLabel: string;
  baseline: { mean: number; cycles: number } | null;
  cycles: {
    closingFillId: string;
    verdict: string;
    metricValue: number | null;
    distanceKm: number;
  }[];
}

async function audit(vehicleId: string): Promise<Audit> {
  await runJobs(h);
  return (
    await request(h.http)
      .get(`/v1/vehicles/${vehicleId}/fuel-cycles`)
      .set(...bearer(owner))
      .expect(200)
  ).body as Audit;
}

/** A healthy history: full tank every ~480 km at ~12 km/L. */
async function healthyHistory(vehicleId: string, cycles: number, startKm = 10_000) {
  let km = startKm;
  await fill(driver.session, vehicleId, km, 40, true);
  for (let i = 0; i < cycles; i++) {
    km += 480;
    await fill(driver.session, vehicleId, km, 40 + (i % 2), true);
  }
  return km;
}

beforeAll(async () => {
  h = await startHarness();
  owner = await ownerSession(h);
  driver = await driverSession(h, owner, 'Ramesh K.');
});

afterAll(async () => {
  await h.close();
});

describe('recording fills', () => {
  it('rejects a fuel the vehicle cannot take', async () => {
    const v = await createVehicle(h, owner, 'MH12FU0001', 'cng');
    const res = await request(h.http)
      .post('/v1/fuel-fills')
      .set(...bearer(driver.session))
      .send({
        id: randomUUID(),
        vehicleId: v.id,
        fuel: 'diesel',
        quantityMilli: 1000,
        costPaise: 9000,
        odometer: await odometer(h, driver.session, 100),
        isFullTank: true,
        paidBy: 'owner',
        filledAt: day(1),
      })
      .expect(422);
    expect(res.body).toMatchObject({ error: { code: 'FUEL_TYPE_MISMATCH' } });
  });

  it('is idempotent on the client id and records drivers as themselves', async () => {
    const v = await createVehicle(h, owner, 'MH12FU0002');
    const id = randomUUID();
    const first = await fill(driver.session, v.id, 1_000, 30, true, { id });
    expect(first).toMatchObject({
      driverId: driver.driverId,
      driverName: 'Ramesh K.',
      unit: 'L',
      odometer: { typedKm: 1_000 },
    });
    const replay = await fill(driver.session, v.id, 1_000, 30, true, { id });
    expect(replay.id).toBe(id);
    expect(await h.owner.fuelFill.count({ where: { id } })).toBe(1);
  });
});

describe('vehicle audit', () => {
  it('builds cycles and a baseline from a healthy history', async () => {
    const v = await createVehicle(h, owner, 'MH12FU0010');
    await healthyHistory(v.id, 5);
    const a = await audit(v.id);
    expect(a).toMatchObject({ track: 'diesel', unitLabel: 'km/L', baseline: { cycles: 5 } });
    expect(a.cycles.map((c) => c.verdict)).toEqual(['ok', 'ok', 'ok', 'ok', 'ok']);
    expect(a.baseline?.mean).toBeGreaterThan(11.6);
  });

  it('flags a theft-like cycle with an explanation the owner can read', async () => {
    const v = await createVehicle(h, owner, 'MH12FU0011');
    const km = await healthyHistory(v.id, 5);
    const bad = await fill(driver.session, v.id, km + 480, 60, true);
    const a = await audit(v.id);
    expect(a.cycles.at(-1)).toMatchObject({ closingFillId: bad.id, verdict: 'flagged' });
    const alerts = await h.owner.alert.findMany({ where: { vehicleId: v.id, status: 'open' } });
    expect(alerts).toHaveLength(1);
    expect(alerts[0]).toMatchObject({ kind: 'fuel_efficiency_low', severity: 'critical' });
    expect(alerts[0]?.title).toBe('MH12FU0011 (Innova Crysta, diesel) used more fuel than usual');
    expect(alerts[0]?.explanation).toContain('logged by Ramesh K.');
  });

  it('recomputes when a late fill arrives out of order, superseding the old cycle rows', async () => {
    const v = await createVehicle(h, owner, 'MH12FU0012');
    await fill(driver.session, v.id, 20_000, 40, true, { at: day(100) });
    await fill(driver.session, v.id, 20_960, 80, true, { at: day(110) });
    expect((await audit(v.id)).cycles.map((c) => c.distanceKm)).toEqual([960]);

    // A full fill from the middle syncs late from an offline phone.
    await fill(driver.session, v.id, 20_480, 40, true, { at: day(105) });
    const a = await audit(v.id);
    expect(a.cycles.map((c) => c.distanceKm)).toEqual([480, 480]);
    expect(
      await h.owner.fuelCycle.count({ where: { vehicleId: v.id, supersededAt: { not: null } } }),
    ).toBeGreaterThan(0);
  });

  it('voiding the fill behind a flagged cycle resolves its alert', async () => {
    const v = await createVehicle(h, owner, 'MH12FU0013');
    const km = await healthyHistory(v.id, 4);
    const bad = await fill(driver.session, v.id, km + 480, 60, true);
    await audit(v.id);
    expect(await h.owner.alert.count({ where: { vehicleId: v.id, status: 'open' } })).toBe(1);
    await request(h.http)
      .post(`/v1/fuel-fills/${bad.id}/void`)
      .set(...bearer(owner))
      .send({ reason: 'Typed 60 instead of 40' })
      .expect(200);
    await audit(v.id);
    expect(await h.owner.alert.count({ where: { vehicleId: v.id, status: 'open' } })).toBe(0);
  });

  it('sends an odometer that went backwards to the review queue, not the alerts inbox', async () => {
    const v = await createVehicle(h, owner, 'MH12FU0014');
    await fill(driver.session, v.id, 30_000, 40, true);
    const back = await fill(driver.session, v.id, 29_500, 40, true);
    const a = await audit(v.id);
    expect(a.cycles[0]?.verdict).toBe('invalid');
    expect(await h.owner.reviewItem.findMany({ where: { subjectId: back.id } })).toMatchObject([
      { kind: 'odometer_regression', subjectType: 'fuel_cycle' },
    ]);
    expect(await h.owner.alert.count({ where: { vehicleId: v.id } })).toBe(0);
  });

  it('audits a petrol + CNG car on cost per km', async () => {
    const v = await createVehicle(h, owner, 'MH12FU0015', 'petrol_cng');
    await fill(driver.session, v.id, 50_000, 9, true, { fuel: 'cng', rupees: 800 });
    await fill(driver.session, v.id, 50_180, 10, false, { fuel: 'petrol', rupees: 1_000 });
    await fill(driver.session, v.id, 50_400, 9.5, true, { fuel: 'cng', rupees: 850 });
    const a = await audit(v.id);
    expect(a).toMatchObject({ track: 'bifuel_cost', unitLabel: '₹/km' });
    expect(a.cycles[0]?.metricValue).toBe(462.5);
  });
});
