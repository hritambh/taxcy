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
  schedule,
  startHarness,
  type Harness,
} from './harness.js';

let h: Harness;
let owner: Session;
let driver: { session: Session; driverId: string };
let vehicleSeq = 0;

async function newTrip(
  assign = true,
  overrides: Record<string, unknown> = {},
): Promise<Trip & { vehicleId: string }> {
  vehicleSeq += 1;
  const vehicle = await createVehicle(h, owner, `MH14TR${String(vehicleSeq).padStart(4, '0')}`);
  const res = await request(h.http)
    .post('/v1/trips')
    .set(...bearer(owner))
    .send({
      tripType: 'one_way',
      customer: { name: 'Anita Desai', phone: '+919822222222' },
      from: { text: 'Pune Station', point: { lat: 18.5286, lng: 73.8743 } },
      to: { text: 'Mumbai Airport T2', point: { lat: 19.0974, lng: 72.8745 } },
      ...schedule(),
      quotedFarePaise: 350_000,
      ...(assign ? { vehicleId: vehicle.id, driverId: driver.driverId } : {}),
      ...overrides,
    })
    .expect(201);
  return { ...(res.body as Trip), vehicleId: vehicle.id };
}

interface Expecting {
  expect(status: number): Promise<request.Response>;
}

/**
 * Builds the request after registering the odometer photo; call .expect(status) on the
 * result. The Test is wrapped in an object because a supertest Test is a thenable:
 * returning it bare from an async function would send it immediately.
 */
function deferred(build: () => Promise<{ test: request.Test }>): Expecting {
  return { expect: async (status) => (await build()).test.expect(status) };
}

function start(trip: Trip, session: Session, km = 48_210, idem = key()): Expecting {
  return deferred(async () => ({
    test: request(h.http)
      .post(`/v1/trips/${trip.id}/start`)
      .set(...bearer(session))
      .set(...idem)
      .send({ odometer: await odometer(h, session, km), occurredAt: new Date().toISOString() }),
  }));
}

function end(
  trip: Trip,
  session: Session,
  km = 48_365,
  extra: Record<string, unknown> = {},
): Expecting {
  return deferred(async () => ({
    test: request(h.http)
      .post(`/v1/trips/${trip.id}/end`)
      .set(...bearer(session))
      .set(...key())
      .send({
        odometer: await odometer(h, session, km),
        occurredAt: new Date().toISOString(),
        ...extra,
      }),
  }));
}

beforeAll(async () => {
  h = await startHarness();
  owner = await ownerSession(h, 'fleet', 'Sharma Travels');
  driver = await driverSession(h, owner, 'Ramesh Kumar');
});

afterAll(async () => {
  await h.close();
});

describe('trip lifecycle', () => {
  it('created → assigned → started → ended, with every transition in trip_events', async () => {
    const trip = await newTrip();
    expect(trip).toMatchObject({
      status: 'assigned',
      customer: { name: 'Anita Desai', phone: '+919822222222' },
      from: { text: 'Pune Station', point: { lat: 18.5286, lng: 73.8743 } },
      driver: { id: driver.driverId, name: 'Ramesh Kumar' },
      allowedCommands: ['reassign', 'unassign', 'start', 'cancel'],
    });

    const started = await start(trip, driver.session).expect(200);
    expect(started.body).toMatchObject({ status: 'started', startOdometer: { typedKm: 48_210 } });

    const ended = await end(trip, driver.session, 48_365, {
      collections: [
        { id: randomUUID(), method: 'cash', amountPaise: 200_000 },
        { id: randomUUID(), method: 'upi', amountPaise: 175_000, reference: 'UPI123' },
      ],
      charges: [{ id: randomUUID(), kind: 'toll', amountPaise: 25_000, paidByDriver: true }],
    }).expect(200);
    expect(ended.body).toMatchObject({
      status: 'ended',
      endOdometer: { typedKm: 48_365 },
      collections: [{ method: 'cash' }, { method: 'upi', reference: 'UPI123' }],
      charges: [{ kind: 'toll', amountPaise: 25_000, paidByDriver: true, enteredRole: 'driver' }],
    });

    const events = await request(h.http)
      .get(`/v1/trips/${trip.id}/events`)
      .set(...bearer(owner))
      .expect(200);
    expect(
      (events.body as { seq: number; eventType: string; actorRole: string }[]).map((e) => [
        e.seq,
        e.eventType,
        e.actorRole,
      ]),
    ).toEqual([
      [1, 'trip.created', 'owner'],
      [2, 'trip.assigned', 'owner'],
      [3, 'trip.started', 'driver'],
      [4, 'trip.ended', 'driver'],
    ]);
    const closed = await h.owner.outboxEvent.findMany({ where: { topic: 'trip.closed' } });
    expect(closed.map((e) => (e.payload as { tripId: string }).tripId)).toContain(trip.id);
  });

  it('rejects illegal transitions and says what is allowed', async () => {
    const trip = await newTrip();
    const res = await end(trip, driver.session).expect(409);
    expect(res.body).toMatchObject({
      error: {
        code: 'ILLEGAL_TRANSITION',
        details: { allowed: ['reassign', 'unassign', 'start', 'cancel'] },
      },
    });
  });

  it('rejects an end reading below the start reading', async () => {
    const trip = await newTrip();
    await start(trip, driver.session, 50_000).expect(200);
    const res = await end(trip, driver.session, 49_990).expect(422);
    expect(res.body).toMatchObject({ error: { code: 'ODOMETER_BEFORE_START' } });
  });

  it('queues a review when a start reading is below the vehicle’s last known odometer', async () => {
    const trip = await newTrip();
    const res = await start(trip, driver.session, 40_000).expect(200);
    const readingId = (res.body as Trip).startOdometer?.id ?? '';
    expect(await h.owner.reviewItem.findMany({ where: { subjectId: readingId } })).toMatchObject([
      { kind: 'odometer_regression' },
    ]);
  });
});

