import { Inject, Injectable, type OnModuleDestroy } from '@nestjs/common';
import {
  createPrismaClient,
  withSystem,
  withTenant,
  type PrismaClient,
  type SystemTx,
  type TenantTx,
} from '@taxcy/db';
import { APP_CONFIG, type AppConfig } from './config.js';

/**
 * Owns the Prisma client. Services never touch the client directly: they open a
 * tenant transaction (RLS scoped to one org) or, for cross-org system work, a
 * system transaction, and hand that to repositories.
 */
@Injectable()
export class Db implements OnModuleDestroy {
  readonly client: PrismaClient;

  constructor(@Inject(APP_CONFIG) config: AppConfig) {
    this.client = createPrismaClient(config.DATABASE_URL);
  }

  tenant<T>(orgId: string, fn: (tx: TenantTx) => Promise<T>): Promise<T> {
    return withTenant(this.client, orgId, fn);
  }

  system<T>(fn: (tx: SystemTx) => Promise<T>): Promise<T> {
    return withSystem(this.client, fn);
  }

  async onModuleDestroy(): Promise<void> {
    await this.client.$disconnect();
  }
}
