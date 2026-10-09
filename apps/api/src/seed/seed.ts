// Loads demo data through the real services and jobs, so cycles, alerts, distance
// checks, review items and settlements are produced by the actual audit logic.
// Run with `bun run db:seed` (see seed-cli.ts). Safe to re-run: exits if the demo org exists.
import { PutObjectCommand } from '@aws-sdk/client-s3';
import type { INestApplicationContext } from '@nestjs/common';
import { istBusinessDate } from '@taxcy/domain';
import { createHash } from 'node:crypto';
import type { TenantAuth } from '../platform/auth/auth-context.js';
import { newId } from '../platform/ids.js';
import { JobDispatcher } from '../platform/jobs/job-dispatcher.js';
import type { JobEvent } from '../platform/jobs/on-job.js';
import { OutboxRelay } from '../platform/jobs/outbox-relay.js';
import { Db } from '../platform/prisma.service.js';
import { S3Service } from '../platform/s3.service.js';
import { DocumentsService } from '../modules/fleet/documents.service.js';
import { FleetService } from '../modules/fleet/fleet.service.js';
import { FuelService } from '../modules/fuel/fuel.service.js';
import { MediaService } from '../modules/media/media.service.js';
import { SettlementsService } from '../modules/money/settlements.service.js';
import { TelemetryService } from '../modules/telemetry/telemetry.service.js';
import { TripsService } from '../modules/trips/trips.service.js';
import { textPng } from './png.js';

const OWNER = { name: 'Anil Sharma', phone: '+919000000001' };
const MANAGER = { name: 'Priya Nair', phone: '+919000000002' };
const HISTORY_DAYS = 42;
const SETTLED_UNTIL_DAYS_AGO = 3;
const GPS_DAYS = 4;

const PAIRS = [
  {
    driver: { name: 'Ramesh Kumar', phone: '+919000000011' },
    vehicle: {
      reg: 'MH12AB1234',
      make: 'Toyota',
      model: 'Innova Crysta',
      fuel: 'diesel',
      odo: 48_000,
      kmpl: 11.5,
    },
  },
  {
    driver: { name: 'Suresh Patil', phone: '+919000000012' },
    vehicle: {
      reg: 'MH12CD5678',
      make: 'Maruti Suzuki',
      model: 'Dzire',
      fuel: 'cng',
      odo: 61_000,
      kmpl: 24,
    },
  },
  {
    driver: { name: 'Imran Shaikh', phone: '+919000000013' },
    vehicle: {
      reg: 'MH12EF9012',
      make: 'Toyota',
      model: 'Etios',
      fuel: 'petrol',
      odo: 35_000,
      kmpl: 14,
    },
  },
] as const;

const PRICES = { diesel: 9_000, cng: 9_000, petrol: 10_500 } as const; // paise per L/kg
const ROUTES = [
  ['Pune Station', 'Mumbai Airport T2'],
  ['Hinjewadi Phase 1', 'Lonavala'],
  ['Kothrud', 'Mahabaleshwar'],
  ['Pune Airport', 'Nashik Road'],
  ['Viman Nagar', 'Shirdi'],
  ['Baner', 'Satara'],
] as const;
const PUNE = { lat: 18.5286, lng: 73.8743 };

/** Deterministic pseudo-random numbers, so every seed run produces the same data. */
let rng = 42;
const random = () => (rng = (rng * 1_103_515_245 + 12_345) % 2_147_483_648) / 2_147_483_648;
const between = (min: number, max: number) => Math.round(min + random() * (max - min));

const todayIst = istBusinessDate(new Date());
/** A UTC instant for an IST wall-clock time `daysAgo` days before today. */
function ist(daysAgo: number, hour: number, minute = 0): Date {
  const [y, m, d] = todayIst.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d - daysAgo, hour - 5, minute - 30));
}

