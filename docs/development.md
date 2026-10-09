# Development guide

For a first run, follow [getting-started.md](getting-started.md). This page is the reference: tools, services, environment variables, scripts and conventions.

> Rows marked **(planned)** describe things later milestones add. Everything else works as of M0.1.

## Toolchain

| Tool                   | Version                                    | Used for                                                                            |
| ---------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------- |
| Node.js                | 24.x (`.nvmrc`)                            | Runtime for the API, workers and all tooling                                        |
| Bun                    | 1.4.x (`packageManager` in `package.json`) | **Package manager only**: installs, workspaces, running scripts. Code runs on Node. |
| Nx                     | 23.x                                       | Task runner and cache (`nx run-many`, `dependsOn: ^build`)                          |
| TypeScript             | 6.0.x                                      | Pinned below 7 because typescript-eslint doesn't support TypeScript 7 yet           |
| Docker                 | 24+                                        | Postgres, Redis and RustFS locally; Testcontainers in integration tests (planned)   |
| Flutter                | 3.38.x (Dart 3.10)                         | Driver app only                                                                     |
| Android Studio / Xcode | latest                                     | Driver app emulator/simulator builds                                                |

### Why the Node apps build with `tsc`

NestJS 12 is ESM-only and relies on `emitDecoratorMetadata` for dependency injection. esbuild-based runners (tsx, `bun run file.ts`) don't emit that metadata. So `apps/api` and `apps/workers` compile with `tsc`, and `dev` runs `tsc --watch` next to `node --watch dist/main.js`.

### How workspace libs are consumed

Each lib's `package.json` exports three conditions:

| Condition | Target            | Used by                                                                               |
| --------- | ----------------- | ------------------------------------------------------------------------------------- |
| `source`  | `src/index.ts`    | Vite (admin web) and its type-checking, via `resolve.conditions` / `customConditions` |
| `types`   | `dist/index.d.ts` | `tsc` in the Node apps                                                                |
| `default` | `dist/index.js`   | Node at runtime                                                                       |

Nx builds a project's libs before anything that depends on them, so `dist/` is always fresh when a Node app needs it.

Bun installs workspaces in **isolated** mode: an app can only import the packages it lists in its own `package.json`, including `@types/node`.

## Local services

`bun run infra:up` starts them; `docker-compose.yml` defines them.

| Service                     | Address                                               | Credentials (dev only)                                                    |
| --------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------- |
| PostgreSQL 16 + PostGIS 3.5 | `localhost:5433`                                      | `taxcy` / `taxcy`, database `taxcy`                                       |
| Redis 8                     | `localhost:6380`                                      | —                                                                         |
| RustFS (S3 API)             | <http://localhost:9000>                               | `taxcy` / `taxcy-dev-secret`, bucket `taxcy-media` (created by `s3-init`) |
| RustFS console              | <http://localhost:9001/rustfs/console/>               | same                                                                      |
| API                         | <http://localhost:3000> (`GET /health/live`)          | —                                                                         |
| Admin web                   | <http://localhost:5173> (proxies `/api/*` to the API) | —                                                                         |
| API docs (planned, M0.2)    | <http://localhost:3000/docs>                          | —                                                                         |
| Bull Board (planned, M0.4)  | <http://localhost:3001/queues>                        | —                                                                         |

The host ports deliberately avoid 5432 and 6379. Without this, a natively installed Postgres or another project's Redis could silently answer on `localhost` instead of Taxcy's containers. Every port can be overridden in `.env` (`POSTGRES_PORT`, `REDIS_PORT`, `S3_PORT`, `S3_CONSOLE_PORT`).

Local S3 runs on **RustFS** because MinIO no longer publishes container images. The API only talks the generic S3 protocol (AWS SDK), so any S3-compatible store works in other environments.

## Environment variables

`.env.example` holds the variables in use today. The API's typed config module (M0.2) validates everything at startup with Zod and exits with a readable error if anything is missing or malformed. Never hardcode secrets.

