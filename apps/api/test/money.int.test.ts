import type { Session, Trip } from '@taxcy/contracts';
import { istBusinessDate } from '@taxcy/domain';
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
  registerPhoto,
  runJobs,
  schedule,
  startHarness,
  type Harness,
} from './harness.js';

let h: Harness;
let owner: Session;
let n = 0;

const today = () => istBusinessDate(new Date());
const tomorrow = () => istBusinessDate(new Date(Date.now() + 86_400_000));
const rupees = (r: number) => r * 100;

interface Detail {
  status: string;
  netPayablePaise: number;
  expectedFarePaise: number;
  cashPaise: number;
  onlinePaise: number;
  driverExpensesPaise: number;
  driverEarningsPaise: number;
  carriedAdjustmentPaise: number;
  shortfallPaise: number;
  tripCount: number;
  lines: { refType: string; refId: string; amountPaise: number; description: string }[];
}

async function runTrip(
  driver: { session: Session; driverId: string },
  fareRupees: number,
  end: { collections?: unknown[]; charges?: unknown[] } = {},
): Promise<Trip> {
  n += 1;
  const vehicle = await createVehicle(
    h,
    owner,
    `MH12MN${String(n).padStart(4, '0')}`,
    'diesel',
    10_000,
  );
  const created = (
    await request(h.http)
      .post('/v1/trips')
      .set(...bearer(owner))
      .send({
        tripType: 'one_way',
        from: { text: 'Pune' },
        to: { text: 'Mumbai' },
        ...schedule(),
        quotedFarePaise: rupees(fareRupees),
        vehicleId: vehicle.id,
        driverId: driver.driverId,
      })
      .expect(201)
  ).body as Trip;
  await request(h.http)
    .post(`/v1/trips/${created.id}/start`)
    .set(...bearer(driver.session))
    .set(...key())
    .send({
      odometer: await odometer(h, driver.session, 20_000),
      occurredAt: new Date().toISOString(),
    })
    .expect(200);
  const ended = await request(h.http)
    .post(`/v1/trips/${created.id}/end`)
    .set(...bearer(driver.session))
    .set(...key())
    .send({
      odometer: await odometer(h, driver.session, 20_155),
      occurredAt: new Date().toISOString(),
      ...end,
    })
    .expect(200);
  return ended.body as Trip;
}

const cash = (r: number) => ({ id: randomUUID(), method: 'cash', amountPaise: rupees(r) });
const upi = (r: number) => ({ id: randomUUID(), method: 'upi', amountPaise: rupees(r) });

async function settlement(driverId: string, date = today()): Promise<Detail> {
  return (
    await request(h.http)
      .get(`/v1/settlements/${date}/drivers/${driverId}`)
      .set(...bearer(owner))
      .expect(200)
  ).body as Detail;
}

beforeAll(async () => {
  h = await startHarness();
  owner = await ownerSession(h);
});

afterAll(async () => {
  await h.close();
});