class Seeder {
  private readonly db: Db;
  private readonly s3: S3Service;
  private readonly media: MediaService;
  private readonly fleet: FleetService;
  private readonly documents: DocumentsService;
  private readonly trips: TripsService;
  private readonly fuel: FuelService;
  private readonly telemetry: TelemetryService;
  private readonly settlements: SettlementsService;
  private photos = 0;

  constructor(private readonly ctx: INestApplicationContext) {
    this.db = ctx.get(Db);
    this.s3 = ctx.get(S3Service);
    this.media = ctx.get(MediaService);
    this.fleet = ctx.get(FleetService);
    this.documents = ctx.get(DocumentsService);
    this.trips = ctx.get(TripsService);
    this.fuel = ctx.get(FuelService);
    this.telemetry = ctx.get(TelemetryService);
    this.settlements = ctx.get(SettlementsService);
  }

  async run(): Promise<void> {
    const existing = await this.db.system((tx) =>
      tx.user.findUnique({ where: { phoneE164: OWNER.phone }, include: { memberships: true } }),
    );
    if (existing?.memberships.length) {
      log('Demo org already exists; nothing to do. Run `bun run db:reset` to start over.');
      this.printLogins();
      return;
    }

    await this.referenceData();
    const { owner, orgId } = await this.org();
    const fleet = [];
    for (const pair of PAIRS) {
      const vehicle = await this.db.tenant(orgId, async (tx) =>
        this.fleet.createVehicle(tx, {
          registrationNo: pair.vehicle.reg,
          make: pair.vehicle.make,
          model: pair.vehicle.model,
          fuelType: pair.vehicle.fuel,
          year: 2022,
          lastOdometerKm: pair.vehicle.odo,
          vehicleModelId: await tx.vehicleModel
            .findFirst({ where: { orgId: null, model: pair.vehicle.model }, select: { id: true } })
            .then((m) => m?.id),
        }),
      );
      const driver = await this.db.tenant(orgId, (tx) => this.fleet.inviteDriver(tx, pair.driver));
      await this.db.tenant(orgId, (tx) =>
        tx.membership.updateMany({
          where: { orgId, userId: driver.userId },
          data: { status: 'active' },
        }),
      );
      const auth: TenantAuth = { userId: driver.userId, orgId, roles: ['driver'] };
      fleet.push({
        pair,
        vehicle,
        driver,
        auth,
        odo: pair.vehicle.odo,
        sinceFull: 0,
        cycleIndex: 0,
      });
    }
    log(`org, ${fleet.length} vehicles and drivers`);

    await this.seedDocuments(
      owner,
      fleet.map((f) => ({ vehicleId: f.vehicle.id, driverId: f.driver.id })),
    );
    log('documents');

    // History: trips most days, fuel when the tank runs low, GPS for the last few days.
    for (let daysAgo = HISTORY_DAYS; daysAgo >= 1; daysAgo--) {
      for (const [index, f] of fleet.entries()) {
        const drivesToday = (daysAgo + index) % 7 !== 0 && (daysAgo + index * 2) % 5 !== 0;
        if (drivesToday) {
          const km = between(90, 230);
          const inflated = f.pair.vehicle.reg === 'MH12AB1234' && daysAgo === 1;
          const ocrMismatch = f.pair.vehicle.reg === 'MH12EF9012' && daysAgo === 2;
          await this.pastTrip(owner, f, daysAgo, km, {
            withGps: daysAgo <= GPS_DAYS,
            inflated,
            ocrMismatch,
          });
        }
        if (f.sinceFull >= f.pair.vehicle.kmpl * 32 || (daysAgo === 1 && f.sinceFull > 150)) {
          const theft = f.pair.vehicle.reg === 'MH12CD5678' && daysAgo <= 3;
          await this.fill(f, daysAgo, theft);
        }
      }
      if (daysAgo % 7 === 0) log(`history: ${HISTORY_DAYS - daysAgo + 1}/${HISTORY_DAYS} days`);
    }

    await this.todaysTrips(owner, fleet);
    log('today’s trips');

    log('running jobs (OCR, fuel audits, distance checks)…');
    await this.drainJobs();
    await this.ctx
      .get(JobDispatcher)
      .dispatch({ topic: 'fleet.document_expiry_scan', orgId: null, payload: {} });

    for (let daysAgo = HISTORY_DAYS; daysAgo >= SETTLED_UNTIL_DAYS_AGO; daysAgo--) {
      for (const f of fleet) {
        const date = new Date(`${istBusinessDate(ist(daysAgo, 12))}T00:00:00.000Z`);
        const draft = await this.settlements.get(owner, date, f.driver.id);
        if (draft.lines.length) await this.settlements.settle(owner, date, f.driver.id);
      }
    }
    log(
      `settled every day up to ${SETTLED_UNTIL_DAYS_AGO} days ago (the last two days are left as drafts)`,
    );
    log(`${this.photos} photos uploaded`);
    this.printLogins();
  }