| Variable                                              | Default (dev)                                 | Purpose                                  |
| ----------------------------------------------------- | --------------------------------------------- | ---------------------------------------- |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | `taxcy`                                       | Container setup                          |
| `POSTGRES_PORT`                                       | `5433`                                        | Host port for Postgres                   |
| `DATABASE_URL`                                        | `postgres://taxcy:taxcy@localhost:5433/taxcy` | API connection                           |
| `REDIS_PORT` / `REDIS_URL`                            | `6380` / `redis://localhost:6380`             |                                          |
| `S3_ENDPOINT`                                         | `http://localhost:9000`                       |                                          |
| `S3_PORT` / `S3_CONSOLE_PORT`                         | `9000` / `9001`                               | Host ports for RustFS                    |
| `S3_REGION`                                           | `ap-south-1`                                  |                                          |
| `S3_BUCKET`                                           | `taxcy-media`                                 |                                          |
| `S3_ACCESS_KEY_ID` / `S3_SECRET_ACCESS_KEY`           | `taxcy` / `taxcy-dev-secret`                  | Also the RustFS root credentials locally |
| `PORT`                                                | `3000`                                        | API port                                 |

Added by later milestones (planned):

| Variable                                                                                   | Milestone   | Purpose                                                                       |
| ------------------------------------------------------------------------------------------ | ----------- | ----------------------------------------------------------------------------- |
| `NODE_ENV`, `LOG_LEVEL`, `SENTRY_DSN`                                                      | M0.2        | Runtime mode, pino level, Sentry (disabled when empty)                        |
| `DATABASE_MIGRATION_URL`                                                                   | M0.2        | Owner role for migrations; `DATABASE_URL` becomes the RLS-restricted app role |
| `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `JWT_ACCESS_TTL` (15m), `JWT_REFRESH_TTL` (30d) | M0.3        | Tokens                                                                        |
| `OTP_TTL_SECONDS` (300), `OTP_MAX_ATTEMPTS` (5), `SMS_PROVIDER` (`console`)                | M0.3        | OTP login                                                                     |
| `S3_PUBLIC_ENDPOINT`, `S3_UPLOAD_URL_TTL_SECONDS` (600)                                    | M0.4        | Host used in signed URLs (your LAN IP for a physical phone); URL lifetime     |
| `OCR_PROVIDER` (`stub`), `MAPS_PROVIDER` (`stub`), `MAP_TILE_URL`                          | M0.4 / M1.7 | Provider selection                                                            |
| `GPS_RETENTION_MONTHS` (12)                                                                | M1.5        | Older GPS partitions are dropped                                              |

## Scripts

Run from the repo root with `bun run <script>`.

| Script                                    | What it does                                                                             |
| ----------------------------------------- | ---------------------------------------------------------------------------------------- |
| `dev`                                     | API + workers + admin web in watch mode (builds libs first)                              |
| `dev:api` / `dev:workers` / `dev:admin`   | One app only                                                                             |
| `infra:up` / `infra:down` / `infra:reset` | Start, stop, or wipe and restart Postgres, Redis and RustFS                              |
| `lint`                                    | ESLint on TypeScript projects; `dart format` check + `flutter analyze` on the driver app |
| `typecheck`                               | `tsc` for every TypeScript project                                                       |
| `test`                                    | Vitest for TypeScript projects; `flutter test` for the driver app                        |
| `build`                                   | Build every project                                                                      |
| `format` / `format:check`                 | Prettier (Dart files are formatted by `dart format`)                                     |
| `verify`                                  | `format:check`, then lint, typecheck, test and build: everything CI runs                 |

Run any target for one project: `bunx nx run @taxcy/domain:test`. Nx caches results, so unchanged projects are skipped; use `--skip-nx-cache` to force a run.

Planned scripts:

| Script                       | Milestone | What it does                                                                       |
| ---------------------------- | --------- | ---------------------------------------------------------------------------------- |
| `db:generate`                | M0.2      | `prisma generate` (client + TypedSQL)                                              |
| `db:migration <name>`        | M0.2      | `prisma migrate dev --create-only`: create a migration for review and hand-editing |
| `db:migrate`                 | M0.2      | `prisma migrate deploy`                                                            |
| `db:drift`                   | M0.2      | Fail if `schema.prisma` and the migrations disagree (also in CI)                   |
| `db:studio`                  | M0.2      | Prisma Studio                                                                      |
| `db:seed` / `db:reset`       | M0.5      | Load sample data / drop, migrate and seed                                          |
| `api:openapi` / `api:client` | M0.2      | Write `openapi.json`; regenerate the TypeScript client (and the Dart client, M1.8) |
| `test:integration`           | M0.2      | API tests against Testcontainers (PostGIS, Redis, RustFS)                          |
| `test:e2e:driver`            | M1.9      | Maestro start-trip → end-trip flow on an emulator                                  |

## Projects

| Project             | Path              | Stack                                                                                     |
| ------------------- | ----------------- | ----------------------------------------------------------------------------------------- |
| `@taxcy/api`        | `apps/api`        | NestJS 12 (ESM), built with `tsc`                                                         |
| `@taxcy/workers`    | `apps/workers`    | Node process; BullMQ from M0.4                                                            |
| `@taxcy/admin-web`  | `apps/admin-web`  | React 19, Vite 8, Tailwind 4                                                              |
| `@taxcy/driver-app` | `apps/driver-app` | Flutter (Dart package `taxcy_driver`); `package.json` only exposes Flutter commands to Nx |
| `@taxcy/contracts`  | `libs/contracts`  | Zod 4 schemas                                                                             |
| `@taxcy/domain`     | `libs/domain`     | Pure TypeScript                                                                           |
| `@taxcy/api-client` | `libs/api-client` | Generated TypeScript client (M0.2)                                                        |
| `@taxcy/ui`         | `libs/ui`         | Shared React UI (shadcn/ui in M1.7)                                                       |
| `@taxcy/db`         | `libs/db`         | Prisma schema, migrations, client (M0.2)                                                  |

## Driver app (Flutter)

```bash
cd apps/driver-app
flutter pub get
flutter run                     # choose an emulator, simulator or device
flutter test
flutter analyze --fatal-infos
```

Analysis is strict (`strict-casts`, `strict-inference`, `strict-raw-types`), which is the Dart equivalent of "no `any`".

From M1.8, the API base URL is passed at build time:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:3000     # Android emulator
flutter run --dart-define=API_URL=http://localhost:3000    # iOS simulator
flutter run --dart-define=API_URL=http://<LAN-IP>:3000     # physical device
```