describe('daily settlement', () => {
  it('worked example: 20% of quoted fare, Ramesh hands over ₹1,290; settling freezes the day', async () => {
    const ramesh = await driverSession(h, owner, 'Ramesh Kumar');
    await request(h.http)
      .put(`/v1/drivers/${ramesh.driverId}/pay-rule`)
      .set(...bearer(owner))
      .send({
        payRule: { kind: 'percent_of_fare', percent: 20, base: 'quoted', allowanceToDriver: true },
      })
      .expect(200);
    const tripA = await runTrip(ramesh, 3_500, {
      collections: [cash(2_000), upi(1_750)],
      charges: [{ id: randomUUID(), kind: 'toll', amountPaise: rupees(250), paidByDriver: true }],
    });
    await runTrip(ramesh, 1_800, { collections: [cash(1_800)] });
    const vehicleId = tripA.vehicle?.id ?? '';
    await request(h.http)
      .post('/v1/fuel-fills')
      .set(...bearer(ramesh.session))
      .send({
        id: randomUUID(),
        vehicleId,
        fuel: 'diesel',
        quantityMilli: 13_300,
        costPaise: rupees(1_200),
        odometer: await odometer(h, ramesh.session, 20_160),
        isFullTank: false,
        paidBy: 'driver_cash',
        filledAt: new Date().toISOString(),
      })
      .expect(201);

    const draft = await settlement(ramesh.driverId);
    expect(draft).toMatchObject({
      status: 'draft',
      expectedFarePaise: rupees(5_550),
      cashPaise: rupees(3_800),
      onlinePaise: rupees(1_750),
      driverExpensesPaise: rupees(1_450),
      driverEarningsPaise: rupees(1_060),
      netPayablePaise: rupees(1_290),
      shortfallPaise: 0,
      tripCount: 2,
    });
    expect(draft.lines).toHaveLength(7);

    const list = await request(h.http)
      .get(`/v1/settlements?date=${today()}`)
      .set(...bearer(owner))
      .expect(200);
    expect(list.body).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ driverName: 'Ramesh Kumar', netPayablePaise: rupees(1_290) }),
      ]),
    );

    const settled = await request(h.http)
      .post(`/v1/settlements/${today()}/drivers/${ramesh.driverId}/settle`)
      .set(...bearer(owner))
      .set(...key())
      .expect(200);
    expect(settled.body).toMatchObject({ status: 'settled', netPayablePaise: rupees(1_290) });
    const tripNow = await request(h.http)
      .get(`/v1/trips/${tripA.id}`)
      .set(...bearer(owner))
      .expect(200);
    expect((tripNow.body as Trip).status).toBe('settled');

    // Charges can no longer be voided, and fuel fills on the day can't be voided either.
    const chargeId = tripA.charges[0]?.id ?? '';
    await request(h.http)
      .post(`/v1/trips/${tripA.id}/charges/${chargeId}/void`)
      .set(...bearer(owner))
      .expect(409);
  });

  it('a payment that syncs after the day was settled carries into the next day', async () => {
    const driver = await driverSession(h, owner, 'Suresh Patil');
    const trip = await runTrip(driver, 2_000, { collections: [cash(1_500)] });
    await request(h.http)
      .post(`/v1/settlements/${today()}/drivers/${driver.driverId}/settle`)
      .set(...bearer(owner))
      .set(...key())
      .expect(200);

    // The remaining ₹500 cash was logged offline and syncs late.
    await request(h.http)
      .post(`/v1/trips/${trip.id}/collections`)
      .set(...bearer(driver.session))
      .send(cash(500))
      .expect(201);

    const settledDay = await settlement(driver.driverId);
    expect(settledDay).toMatchObject({ status: 'settled', cashPaise: rupees(1_500) });
    const next = await settlement(driver.driverId, tomorrow());
    expect(next).toMatchObject({
      status: 'draft',
      carriedAdjustmentPaise: rupees(500),
      netPayablePaise: rupees(500),
      tripCount: 0,
    });
    expect(next.lines).toMatchObject([{ refType: 'adjustment', amountPaise: rupees(500) }]);
  });

  it('an approved cancellation of a started trip counts its cancellation fare', async () => {
    const driver = await driverSession(h, owner, 'Imran Shaikh');
    n += 1;
    const vehicle = await createVehicle(
      h,
      owner,
      `MH12MN${String(n).padStart(4, '0')}`,
      'diesel',
      10_000,
    );
    const trip = (
      await request(h.http)
        .post('/v1/trips')
        .set(...bearer(owner))
        .send({
          tripType: 'one_way',
          from: { text: 'Pune' },
          to: { text: 'Nashik' },
          ...schedule(),
          quotedFarePaise: rupees(4_000),
          vehicleId: vehicle.id,
          driverId: driver.driverId,
        })
        .expect(201)
    ).body as Trip;
    await request(h.http)
      .post(`/v1/trips/${trip.id}/start`)
      .set(...bearer(driver.session))
      .set(...key())
      .send({
        odometer: await odometer(h, driver.session, 30_000),
        occurredAt: new Date().toISOString(),
      })
      .expect(200);
    const requested = (
      await request(h.http)
        .post(`/v1/trips/${trip.id}/cancellation-requests`)
        .set(...bearer(driver.session))
        .set(...key())
        .send({
          id: randomUUID(),
          reason: 'Customer changed plans',
          endOdometer: await odometer(h, driver.session, 30_040),
          occurredAt: new Date().toISOString(),
        })
        .expect(200)
    ).body as Trip;
    await request(h.http)
      .post(`/v1/cancellation-requests/${requested.cancellationRequest?.id ?? ''}/approve`)
      .set(...bearer(owner))
      .set(...key())
      .send({ cancellationFarePaise: rupees(800) })
      .expect(200);
    await request(h.http)
      .post(`/v1/trips/${trip.id}/collections`)
      .set(...bearer(driver.session))
      .send(cash(800))
      .expect(201);
    expect(await settlement(driver.driverId)).toMatchObject({
      expectedFarePaise: rupees(800),
      cashPaise: rupees(800),
      tripCount: 1,
    });
  });
});