describe('idempotent commands', () => {
  it('replays the stored response for the same key, without a second event', async () => {
    const trip = await newTrip();
    const idem = key();
    const body = {
      odometer: await odometer(h, driver.session, 48_300),
      occurredAt: new Date().toISOString(),
    };
    const first = await request(h.http)
      .post(`/v1/trips/${trip.id}/start`)
      .set(...bearer(driver.session))
      .set(...idem)
      .send(body)
      .expect(200);
    const replay = await request(h.http)
      .post(`/v1/trips/${trip.id}/start`)
      .set(...bearer(driver.session))
      .set(...idem)
      .send(body)
      .expect(200);
    expect(replay.headers['idempotent-replay']).toBe('true');
    expect(replay.body).toEqual(first.body);
    expect(
      await h.owner.tripEvent.count({ where: { tripId: trip.id, eventType: 'trip.started' } }),
    ).toBe(1);
  });

  it('rejects the same key with a different body', async () => {
    const trip = await newTrip();
    const idem = key();
    await start(trip, driver.session, 48_400, idem).expect(200);
    const res = await start(trip, driver.session, 48_999, idem).expect(409);
    expect(res.body).toMatchObject({ error: { code: 'IDEMPOTENCY_CONFLICT' } });
  });

  it('requires a key on commands', async () => {
    const trip = await newTrip();
    const res = await request(h.http)
      .post(`/v1/trips/${trip.id}/start`)
      .set(...bearer(driver.session))
      .send({
        odometer: await odometer(h, driver.session, 1),
        occurredAt: new Date().toISOString(),
      })
      .expect(400);
    expect(res.body).toMatchObject({ error: { code: 'IDEMPOTENCY_KEY_REQUIRED' } });
  });
});

describe('assignment', () => {
  it('refuses to double-book a vehicle', async () => {
    const window = schedule();
    const first = await newTrip(true, window);
    const second = await newTrip(false, window);
    const other = await driverSession(h, owner, 'Imran Shaikh');
    const res = await request(h.http)
      .post(`/v1/trips/${second.id}/assign`)
      .set(...bearer(owner))
      .set(...key())
      .send({ vehicleId: first.vehicleId, driverId: other.driverId })
      .expect(409);
    expect(res.body).toMatchObject({ error: { code: 'VEHICLE_BUSY' } });
  });

  it('refuses to double-book a driver', async () => {
    const window = schedule();
    await newTrip(true, window);
    const second = await newTrip(false, window);
    const res = await request(h.http)
      .post(`/v1/trips/${second.id}/assign`)
      .set(...bearer(owner))
      .set(...key())
      .send({ vehicleId: second.vehicleId, driverId: driver.driverId })
      .expect(409);
    expect(res.body).toMatchObject({ error: { code: 'DRIVER_BUSY' } });
  });
});

describe('offline conflicts (server wins)', () => {
  it('a start that arrives after the owner cancelled is rejected, and the photo is kept as evidence', async () => {
    const trip = await newTrip();
    await request(h.http)
      .post(`/v1/trips/${trip.id}/cancel`)
      .set(...bearer(owner))
      .set(...key())
      .send({ reason: 'Customer cancelled' })
      .expect(200);
    const res = await start(trip, driver.session).expect(409);
    expect(res.body).toMatchObject({
      error: { code: 'TRIP_CANCELLED', details: { reason: 'Customer cancelled' } },
    });
    const orphans = await h.owner.reviewItem.findMany({
      where: { kind: 'orphan_evidence', context: { path: ['tripId'], equals: trip.id } },
    });
    expect(orphans).toHaveLength(1);
  });

  it('a driver acting on a trip reassigned away from them gets TRIP_REASSIGNED', async () => {
    const trip = await newTrip();
    const other = await driverSession(h, owner, 'Suresh Patil');
    await request(h.http)
      .post(`/v1/trips/${trip.id}/assign`)
      .set(...bearer(owner))
      .set(...key())
      .send({ vehicleId: trip.vehicleId, driverId: other.driverId })
      .expect(200);
    const res = await start(trip, driver.session).expect(409);
    expect(res.body).toMatchObject({ error: { code: 'TRIP_REASSIGNED' } });
  });
});