The driver app can't import `libs/contracts` or `libs/domain` (they're TypeScript). It gets:

- **API types:** a Dart client generated from the same OpenAPI document as `libs/api-client`.
- **Trip state machine:** the transition table is exported from `libs/domain` as JSON. The Dart app loads that JSON, and a shared fixture test fails if the two implementations disagree.

## Testing

- **Unit (`libs/domain`, `libs/contracts`)**: pure functions with table-driven Vitest tests. The worked examples in [`docs/domain`](domain/) become test cases.
- **Integration (`apps/api`, planned M0.2)**: tests boot Nest against Testcontainers (PostGIS, Redis, RustFS), apply migrations, and drive HTTP. They cover the trip lifecycle, idempotent replays, sync conflicts and tenant isolation.
- **Driver app**: `flutter test` widget and unit tests; one Maestro flow (M1.9).

## Conventions

- **Layering:** controller (HTTP + Zod parse) → service (orchestration, transactions) → repository (Prisma, tenant-scoped) → `libs/domain` (pure rules). Controllers contain no business logic.
- **Types:** strict TypeScript (`strictTypeChecked` lint preset, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`). No `any`; use `unknown` and narrow with Zod.
- **Validation:** every request, env var, queue payload and sync record is parsed with a schema from `libs/contracts`.
- **Money and time:** paise as `bigint` in the DB and `number` in TypeScript (safe below ₹90 trillion). UTC everywhere; convert to IST only for display and business dates (`istBusinessDate` in `libs/domain`).
- **Migrations:** create them with `--create-only` and read the SQL before applying it. Prisma will drop objects it doesn't model, such as partitions, exclusion constraints and RLS policies.
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/), small and focused: `feat(fuel): compute cycles on full-tank fill`.
- **Docs:** a milestone isn't done until the docs it affects are updated.

## CI

`.github/workflows/ci.yml` runs on pushes to `main` and on pull requests (<https://github.com/hritambh/taxcy>):

| Job                | Steps                                                                                                                 |
| ------------------ | --------------------------------------------------------------------------------------------------------------------- |
| TypeScript         | `bun install --frozen-lockfile`, `format:check`, `nx run-many -t lint typecheck test build` (excludes the driver app) |
| Flutter driver app | `flutter pub get`, `dart format` check, `flutter analyze --fatal-infos`, `flutter test` (Flutter 3.38.5)              |