describe('alerts inbox', () => {
  it('counts, lists and resolves alerts', async () => {
    const vehicle = await createVehicle(h, owner, 'MH12AL0001');
    await request(h.http)
      .post('/v1/documents')
      .set(...bearer(owner))
      .send({ docType: 'insurance', vehicleId: vehicle.id, expiresOn: today() })
      .expect(201);
    const summary = await request(h.http)
      .get('/v1/alerts/summary')
      .set(...bearer(owner))
      .expect(200);
    expect(
      (summary.body as { openAlerts: { critical: number } }).openAlerts.critical,
    ).toBeGreaterThanOrEqual(1);
    const open = (
      await request(h.http)
        .get(`/v1/alerts?status=open&vehicleId=${vehicle.id}`)
        .set(...bearer(owner))
        .expect(200)
    ).body as { id: string }[];
    expect(open).toHaveLength(1);
    const done = await request(h.http)
      .patch(`/v1/alerts/${open[0]?.id ?? ''}`)
      .set(...bearer(owner))
      .send({ status: 'resolved' })
      .expect(200);
    expect(done.body).toMatchObject({ status: 'resolved' });
  });

  it('dismissing a fuel alert as a false alarm lets that cycle train the baseline', async () => {
    const driver = await driverSession(h, owner, 'Fuel Tester');
    const vehicle = await createVehicle(h, owner, 'MH12AL0002');
    let km = 10_000;
    const fill = async (litres: number) => {
      await request(h.http)
        .post('/v1/fuel-fills')
        .set(...bearer(driver.session))
        .send({
          id: randomUUID(),
          vehicleId: vehicle.id,
          fuel: 'diesel',
          quantityMilli: litres * 1000,
          costPaise: litres * 9000,
          odometer: await odometer(h, driver.session, km),
          isFullTank: true,
          paidBy: 'owner',
          filledAt: new Date(Date.UTC(2026, 6, 1) + km * 1000).toISOString(),
        })
        .expect(201);
      km += 480;
    };
    for (const litres of [40, 40, 41, 40, 40, 58]) await fill(litres);
    await runJobs(h);
    const [alert] = (
      await request(h.http)
        .get(`/v1/alerts?vehicleId=${vehicle.id}&status=open`)
        .set(...bearer(owner))
        .expect(200)
    ).body as { id: string; kind: string }[];
    expect(alert?.kind).toBe('fuel_efficiency_low');
    await request(h.http)
      .patch(`/v1/alerts/${alert?.id ?? ''}`)
      .set(...bearer(owner))
      .send({ status: 'dismissed', falsePositive: true })
      .expect(200);
    await runJobs(h);
    const audit = (
      await request(h.http)
        .get(`/v1/vehicles/${vehicle.id}/fuel-cycles`)
        .set(...bearer(owner))
        .expect(200)
    ).body as {
      cycles: { includedInBaseline: boolean }[];
      baseline: { cycles: number };
    };
    expect(audit.cycles.at(-1)?.includedInBaseline).toBe(true);
    expect(audit.baseline.cycles).toBe(5);
  });
});

describe('review queue', () => {
  it('accepting the OCR value rewrites the odometer reading', async () => {
    const driver = await driverSession(h, owner, 'Review Tester');
    const vehicle = await createVehicle(h, owner, 'MH12RV0001');
    const reading = {
      id: randomUUID(),
      typedKm: 48_210,
      mediaId: await registerPhoto(h, driver.session),
      capturedAt: new Date().toISOString(),
    };
    await h.owner.odometerReading.create({
      data: {
        ...reading,
        orgId: owner.activeOrgId ?? '',
        vehicleId: vehicle.id,
        context: 'adhoc',
        capturedAt: new Date(),
        createdBy: owner.user.id,
        ocrKm: 48_270,
      },
    });
    await h.owner.reviewItem.create({
      data: {
        id: randomUUID(),
        orgId: owner.activeOrgId ?? '',
        kind: 'ocr_mismatch_odometer',
        subjectType: 'odometer_reading',
        subjectId: reading.id,
        typedValue: '48210',
        ocrValue: '48270',
      },
    });
    const open = (
      await request(h.http)
        .get('/v1/review-items?status=open')
        .set(...bearer(owner))
        .expect(200)
    ).body as { id: string; subjectId: string }[];
    const mine = open.find((i) => i.subjectId === reading.id);
    const resolved = await request(h.http)
      .post(`/v1/review-items/${mine?.id ?? ''}/resolve`)
      .set(...bearer(owner))
      .send({ resolution: 'accepted_ocr' })
      .expect(200);
    expect(resolved.body).toMatchObject({
      status: 'accepted_ocr',
      resolution: { appliedValue: 48_270 },
    });
    expect(
      (await h.owner.odometerReading.findUniqueOrThrow({ where: { id: reading.id } })).typedKm,
    ).toBe(48_270);
    await request(h.http)
      .post(`/v1/review-items/${mine?.id ?? ''}/resolve`)
      .set(...bearer(owner))
      .send({ resolution: 'dismissed' })
      .expect(409);
  });

  it('a correction needs a value', async () => {
    const item = await h.owner.reviewItem.create({
      data: {
        id: randomUUID(),
        orgId: owner.activeOrgId ?? '',
        kind: 'ocr_mismatch_odometer',
        subjectType: 'odometer_reading',
        subjectId: randomUUID(),
      },
    });
    const res = await request(h.http)
      .post(`/v1/review-items/${item.id}/resolve`)
      .set(...bearer(owner))
      .send({ resolution: 'corrected' })
      .expect(400);
    expect(res.body).toMatchObject({ error: { code: 'VALIDATION_FAILED' } });
  });
});