  private printLogins(): void {
    log('');
    log('Seeded org "Sharma Travels"');
    log(`  owner    ${OWNER.name.padEnd(15)} ${OWNER.phone}`);
    log(`  manager  ${MANAGER.name.padEnd(15)} ${MANAGER.phone}`);
    for (const p of PAIRS)
      log(
        `  driver   ${p.driver.name.padEnd(15)} ${p.driver.phone}   (${p.vehicle.model}, ${p.vehicle.fuel})`,
      );
    log('Sign in with any of these numbers; the OTP is printed in the API log.');
  }

  private async referenceData(): Promise<void> {
    await this.db.system(async (tx) => {
      const models = [
        {
          make: 'Toyota',
          model: 'Innova Crysta',
          fuelType: 'diesel',
          track: 'diesel',
          mean: 11.5,
          std: 1.0,
        },
        {
          make: 'Maruti Suzuki',
          model: 'Dzire',
          fuelType: 'cng',
          track: 'cng',
          mean: 24,
          std: 2.0,
        },
        { make: 'Toyota', model: 'Etios', fuelType: 'petrol', track: 'petrol', mean: 14, std: 1.3 },
        {
          make: 'Maruti Suzuki',
          model: 'Ertiga',
          fuelType: 'petrol_cng',
          track: 'bifuel_cost',
          mean: 420,
          std: 40,
        },
      ] as const;
      for (const m of models) {
        if (await tx.vehicleModel.count({ where: { orgId: null, model: m.model } })) continue;
        const id = newId();
        await tx.vehicleModel.create({
          data: { id, make: m.make, model: m.model, fuelType: m.fuelType },
        });
        await tx.fuelBaselineDefault.create({
          data: {
            id: newId(),
            vehicleModelId: id,
            track: m.track,
            meanValue: m.mean,
            stdValue: m.std,
          },
        });
      }
    });
  }

  private async org(): Promise<{ owner: TenantAuth; orgId: string }> {
    const orgId = newId();
    const ownerId = newId();
    await this.db.tenant(orgId, async (tx) => {
      await tx.user.create({ data: { id: ownerId, phoneE164: OWNER.phone, name: OWNER.name } });
      await tx.organization.create({ data: { id: orgId, name: 'Sharma Travels', kind: 'fleet' } });
      await tx.orgSettings.create({
        data: {
          orgId,
          driverPayRule: {
            kind: 'percent_of_fare',
            percent: 20,
            base: 'quoted',
            allowanceToDriver: true,
          },
        },
      });
      await tx.membership.create({
        data: { id: newId(), orgId, userId: ownerId, roles: ['owner'] },
      });
      const managerId = newId();
      await tx.user.upsert({
        where: { phoneE164: MANAGER.phone },
        update: {},
        create: { id: managerId, phoneE164: MANAGER.phone, name: MANAGER.name },
      });
      const manager = await tx.user.findUniqueOrThrow({ where: { phoneE164: MANAGER.phone } });
      await tx.membership.create({
        data: { id: newId(), orgId, userId: manager.id, roles: ['manager'] },
      });
    });
    return { owner: { userId: ownerId, orgId, roles: ['owner'] }, orgId };
  }