describe('cancelling a started trip needs a reason and approval', () => {
  function requestCancel(trip: Trip): Expecting {
    return deferred(async () => ({
      test: request(h.http)
        .post(`/v1/trips/${trip.id}/cancellation-requests`)
        .set(...bearer(driver.session))
        .set(...key())
        .send({
          id: randomUUID(),
          reason: 'Customer got off at Lonavala',
          endOdometer: await odometer(h, driver.session, 48_280),
          occurredAt: new Date().toISOString(),
        }),
    }));
  }

  it('cannot be cancelled directly', async () => {
    const trip = await newTrip();
    await start(trip, driver.session).expect(200);
    const res = await request(h.http)
      .post(`/v1/trips/${trip.id}/cancel`)
      .set(...bearer(owner))
      .set(...key())
      .send({ reason: 'x' })
      .expect(409);
    expect(res.body).toMatchObject({ error: { code: 'ILLEGAL_TRANSITION' } });
  });

  it('request → alert → approve with a cancellation fare', async () => {
    const trip = await newTrip();
    await start(trip, driver.session).expect(200);
    const requested = (await requestCancel(trip).expect(200)).body as Trip;
    expect(requested).toMatchObject({
      status: 'started',
      cancellationRequest: {
        status: 'pending',
        requestedRole: 'driver',
        endOdometer: { typedKm: 48_280 },
      },
      allowedCommands: ['end', 'approveCancel', 'rejectCancel', 'withdrawCancel'],
    });
    expect(
      await h.owner.alert.findMany({ where: { tripId: trip.id, status: 'open' } }),
    ).toMatchObject([{ kind: 'cancellation_requested' }]);
    await requestCancel(trip).expect(409);

    const requestId = requested.cancellationRequest?.id ?? '';
    const driverTry = await request(h.http)
      .post(`/v1/cancellation-requests/${requestId}/approve`)
      .set(...bearer(driver.session))
      .set(...key())
      .send({})
      .expect(403);
    expect(driverTry.body).toMatchObject({ error: { code: 'FORBIDDEN_ROLE' } });

    const approved = await request(h.http)
      .post(`/v1/cancellation-requests/${requestId}/approve`)
      .set(...bearer(owner))
      .set(...key())
      .send({ cancellationFarePaise: 80_000 })
      .expect(200);
    expect(approved.body).toMatchObject({
      status: 'cancelled',
      cancelReason: 'Customer got off at Lonavala',
      cancellationFarePaise: 80_000,
      endOdometer: { typedKm: 48_280 },
      cancellationRequest: { status: 'approved' },
    });
    expect(await h.owner.alert.count({ where: { tripId: trip.id, status: 'open' } })).toBe(0);
  });

  it('reject keeps the trip running', async () => {
    const trip = await newTrip();
    await start(trip, driver.session).expect(200);
    const requestId =
      ((await requestCancel(trip).expect(200)).body as Trip).cancellationRequest?.id ?? '';
    const rejected = await request(h.http)
      .post(`/v1/cancellation-requests/${requestId}/reject`)
      .set(...bearer(owner))
      .set(...key())
      .send({ note: 'Customer confirmed they want to continue' })
      .expect(200);
    expect(rejected.body).toMatchObject({
      status: 'started',
      cancellationRequest: { status: 'rejected' },
    });
    await end(trip, driver.session).expect(200);
  });
});

describe('visibility and charges', () => {
  it('drivers see only their own trips', async () => {
    const mine = await newTrip();
    const other = await driverSession(h, owner, 'Vikram Rao');
    await request(h.http)
      .get(`/v1/trips/${mine.id}`)
      .set(...bearer(other.session))
      .expect(404);
    await request(h.http)
      .get('/v1/trips')
      .set(...bearer(driver.session))
      .expect(403);
    const my = await request(h.http)
      .get('/v1/me/trips')
      .set(...bearer(driver.session))
      .expect(200);
    expect((my.body as Trip[]).map((t) => t.id)).toContain(mine.id);
    const theirs = await request(h.http)
      .get('/v1/me/trips')
      .set(...bearer(other.session))
      .expect(200);
    expect(theirs.body).toEqual([]);
  });

  it('charges are idempotent on id; only staff can void them', async () => {
    const trip = await newTrip();
    await start(trip, driver.session).expect(200);
    const charge = { id: randomUUID(), kind: 'parking', amountPaise: 5_000, paidByDriver: true };
    await request(h.http)
      .post(`/v1/trips/${trip.id}/charges`)
      .set(...bearer(driver.session))
      .send(charge)
      .expect(201);
    const again = await request(h.http)
      .post(`/v1/trips/${trip.id}/charges`)
      .set(...bearer(driver.session))
      .send(charge)
      .expect(201);
    expect((again.body as Trip).charges).toHaveLength(1);
    await request(h.http)
      .post(`/v1/trips/${trip.id}/charges/${charge.id}/void`)
      .set(...bearer(driver.session))
      .expect(403);
    const voided = await request(h.http)
      .post(`/v1/trips/${trip.id}/charges/${charge.id}/void`)
      .set(...bearer(owner))
      .expect(200);
    expect((voided.body as Trip).charges[0]?.voidedAt).not.toBeNull();
  });
});
