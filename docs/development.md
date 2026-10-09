# Development guide

For a first run, follow [getting-started.md](getting-started.md). This page is the reference: tools, services, environment variables, scripts, tests and conventions.

## Toolchain

| Tool                   | Version                  | Used for                                                                            |
| ---------------------- | ------------------------ | ----------------------------------------------------------------------------------- |
| Node.js                | 24.x (`.nvmrc`)          | Runtime for the API, workers, seed and tooling                                      |
| Bun                    | 1.4.x (`packageManager`) | **Package manager only**: installs, workspaces, running scripts. Code runs on Node. |
| Nx                     | 23.x                     | Task runner and cache (`nx run-many`, libs build before their dependents)           |
| TypeScript             | 6.0.x                    | Pinned below 7 because typescript-eslint doesn't support TypeScript 7 yet           |
| Prisma                 | 7.10 (`libs/db`)         | Schema, migrations, client (driver adapter `@prisma/adapter-pg`)                    |
| Docker                 | 24+                      | Postgres, Redis and RustFS locally; Testcontainers in integration tests             |
| Flutter                | 3.38.x (Dart 3.10)       | Driver app                                                                          |
| Android Studio / Xcode | latest                   | Driver app emulator/simulator builds                                                |

### Why the Node apps build with `tsc`

NestJS 12 is ESM-only and relies on `emitDecoratorMetadata` for dependency injection. esbuild-based runners (tsx, `bun run file.ts`) and Vite's default transform don't emit that metadata. So `apps/api` and `apps/workers` compile with `tsc`, `dev` runs `tsc --watch` next to `node --watch`, and the API's Vitest configs use SWC (`unplugin-swc`).

### How workspace libs are consumed

| Condition | Target            | Used by                                |
| --------- | ----------------- | -------------------------------------- |
| `source`  | `src/index.ts`    | Vite (admin web) and its type-checking |
| `types`   | `dist/index.d.ts` | `tsc` in the Node apps                 |
| `default` | `dist/index.js`   | Node at runtime                        |

Nx builds a project's libs first, so `dist/` is fresh whenever a Node app needs it. Bun installs workspaces in **isolated** mode: a package can only import what its own `package.json` lists, including `@types/node`.

## Local services

`bun run infra:up` starts them; `docker-compose.yml` defines them.

| Service                     | Address                                               | Credentials (dev only)                                                    |
| --------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------- |
| PostgreSQL 16 + PostGIS 3.5 | `localhost:5433`                                      | owner `taxcy`/`taxcy`; app role `taxcy_api`/`taxcy_api`; database `taxcy` |
| Redis 8                     | `localhost:6380`                                      | —                                                                         |
| RustFS (S3 API)             | <http://localhost:9000>                               | `taxcy` / `taxcy-dev-secret`, bucket `taxcy-media`                        |
| RustFS console              | <http://localhost:9001/rustfs/console/>               | same                                                                      |
| API                         | <http://localhost:3000/v1>                            | —                                                                         |
| API docs                    | <http://localhost:3000/docs> (`/` redirects here)     | —                                                                         |
| Bull Board (job queues)     | <http://localhost:3001/queues>                        | —                                                                         |
| Admin web                   | <http://localhost:5173> (proxies `/api/*` to the API) | —                                                                         |