  private async seedDocuments(
    owner: TenantAuth,
    items: { vehicleId: string; driverId: string }[],
  ): Promise<void> {
    const inDays = (d: number) => new Date(`${istBusinessDate(ist(-d, 12))}T00:00:00.000Z`);
    await this.db.tenant(owner.orgId, async (tx) => {
      for (const [i, item] of items.entries()) {
        const docs = [
          { docType: 'rc', expiresOn: inDays(3_000) },
          { docType: 'insurance', expiresOn: inDays(i === 1 ? 5 : 200 + i * 40) },
          { docType: 'permit', expiresOn: inDays(400 + i * 30) },
          { docType: 'puc', expiresOn: inDays(i === 2 ? 24 : 120) },
        ] as const;
        for (const d of docs)
          await this.documents.create(tx, {
            ...d,
            vehicleId: item.vehicleId,
            number: `${d.docType.toUpperCase()}-${1000 + i}`,
          });
        await this.documents.create(tx, {
          docType: 'driving_licence',
          driverId: item.driverId,
          expiresOn: inDays(i === 2 ? 25 : 900),
          number: `MH12 2015000${i}`,
        });
      }
    });
  }

  /** Registers, uploads and confirms a photo; the stub OCR reads `ocr` from its metadata. */
  private async photo(
    auth: TenantAuth,
    kind: 'odometer' | 'fuel_receipt',
    text: string,
    at: Date,
    ocr: Record<string, string>,
  ): Promise<string> {
    const bytes = textPng(
      text,
      kind === 'odometer'
        ? { bg: [20, 20, 20], fg: [250, 250, 250] }
        : { bg: [250, 248, 240], fg: [30, 30, 30] },
    );
    const id = newId();
    await this.media.create(auth, {
      id,
      kind,
      contentType: 'image/png',
      sha256: createHash('sha256').update(bytes).digest('hex'),
      byteSize: bytes.length,
      capturedAt: at,
      location: { lat: PUNE.lat, lng: PUNE.lng, accuracyM: 8 },
    });
    const { storageKey } = await this.db.tenant(auth.orgId, (tx) =>
      tx.mediaObject.findUniqueOrThrow({ where: { id } }),
    );
    await this.s3.client.send(
      new PutObjectCommand({
        Bucket: this.s3.bucket,
        Key: storageKey,
        Body: bytes,
        ContentType: 'image/png',
        Metadata: ocr,
      }),
    );
    await this.media.complete(auth, id);
    this.photos += 1;
    return id;
  }

  private async odometer(auth: TenantAuth, km: number, at: Date, ocrKm = km) {
    return {
      id: newId(),
      typedKm: km,
      mediaId: await this.photo(auth, 'odometer', `${km} KM`, at, { 'ocr-km': String(ocrKm) }),
      capturedAt: at,
    };
  }

