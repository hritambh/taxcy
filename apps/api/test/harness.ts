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