- **Ports:** the host ports avoid 5432 and 6379, so a natively installed Postgres or another project's Redis can't silently answer on `localhost`.
- **Database roles:** the Postgres init script (`infra/postgres/init-roles.sql`) creates `taxcy_api`, the role the API and workers connect as. It is neither a superuser nor the table owner, so [row-level security](architecture.md#multi-tenancy) applies to it. Migrations and the seed's reference data run as the owner.
- **Object storage:** local S3 is **RustFS**, because MinIO no longer publishes container images. The API speaks plain S3 (AWS SDK).

## Environment variables

The API and workers validate their environment at startup with Zod (`apps/api/src/platform/config.ts`) and exit with a readable list of problems. `.env.example` has working local values; never commit real secrets.

| Variable                                                                            | Default                 | Purpose                                                           |
| ----------------------------------------------------------------------------------- | ----------------------- | ----------------------------------------------------------------- |
| `NODE_ENV`                                                                          | `development`           | `development` \| `test` \| `production`                           |
| `PORT`                                                                              | `3000`                  | API port                                                          |
| `LOG_LEVEL`                                                                         | `info`                  | pino level; pretty-printed in development                         |
| `CORS_ORIGINS`                                                                      | `http://localhost:5173` | Comma-separated allowed origins                                   |
| `DATABASE_URL`                                                                      | —                       | App role connection (`taxcy_api`, RLS applies)                    |
| `DATABASE_MIGRATION_URL`                                                            | —                       | Owner connection for migrations and the seed                      |
| `SHADOW_DATABASE_URL`                                                               | —                       | Empty database used by `db:drift`                                 |
| `POSTGRES_*`, `REDIS_PORT`, `S3_PORT`, `S3_CONSOLE_PORT`                            | see `.env.example`      | docker-compose settings                                           |
| `REDIS_URL`                                                                         | —                       | OTPs, rate limits, BullMQ                                         |
| `S3_ENDPOINT`, `S3_REGION`, `S3_BUCKET`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` | —                       | Object storage                                                    |
| `S3_PUBLIC_ENDPOINT`                                                                | `S3_ENDPOINT`           | Host used in signed URLs; set to your LAN IP for a physical phone |
| `S3_UPLOAD_URL_TTL_SECONDS`                                                         | `600`                   | Signed upload URL lifetime                                        |
| `JWT_ACCESS_SECRET`                                                                 | —                       | ≥ 32 characters                                                   |
| `JWT_ACCESS_TTL_SECONDS` / `JWT_REFRESH_TTL_DAYS`                                   | `900` / `30`            | Token lifetimes                                                   |
| `OTP_TTL_SECONDS` / `OTP_MAX_ATTEMPTS` / `OTP_IP_LIMIT_PER_HOUR`                    | `300` / `5` / `30`      | OTP login                                                         |
| `SMS_PROVIDER` / `OCR_PROVIDER`                                                     | `console` / `stub`      | Provider selection (only stubs exist so far)                      |
| `SENTRY_DSN`                                                                        | empty                   | Sentry is enabled when set                                        |
| `WORKERS_DASHBOARD_PORT`                                                            | `3001`                  | Bull Board                                                        |

## Scripts

Run from the repo root with `bun run <script>`.

| Script                                    | What it does                                                                                         |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `dev`                                     | API, workers and admin web in watch mode (builds libs first)                                         |
| `dev:api` / `dev:workers` / `dev:admin`   | One app only                                                                                         |
| `infra:up` / `infra:down` / `infra:reset` | Start, stop, or wipe and restart Postgres, Redis and RustFS                                          |
| `db:migrate`                              | Apply migrations (`prisma migrate deploy`)                                                           |
| `db:seed`                                 | Load the demo fleet (safe to re-run; skips if it already exists)                                     |
| `db:reset`                                | Drop everything, migrate, and seed                                                                   |
| `db:migration <name>`                     | Create a migration for review (`prisma migrate dev --create-only`)                                   |
| `db:drift`                                | Fail if `schema.prisma` and the migrations disagree (needs the shadow database)                      |
| `db:generate` / `db:studio`               | Prisma client generation / Prisma Studio                                                             |
| `api:client`                              | Rebuild `libs/api-client/openapi.json` and the typed client from the contracts                       |
| `lint` / `typecheck` / `test` / `build`   | Across all projects, including `dart format` + `flutter analyze` + `flutter test` for the driver app |
| `test:integration`                        | API integration tests against throwaway containers (about 5 minutes)                                 |
| `format` / `format:check`                 | Prettier                                                                                             |
| `verify`                                  | `format:check`, then lint, typecheck, test and build: what CI runs                                   |

Run one project's target with `bunx nx run @taxcy/domain:test`. Nx caches results; add `--skip-nx-cache` to force a run.

### Creating a migration

1. Edit `libs/db/prisma/schema.prisma`.
2. `bun run db:migration add_something` writes `libs/db/prisma/migrations/<timestamp>_add_something/migration.sql` without applying it.
3. **Read the SQL.** Prisma will drop objects it doesn't model, such as partitions, exclusion constraints, CHECKs, RLS policies and functions. If you see such drops, delete them.
4. `bun run db:migrate`, then `bun run db:drift`.

## Projects

| Project             | Path              | What's inside                                                                                                                                                                                                                    |
| ------------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `@taxcy/api`        | `apps/api`        | NestJS modular monolith: `platform/` (config, logging, auth guard, contract binding, idempotency, outbox, jobs) and `modules/` (identity, media, fleet, trips, fuel, telemetry, money, alerts)                                   |
| `@taxcy/workers`    | `apps/workers`    | Outbox relay → BullMQ, a worker per queue, cron schedules, Bull Board. Boots the API's modules without HTTP (`@taxcy/api/worker`).                                                                                               |
| `@taxcy/admin-web`  | `apps/admin-web`  | Owner/manager console (React 19, Vite 8, Tailwind 4)                                                                                                                                                                             |
| `@taxcy/driver-app` | `apps/driver-app` | Flutter driver app (Dart package `taxcy_driver`). `bun run --cwd apps/driver-app codegen` regenerates the drift database code; `bunx nx run @taxcy/domain:fixtures` re-exports the trip transition fixture it is tested against. |
| `@taxcy/contracts`  | `libs/contracts`  | Zod route contracts, error codes, OpenAPI builder                                                                                                                                                                                |
| `@taxcy/domain`     | `libs/domain`     | Pure logic: fuel audit, GPS checks, trip state machine, settlement, document expiry                                                                                                                                              |
| `@taxcy/db`         | `libs/db`         | Prisma schema, migrations, client, tenant/system transactions                                                                                                                                                                    |
| `@taxcy/api-client` | `libs/api-client` | Generated TypeScript client (openapi-fetch)                                                                                                                                                                                      |
| `@taxcy/ui`         | `libs/ui`         | Shared React UI                                                                                                                                                                                                                  |

## Testing

| Suite                 | Where                            | What it covers                                                                                                                                                                                                   |
| --------------------- | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Domain unit tests     | `libs/domain` (Vitest)           | Every rule, table-driven, including the worked examples in [`docs/domain`](domain/)                                                                                                                              |
| Contract tests        | `libs/contracts`                 | Shared schemas                                                                                                                                                                                                   |
| API integration tests | `apps/api/test/*.int.test.ts`    | Each file boots the real Nest app on a port against Testcontainers (PostGIS, Redis, RustFS) with migrations applied, and drives it over HTTP. Background jobs run in-process via `runJobs()`.                    |
| Seed test             | `apps/api/test/seed.int.test.ts` | Runs the full demo seed and checks it produces the alerts, review items, trip states and settlements the guides promise                                                                                          |
| Driver app            | `apps/driver-app/test`           | `flutter test`: sync engine against a fake API (ordering, idempotency keys reused on retry, backoff, conflicts), drift outbox, model parsing, widgets, and state-machine conformance with the TypeScript fixture |

The integration suite covers OTP login and token rotation, row-level security, signed uploads and OCR reconciliation, fleet and document expiry, the trip lifecycle (idempotent replays, double-booking, offline conflicts, cancellation approval), fuel audits (late fills, voids, bi-fuel), GPS distance checks and partitions, and settlements (carry-forward of late items).

## Conventions

- **Layering:** controller (bound to a contract with `@Route`; `@Input()` gives validated params/query/body) → service (transactions via `Db.tenant()`/`Db.system()`) → repository or Prisma calls on the transaction → `libs/domain` for rules. Controllers hold no logic.
- **Tenancy:** org-scoped work happens inside `db.tenant(orgId, tx => …)`. `TenantTx` is the only way to reach org data, and RLS backs it up.
- **Writes and jobs:** side effects that should happen after commit are published with `publish(tx, topic, payload)` into the outbox. Handlers are marked `@OnJob(topic)` and must be idempotent.
- **Errors:** throw `AppError(code, message, details?)`. Anything else becomes a logged `500 INTERNAL`.
- **Errors that must persist:** if something must be recorded _and_ the request must fail (e.g. a rejected upload), commit the record in its own transaction, then throw. A throw inside the transaction rolls the record back.
- **Types:** strict TypeScript (`strictTypeChecked`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`), no `any`. Use `Patch<T>` + `definedOnly()` for partial updates.
- **Money and time:** paise as `bigint` in the DB and `number` in code. UTC everywhere; IST only for display and business dates (`istBusinessDate`).
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/).

## CI

`.github/workflows/ci.yml` runs on pushes to `main` and on pull requests:

| Job                      | Steps                                                                                                           |
| ------------------------ | --------------------------------------------------------------------------------------------------------------- |
| TypeScript               | install, `format:check`, lint, typecheck, test, build (excluding the driver app)                                |
| Migrations + integration | Postgres service → roles → `db:drift`; generated client must be up to date; `test:integration` (Testcontainers) |
| Flutter driver app       | `dart format` check, `flutter analyze --fatal-infos`, `flutter test`                                            |
