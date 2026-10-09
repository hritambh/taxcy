// Fails when schema.prisma and the migrations disagree, e.g. a new migration that
// silently drops a hand-written constraint, or a schema change with no migration.
// Needs DATABASE_MIGRATION_URL and SHADOW_DATABASE_URL (an empty, throwaway database).
import { spawnSync } from 'node:child_process';

const result = spawnSync(
  'prisma',
  [
    'migrate',
    'diff',
    '--from-migrations',
    'prisma/migrations',
    '--to-schema',
    'prisma/schema.prisma',
    '--script',
    '--exit-code',
  ],
  { stdio: ['ignore', 'pipe', 'inherit'], encoding: 'utf8' },
);

if (result.status === 0) {
  process.stdout.write('db:drift — migrations match schema.prisma\n');
  process.exit(0);
}
process.stdout.write(result.stdout);
process.stderr.write(
  result.status === 2
    ? 'db:drift — schema.prisma and migrations differ (statements above). Add a migration or fix the schema.\n'
    : 'db:drift — prisma migrate diff failed\n',
);
process.exit(1);