  private async pastTrip(
    owner: TenantAuth,
    f: {
      pair: (typeof PAIRS)[number];
      vehicle: { id: string };
      driver: { id: string };
      auth: TenantAuth;
      odo: number;
      sinceFull: number;
    },
    daysAgo: number,
    km: number,
    options: { withGps: boolean; inflated: boolean; ocrMismatch: boolean },
  ): Promise<void> {
    const [from, to] = ROUTES[between(0, ROUTES.length - 1)] ?? ROUTES[0];
    const startHour = between(7, 11);
    const start = ist(daysAgo, startHour);
    const hours = Math.max(2, Math.round(km / 55));
    const end = new Date(start.getTime() + hours * 3_600_000);
    const fare = Math.round((km * 16) / 50) * 50 * 100;
    const trip = await this.trips.create(owner, {
      tripType: 'one_way',
      customer: { name: CUSTOMERS[between(0, CUSTOMERS.length - 1)] ?? 'Walk-in customer' },
      from: { text: from, point: PUNE },
      to: { text: to, point: null },
      scheduledStartAt: start,
      scheduledEndAt: end,
      quotedFarePaise: fare,
      vehicleId: f.vehicle.id,
      driverId: f.driver.id,
    });
    const odoKm = options.inflated ? Math.round(km * 1.21) : km;
    await this.trips.start(f.auth, trip.id, newId(), {
      odometer: await this.odometer(f.auth, f.odo, start, options.ocrMismatch ? f.odo + 60 : f.odo),
      occurredAt: start,
    });
    if (options.withGps) await this.gps(f.auth, trip.id, start, end, km);
    const toll = random() < 0.4 ? between(1, 4) * 5_000 : 0;
    const cashShare = random() < 0.5 ? 1 : 0.6;
    const total = fare + toll;
    const cash = Math.round((total * cashShare) / 100) * 100;
    await this.trips.end(f.auth, trip.id, newId(), {
      odometer: await this.odometer(f.auth, f.odo + odoKm, end),
      occurredAt: end,
      charges: toll ? [{ id: newId(), kind: 'toll', amountPaise: toll, paidByDriver: true }] : [],
      collections: [
        { id: newId(), method: 'cash', amountPaise: cash, collectedAt: end },
        ...(total - cash > 0
          ? [
              {
                id: newId(),
                method: 'upi' as const,
                amountPaise: total - cash,
                reference: `UPI${between(100_000, 999_999)}`,
                collectedAt: end,
              },
            ]
          : []),
      ],
    });
    f.odo += odoKm;
    f.sinceFull += odoKm;
  }

  private async fill(
    f: {
      pair: (typeof PAIRS)[number];
      vehicle: { id: string };
      auth: TenantAuth;
      odo: number;
      sinceFull: number;
      cycleIndex: number;
    },
    daysAgo: number,
    theft: boolean,
  ): Promise<void> {
    const at = ist(daysAgo, 19, between(0, 50));
    const fuel = f.pair.vehicle.fuel;
    const efficiency = f.pair.vehicle.kmpl * (1 + (random() - 0.5) * 0.08);
    const quantity = (f.sinceFull / efficiency) * (theft ? 1.35 : 1);
    const quantityMilli = Math.max(1_000, Math.round(quantity * 1_000));
    const cost = Math.round((quantityMilli / 1_000) * PRICES[fuel]);
    const receipt = await this.photo(f.auth, 'fuel_receipt', `RS ${Math.round(cost / 100)}`, at, {
      'ocr-amount-paise': String(cost),
    });
    await this.fuel.record(f.auth, {
      id: newId(),
      vehicleId: f.vehicle.id,
      fuel,
      quantityMilli,
      costPaise: cost,
      odometer: await this.odometer(f.auth, f.odo, at),
      isFullTank: true,
      receiptMediaId: receipt,
      paidBy: f.cycleIndex % 3 === 0 ? 'owner' : 'driver_cash',
      filledAt: at,
    });
    f.sinceFull = 0;
    f.cycleIndex += 1;
  }

  /** A straight-line track north from Pune covering `km` between start and end, one point per 30 s. */
  private async gps(
    auth: TenantAuth,
    tripId: string,
    start: Date,
    end: Date,
    km: number,
  ): Promise<void> {
    const steps = Math.floor((end.getTime() - start.getTime()) / 30_000);
    const points = Array.from({ length: steps + 1 }, (_, i) => ({
      id: newId(),
      recordedAt: new Date(start.getTime() + i * 30_000),
      lat: PUNE.lat + (km * i) / steps / 111.2,
      lng: PUNE.lng,
      accuracyM: 6 + (i % 5),
    }));
    for (let i = 0; i < points.length; i += 500)
      await this.telemetry.ingest(auth, tripId, points.slice(i, i + 500));
  }

