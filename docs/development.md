# Development guide

> **(planned)** The commands, ports and variables below are the contract that milestones M0.1–M0.2 will implement. They don't work yet. When a milestone lands, the matching section here is updated and the "(planned)" marker removed.

## Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| Node.js | 24.x | Pinned via `.nvmrc` and `engines` |
| pnpm | 11.x | Pinned via `packageManager` in `package.json` |
| Docker | 24+ | Runs Postgres, Redis and MinIO locally, and Testcontainers in tests |
| Android Studio / Xcode | latest | Only for the driver app (Expo dev build) |
| Maestro CLI | latest | Only for the driver-app end-to-end flow |

## First-time setup

```bash
pnpm install
cp .env.example .env
docker compose up -d
pnpm db:migrate
pnpm db:seed
pnpm dev
```

`pnpm dev` starts the API, the workers and the admin web together. The driver app runs separately (see [Driver app](#driver-app)).

### Local services

| Service | URL / port | Credentials (dev only) |
| --- | --- | --- |
| API | <http://localhost:3000> | — |
| API docs (OpenAPI UI) | <http://localhost:3000/docs> | — |
| Admin web | <http://localhost:5173> | Seeded owner phone + OTP from API log |
| PostgreSQL + PostGIS | `localhost:5432` | `taxcy` / `taxcy`, db `taxcy` |
| Redis | `localhost:6379` | — |
| MinIO API | <http://localhost:9000> | `minioadmin` / `minioadmin` |
| MinIO console | <http://localhost:9001> | same |
| Bull Board (job dashboard) | <http://localhost:3001/queues> | — |

### Logging in locally

1. Open the admin web and enter a seeded phone number (printed by `pnpm db:seed`).
2. The dev SMS provider writes the OTP to the API log: `otp.issued phone=+91XXXXXXXXXX code=123456`.
3. Enter the code.

## Environment variables

All configuration is read once at startup by a typed config module and validated with Zod. The process exits with a readable error if anything is missing or malformed. Never hardcode secrets.

| Variable | Required | Default (dev) | Purpose |
| --- | --- | --- | --- |
| `NODE_ENV` | yes | `development` | `development` \| `test` \| `production` |
| `PORT` | no | `3000` | API port |
| `POSTGRES_PORT` | no | `5432` | Host port docker-compose maps Postgres to |
| `DATABASE_URL` | yes | `postgres://taxcy:taxcy@localhost:5432/taxcy` | App role (subject to RLS) |
| `DATABASE_MIGRATION_URL` | yes | owner role URL | Used only by migrations and seed |
| `REDIS_URL` | yes | `redis://localhost:6379` | BullMQ, OTPs, rate limits |
| `S3_ENDPOINT` | yes | `http://localhost:9000` | S3-compatible endpoint |
| `S3_REGION` | yes | `ap-south-1` | |
| `S3_BUCKET` | yes | `taxcy-media` | |
| `S3_ACCESS_KEY_ID` / `S3_SECRET_ACCESS_KEY` | yes | MinIO defaults | |
| `S3_PUBLIC_ENDPOINT` | no | `S3_ENDPOINT` | Host used in signed URLs; set to your LAN IP when testing on a physical phone |
| `S3_UPLOAD_URL_TTL_SECONDS` | no | `600` | Signed upload URL lifetime |
| `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | yes | dev values in `.env.example` | |
| `JWT_ACCESS_TTL` | no | `15m` | |
| `JWT_REFRESH_TTL` | no | `30d` | |
| `OTP_TTL_SECONDS` | no | `300` | |
| `OTP_MAX_ATTEMPTS` | no | `5` | Verify attempts per challenge |
| `SMS_PROVIDER` | no | `console` | `console` logs OTPs; real providers added later |
| `OCR_PROVIDER` | no | `stub` | |
| `MAPS_PROVIDER` | no | `stub` | Geocoding |
| `MAP_TILE_URL` | no | OSM tiles | Used by admin web (`VITE_MAP_TILE_URL`) |
| `SENTRY_DSN` | no | empty | Sentry disabled when empty |
| `LOG_LEVEL` | no | `debug` | pino level |
| `GPS_RETENTION_MONTHS` | no | `12` | Older partitions are dropped |

## Scripts

| Command | What it does |
| --- | --- |
| `pnpm dev` | API + workers + admin web in watch mode |
| `pnpm dev:api` / `pnpm dev:workers` / `pnpm dev:admin` | One app only |
| `pnpm lint` | ESLint across the workspace (Nx affected in CI) |
| `pnpm format` / `pnpm format:check` | Prettier |
| `pnpm typecheck` | `tsc --noEmit` for every project |
| `pnpm test` | Unit tests (Vitest) |
| `pnpm test:integration` | API integration tests against Testcontainers Postgres/Redis/MinIO |
| `pnpm test:e2e:driver` | Maestro start-trip → end-trip flow (needs a running emulator) |
| `pnpm db:generate` | `prisma generate` (client + TypedSQL); runs automatically after install |
| `pnpm db:migration <name>` | `prisma migrate dev --create-only`: creates a migration for review and hand-editing |
| `pnpm db:migrate` | `prisma migrate deploy`: applies migrations |
| `pnpm db:drift` | Fails if `schema.prisma` and the migrations disagree (also runs in CI) |
| `pnpm db:studio` | Prisma Studio |
| `pnpm db:seed` | Load sample data (idempotent; safe to re-run) |
| `pnpm db:reset` | Drop, migrate and seed (dev only) |
| `pnpm api:openapi` | Write `apps/api/openapi.json` |
| `pnpm api:client` | Regenerate `libs/api-client` from `openapi.json` |
| `pnpm verify` | lint + format:check + typecheck + test (what CI runs) |

## Seed data

`pnpm db:seed` creates:

- **Org:** one fleet org, with an owner and a manager.
- **Vehicles:** Toyota Innova Crysta (diesel), Maruti Dzire (CNG), Toyota Etios (petrol).
- **Drivers:** three drivers, each with a valid DL. One vehicle has insurance expiring within 7 days, so an alert shows up on day one.
- **Fuel history:** about 2 months of fills per vehicle, including partial fills and one cycle that looks like fuel theft.
- **Trips:** trips in every state, with GPS tracks; one has an odometer reading inflated relative to GPS.

The seed prints each user's phone number when it finishes.

## Driver app

The driver app uses background location and a custom camera flow, so it needs an **Expo dev build**. Expo Go is not supported.

```bash
pnpm --filter driver-app prebuild
pnpm --filter driver-app android     # or: ios
```

Point the app at your machine's API with `EXPO_PUBLIC_API_URL=http://<LAN-IP>:3000` (not `localhost` on a physical device or Android emulator; use `10.0.2.2` on the emulator).

To test offline behaviour, turn on airplane mode, start or end a trip, then turn it off. The sync indicator shows the pending outbox count draining.

## Testing

- **Unit (`libs/domain`)**: pure functions, no I/O. Every fuel, settlement and state-machine rule has table-driven tests with worked examples taken from [`docs/domain`](domain/).
- **Integration (`apps/api`)**: tests boot the Nest app against Testcontainers (PostGIS, Redis, MinIO), run migrations, and drive HTTP. They cover the trip lifecycle, idempotent replays, sync conflicts and tenant isolation (every module has a "can't see another org's data" test).
- **End-to-end (driver app)**: one Maestro flow, `apps/driver-app/e2e/start-end-trip.yaml`, with the camera mocked. It runs locally; it isn't in CI yet.

## Conventions

- **Layering:** controller (HTTP + Zod parse) → service (orchestration, transactions) → repository (Prisma, tenant-scoped) → `libs/domain` (pure rules). Controllers contain no business logic.
- **Migrations:** always create migrations with `--create-only` and read the SQL before applying it. Prisma will happily drop objects it doesn't model, such as partitions, exclusion constraints and RLS policies; `pnpm db:drift` catches this.
- **Types:** `strict` TypeScript with no `any`. Use `unknown` and narrow with Zod.
- **Validation:** every request body, query, param, env var, queue payload and client sync record is parsed with a schema from `libs/contracts`.
- **Money and time:** paise as `bigint` in the DB and `number` in TypeScript (safe below ₹90 trillion). UTC everywhere; convert to IST only for display and for "business date" calculations.
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/), small and focused, scoped by module: `feat(fuel): compute cycles on full-tank fill`.
- **Docs:** a milestone isn't done until the docs it affects are updated.

## CI

No remote is configured yet (decision D6); the workflow is committed and will run once one is added. It runs GitHub Actions on every push and PR: install (cached pnpm store) → `pnpm verify` → `pnpm test:integration` (Docker is available on `ubuntu-latest`). Nx `affected` keeps PR runs fast.
