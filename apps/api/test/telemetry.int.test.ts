import type { Session, Trip } from '@taxcy/contracts';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
  createVehicle,
  driverSession,
  key,
  odometer,
  ownerSession,
  runJobs,
  schedule,
  startHarness,
  type Harness,
} from './harness.js';

let h: Harness;
let owner: Session;
let driver: { session: Session; driverId: string };
let n = 0;

const START = Date.UTC(2026, 9, 9, 3, 0, 0); // 08:30 IST

/** A drive heading north at ~60 km/h: one point every 30 s (0.5 km apart). */
function drive(
  minutes: number,
  options: { from?: number; skip?: (i: number) => boolean; mockEvery?: number } = {},
) {
  const count = minutes * 2;
  const points = [];
  for (let i = 0; i <= count; i++) {
    if (options.skip?.(i)) continue;
    points.push({
      id: randomUUID(),
      recordedAt: new Date((options.from ?? START) + i * 30_000).toISOString(),
      lat: 18.5204 + (i * 0.5) / 111.2,
      lng: 73.8567,
      accuracyM: 8,
      ...(options.mockEvery && i % options.mockEvery === 0 ? { isMock: true } : {}),
    });
  }
  return points;
}

async function startedTrip(startKm = 48_000): Promise<Trip> {
  n += 1;
  const vehicle = await createVehicle(
    h,
    owner,
    `MH12GP${String(n).padStart(4, '0')}`,
    'diesel',
    10_000,
  );
  const created = await request(h.http)
    .post('/v1/trips')
    .set(...bearer(owner))
    .send({
      tripType: 'one_way',
      from: { text: 'Pune' },
      to: { text: 'Lonavala' },
      ...schedule(),
      quotedFarePaise: 250_000,
      vehicleId: vehicle.id,
      driverId: driver.driverId,
    })
    .expect(201);
  const trip = created.body as Trip;
  await request(h.http)
    .post(`/v1/trips/${trip.id}/start`)
    .set(...bearer(driver.session))
    .set(...key())
    .send({
      odometer: await odometer(h, driver.session, startKm),
      occurredAt: new Date(START).toISOString(),
    })
    .expect(200);
  return trip;
}

function upload(trip: Trip, points: unknown[], session = driver.session) {
  return request(h.http)
    .post(`/v1/trips/${trip.id}/gps-batches`)
    .set(...bearer(session))
    .send({ points });
}

async function endTrip(trip: Trip, endKm: number, minutes: number) {
  await request(h.http)
    .post(`/v1/trips/${trip.id}/end`)
    .set(...bearer(driver.session))
    .set(...key())
    .send({
      odometer: await odometer(h, driver.session, endKm),
      occurredAt: new Date(START + minutes * 60_000).toISOString(),
    })
    .expect(200);
  await runJobs(h);
  return (
    await request(h.http)
      .get(`/v1/trips/${trip.id}/distance-check`)
      .set(...bearer(owner))
      .expect(200)
  ).body as {
    result: string;
    gpsKm: number;
    coverageRatio: number;
    odometerKm: number;
  };
}

beforeAll(async () => {
  h = await startHarness();
  owner = await ownerSession(h);
  driver = await driverSession(h, owner);
});

afterAll(async () => {
  await h.close();
});

describe('GPS ingest', () => {
  it('stores a batch, ignores re-sent points and points outside the trip window', async () => {
    const trip = await startedTrip();
    const points = drive(10);
    const tooEarly = { ...drive(0, { from: START - 3_600_000 })[0], id: randomUUID() };
    const first = await upload(trip, [...points, tooEarly]).expect(200);
    expect(first.body).toEqual({ accepted: points.length, duplicates: 0, outOfWindow: 1 });
    const again = await upload(trip, points).expect(200);
    expect(again.body).toEqual({ accepted: 0, duplicates: points.length, outOfWindow: 0 });
  });

  it('only the trip’s driver can upload', async () => {
    const trip = await startedTrip();
    const other = await driverSession(h, owner, 'Someone Else');
    await upload(trip, drive(1), other.session).expect(404);
  });
});