  private async todaysTrips(
    owner: TenantAuth,
    fleet: {
      pair: (typeof PAIRS)[number];
      vehicle: { id: string };
      driver: { id: string };
      auth: TenantAuth;
      odo: number;
      sinceFull: number;
    }[],
  ): Promise<void> {
    const [ramesh, suresh, imran] = fleet;
    if (!ramesh || !suresh || !imran) return;
    // Ramesh: an early airport drop, already ended today.
    await this.pastTrip(owner, ramesh, 0, 38, {
      withGps: true,
      inflated: false,
      ocrMismatch: false,
    });

    // Suresh: on the road right now.
    const now = Date.now();
    const started = new Date(now - 75 * 60_000);
    const running = await this.trips.create(owner, {
      tripType: 'round_trip',
      customer: { name: 'Meera Joshi', phone: '+919822000101' },
      from: { text: 'Aundh', point: PUNE },
      to: { text: 'Lavasa', point: null },
      scheduledStartAt: started,
      scheduledEndAt: new Date(now + 5 * 3_600_000),
      quotedFarePaise: 450_000,
      vehicleId: suresh.vehicle.id,
      driverId: suresh.driver.id,
    });
    await this.trips.start(suresh.auth, running.id, newId(), {
      odometer: await this.odometer(suresh.auth, suresh.odo, started),
      occurredAt: started,
    });
    await this.gps(suresh.auth, running.id, started, new Date(now - 60_000), 62);

    // Imran: assigned for this evening. Plus an unassigned and a cancelled booking tomorrow.
    const evening = new Date(now + 4 * 3_600_000);
    await this.trips.create(owner, {
      tripType: 'local_rental',
      customer: { name: 'Rahul Verma', phone: '+919822000102' },
      from: { text: 'Koregaon Park' },
      scheduledStartAt: evening,
      scheduledEndAt: new Date(evening.getTime() + 8 * 3_600_000),
      quotedFarePaise: 280_000,
      vehicleId: imran.vehicle.id,
      driverId: imran.driver.id,
    });
    await this.trips.create(owner, {
      tripType: 'one_way',
      customer: { name: 'Sneha Kulkarni', phone: '+919822000103' },
      from: { text: 'Pune Station', point: PUNE },
      to: { text: 'Goa (Panaji)' },
      scheduledStartAt: new Date(now + 26 * 3_600_000),
      scheduledEndAt: new Date(now + 37 * 3_600_000),
      quotedFarePaise: 1_150_000,
    });
    const cancelled = await this.trips.create(owner, {
      tripType: 'one_way',
      customer: { name: 'Vikram Rao' },
      from: { text: 'Wakad' },
      to: { text: 'Mumbai Central' },
      scheduledStartAt: new Date(now + 30 * 3_600_000),
      scheduledEndAt: new Date(now + 35 * 3_600_000),
      quotedFarePaise: 380_000,
    });
    await this.trips.cancel(owner, cancelled.id, newId(), 'Customer booked a flight instead');
  }

  private async drainJobs(): Promise<void> {
    const relay = this.ctx.get(OutboxRelay);
    const dispatcher = this.ctx.get(JobDispatcher);
    for (;;) {
      const events: JobEvent[] = [];
      await relay.drainOnce((event) => {
        events.push(event);
        return Promise.resolve();
      }, 500);
      if (!events.length) return;
      for (const event of events) await dispatcher.dispatch(event);
    }
  }
}

const CUSTOMERS = [
  'Anita Desai',
  'Rohit Mehta',
  'Kavya Iyer',
  'Sameer Khan',
  'Pooja Patil',
  'Arjun Nair',
  'Neha Gupta',
];

function log(message: string): void {
  process.stdout.write(`${message}\n`);
}

/** Seeds the demo org into the database `ctx` is connected to. */
export async function runSeed(ctx: INestApplicationContext): Promise<void> {
  // Partitions for every month the seed writes GPS points into.
  await ctx.get(Db).system(async (tx) => {
    for (const offset of [-1, 0, 1, 2]) {
      const month = new Date(
        Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth() + offset, 1),
      )
        .toISOString()
        .slice(0, 10);
      await tx.$queryRaw`SELECT ensure_gps_partition(${month}::date)`;
    }
  });
  await new Seeder(ctx).run();
}
