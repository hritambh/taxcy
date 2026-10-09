import { defineConfig } from 'prisma/config';

// Migrations run as the table owner; the app connects as taxcy_api (see infra/postgres).
const url = process.env['DATABASE_MIGRATION_URL'] ?? process.env['DATABASE_URL'];
// Throwaway database that `migrate diff --from-migrations` replays migrations into.
const shadowDatabaseUrl = process.env['SHADOW_DATABASE_URL'];

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: { path: 'prisma/migrations' },
  ...(url ? { datasource: { url, ...(shadowDatabaseUrl ? { shadowDatabaseUrl } : {}) } } : {}),
  experimental: { externalTables: true },
  // gps_points is range-partitioned, which Prisma can't model; it's created by a
  // hand-written migration and only read/written through raw SQL.
  tables: { external: ['public.gps_points'] },
});