describe('odometer vs GPS', () => {
  it('ok when the odometer matches the GPS route', async () => {
    const trip = await startedTrip(48_000);
    await upload(trip, drive(120)).expect(200);
    const check = await endTrip(trip, 48_121, 120);
    expect(check).toMatchObject({ result: 'ok', odometerKm: 121 });
    expect(check.gpsKm).toBeGreaterThan(119);
    expect(check.gpsKm).toBeLessThan(121);
    expect(check.coverageRatio).toBeGreaterThan(0.99);
  });

  it('flags an odometer well above the GPS distance and explains it', async () => {
    const trip = await startedTrip(48_000);
    await upload(trip, drive(120)).expect(200);
    const check = await endTrip(trip, 48_150, 120);
    expect(check.result).toBe('flagged');
    const alerts = await h.owner.alert.findMany({
      where: { tripId: trip.id, kind: 'odo_gps_mismatch' },
    });
    expect(alerts).toHaveLength(1);
    expect(alerts[0]?.severity).toBe('critical');
    // The synthetic track is ~119.5 km on the spheroid.
    expect(alerts[0]?.explanation).toMatch(
      /^The odometer readings say 150 km, but the phone's GPS recorded 1(19|20) km\./,
    );
  });

  it('is inconclusive when the phone stopped recording, rather than accusing the driver', async () => {
    const trip = await startedTrip(48_000);
    await upload(trip, drive(120, { skip: (i) => i > 40 && i < 200 })).expect(200);
    const check = await endTrip(trip, 48_150, 120);
    expect(check.result).toBe('inconclusive');
    expect(await h.owner.alert.count({ where: { tripId: trip.id } })).toBe(0);
  });

  it('re-checks when late points arrive after the trip ended', async () => {
    const trip = await startedTrip(48_000);
    await upload(trip, drive(120).slice(0, 60)).expect(200);
    expect((await endTrip(trip, 48_121, 120)).result).toBe('inconclusive');
    await upload(trip, drive(120)).expect(200); // the rest syncs later
    await runJobs(h);
    const check = (
      await request(h.http)
        .get(`/v1/trips/${trip.id}/distance-check`)
        .set(...bearer(owner))
    ).body as { result: string };
    expect(check.result).toBe('ok');
  });

  it('drops mock locations and queues a review', async () => {
    const trip = await startedTrip();
    await upload(trip, drive(120, { mockEvery: 10 })).expect(200);
    await endTrip(trip, 48_121, 120);
    expect(await h.owner.reviewItem.findMany({ where: { subjectId: trip.id } })).toMatchObject([
      { kind: 'mock_location' },
    ]);
    const route = await request(h.http)
      .get(`/v1/trips/${trip.id}/route`)
      .set(...bearer(owner))
      .expect(200);
    expect((route.body as { dropped: { mock: number } }).dropped.mock).toBe(25);
  });
});

describe('partitions', () => {
  it('creates monthly partitions and moves rows that landed in the default partition', async () => {
    const trip = await startedTrip();
    const future = Date.UTC(2031, 4, 10);
    await h.owner.$executeRaw`
      INSERT INTO gps_points (org_id, trip_id, driver_id, client_point_id, recorded_at, location)
      VALUES (${owner.activeOrgId}::uuid, ${trip.id}::uuid, ${driver.driverId}::uuid, ${randomUUID()}::uuid,
              ${new Date(future)}, ST_SetSRID(ST_MakePoint(73.85, 18.52), 4326)::geography)`;
    const inDefault = async () =>
      (
        await h.owner.$queryRaw<
          { n: bigint }[]
        >`SELECT count(*) AS n FROM gps_points_default WHERE recorded_at >= '2031-05-01'`
      )[0]?.n;
    expect(await inDefault()).toBe(1n);
    await h.owner.$queryRaw`SELECT ensure_gps_partition('2031-05-01'::date)`;
    expect(await inDefault()).toBe(0n);
    const inPartition = await h.owner.$queryRaw<
      { n: bigint }[]
    >`SELECT count(*) AS n FROM gps_points_2031_05`;
    expect(inPartition[0]?.n).toBe(1n);
  });
});
