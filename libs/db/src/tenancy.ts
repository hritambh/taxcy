import type { Prisma, PrismaClient } from './generated/prisma/client.js';

declare const tenantBrand: unique symbol;
declare const systemBrand: unique symbol;

/**
 * A transaction in which `app.org_id` is set, so row-level security only exposes
 * this org's rows. Repositories accept only this type, so a query can't run
 * without a tenant context. `orgId` is carried along for explicit WHERE clauses:
 * RLS is the backstop, not the primary filter.
 */
export type TenantTx = Prisma.TransactionClient & {
  readonly orgId: string;
  readonly [tenantBrand]: true;
};

/** A transaction that may see every org's rows (system jobs, pre-login lookups). */
export type SystemTx = Prisma.TransactionClient & { readonly [systemBrand]: true };

interface TxOptions {
  timeoutMs?: number;
}

export async function withTenant<T>(
  prisma: PrismaClient,
  orgId: string,
  fn: (tx: TenantTx) => Promise<T>,
  options: TxOptions = {},
): Promise<T> {
  return prisma.$transaction(
    async (tx) => {
      await tx.$executeRaw`SELECT set_config('app.org_id', ${orgId}, true)`;
      return fn(Object.assign(tx, { orgId }) as TenantTx);
    },
    { timeout: options.timeoutMs ?? 15_000 },
  );
}

export async function withSystem<T>(
  prisma: PrismaClient,
  fn: (tx: SystemTx) => Promise<T>,
  options: TxOptions = {},
): Promise<T> {
  return prisma.$transaction(
    async (tx) => {
      await tx.$executeRaw`SELECT set_config('app.bypass_rls', 'on', true)`;
      return fn(tx as SystemTx);
    },
    { timeout: options.timeoutMs ?? 30_000 },
  );
}
