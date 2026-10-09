import { JobDispatcher } from '../src/platform/jobs/job-dispatcher.js';
import type { JobEvent } from '../src/platform/jobs/on-job.js';
import { OutboxRelay } from '../src/platform/jobs/outbox-relay.js';
import type { Session } from '@taxcy/contracts';
import request from 'supertest';
import { randomInt, randomUUID } from 'node:crypto';
import { SMS_PROVIDER, type ConsoleSmsProvider } from '../src/modules/identity/sms.provider.js';
import type { INestApplication } from '@nestjs/common';
import { createPrismaClient, type PrismaClient } from '@taxcy/db';
import type { App } from 'supertest/types.js';
import { createApp } from '../src/app.js';

export interface Harness {
  app: INestApplication;
  http: App;
  /** Owner connection: bypasses RLS. For arranging fixtures and asserting raw state only. */
  owner: PrismaClient;
  close(): Promise<void>;
}

export async function startHarness(): Promise<Harness> {
  const app = await createApp({ logs: false });
  const owner = createPrismaClient(requireEnv('DATABASE_MIGRATION_URL'));
  return {
    app,
    http: app.getHttpServer() as App,
    owner,
    async close() {
      await owner.$disconnect();
      await app.close();
    },
  };
}

export function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is not set; is the integration global setup running?`);
  return value;
}

/** A random valid Indian mobile number, so per-phone rate limits never collide across tests. */
export function randomPhone(): string {
  return `+919${randomInt(0, 1_000_000_000).toString().padStart(9, '0')}`;
}

export function lastOtp(h: Harness, phone: string): string {
  const code = h.app.get<ConsoleSmsProvider>(SMS_PROVIDER).lastCodeFor(phone);
  if (!code) throw new Error(`No OTP was sent to ${phone}`);
  return code;
}

/** Signs in through the real OTP flow. */
export async function login(h: Harness, phone = randomPhone()): Promise<Session> {
  await request(h.http).post('/v1/auth/otp/request').send({ phone }).expect(202);
  const res = await request(h.http)
    .post('/v1/auth/otp/verify')
    .send({ phone, code: lastOtp(h, phone), deviceId: randomUUID(), platform: 'web' })
    .expect(200);
  return res.body as Session;
}

/** Signs up a new user and creates an org they own; returns a session scoped to it. */
export async function ownerSession(
  h: Harness,
  kind: 'fleet' | 'dco' = 'fleet',
  name = 'Test Travels',
): Promise<Session> {
  const session = await login(h);
  const res = await request(h.http)
    .post('/v1/orgs')
    .set('Authorization', `Bearer ${session.accessToken}`)
    .send({ name, kind, refreshToken: session.refreshToken })
    .expect(201);
  return res.body as Session;
}

export const bearer = (session: Session): [string, string] => [
  'Authorization',
  `Bearer ${session.accessToken}`,
];

/**
 * Drains the outbox and runs each job's handler in-process, repeating until no new
 * events appear (handlers may publish follow-up events). Mirrors what the workers
 * app does through BullMQ, minus the queue, so tests are deterministic.
 */
export async function runJobs(h: Harness): Promise<number> {
  const relay = h.app.get(OutboxRelay);
  const dispatcher = h.app.get(JobDispatcher);
  let total = 0;
  for (let round = 0; round < 20; round++) {
    const events: JobEvent[] = [];
    await relay.drainOnce((event) => {
      events.push(event);
      return Promise.resolve();
    });
    if (!events.length) return total;
    for (const event of events) await dispatcher.dispatch(event);
    total += events.length;
  }
  throw new Error('runJobs: jobs keep producing events after 20 rounds');
}
