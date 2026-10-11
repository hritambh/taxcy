# Taxcy

Fleet audit and intercity cab operations for small fleet owners (2–15 cars) and owner-drivers (DCOs) in India.

Taxcy gives a fleet owner a trustworthy picture of what their cars and drivers actually did: trips with photo-verified odometer readings, fuel fills audited against each vehicle's own history, GPS-vs-odometer distance checks, and a daily cash settlement per driver.

> **Status: M0.1–M1.8 and M1.10 done.** The API, workers, admin console and the Flutter app (offline-first driver screens plus an owner/manager mode, in English and Hindi) are built, and a demo fleet can be seeded. Next up is M1.9 (end-to-end tests). See [`docs/roadmap.md`](docs/roadmap.md) for progress and [`docs/decisions.md`](docs/decisions.md) for design decisions.

---

## What it does

| For the fleet owner (admin web)                                                                                  | For the driver (mobile app)                                |
| ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Manage vehicles, drivers and their documents (RC, insurance, permit, PUC, DL)                                    | Log in with phone + OTP                                    |
| Get alerts 30 / 7 / 1 days before a document expires                                                             | See assigned trips                                         |
| Create, assign and track trips; see photos and the GPS route                                                     | Start/end a trip with an odometer photo + typed reading    |
| See fuel efficiency (or cost per km for petrol + CNG cars) per vehicle, cycle by cycle, against its own baseline | Log fuel fills with a receipt photo and a full-tank toggle |
| Get plain-language alerts for suspicious fuel use or inflated odometer readings                                  | Log cash / UPI / card collections                          |
| Review OCR mismatches in a review queue                                                                          | Request cancellation of a running trip                     |
| Approve or reject trip cancellations                                                                             | Add tolls, parking and other charges                       |
| Configure driver pay rules                                                                                       | Keep working offline; sync when back online                |
| Settle each driver's day: fare, cash, online, expenses, net payable                                              |                                                            |

Out of scope for now: the passenger app, return-leg matching and the OTA partner API. The schema leaves room for them (see [`docs/database.md`](docs/database.md#future-proofing)).

## Repository layout

```
apps/
  api/          NestJS modular monolith (HTTP API)
  workers/      BullMQ workers: OCR, fuel cycles, GPS distance, document expiry, outbox relay
  admin-web/    React + Vite admin console for owners and managers
  driver-app/   Flutter app "Taxcy": offline-first driver screens, owner mode, English + Hindi
libs/
  db/           Prisma schema, migrations, TypedSQL queries and client (shared by api + workers)
  contracts/    Zod schemas + inferred types shared by API and clients
  domain/       Pure business logic (fuel audit, trip state machine, settlement math)
  api-client/   Typed client generated from the API's OpenAPI document
  ui/           Shared React UI components (shadcn/ui based)
docs/           Architecture, domain rules, database, usage guides
```

## Tech stack

| Concern        | Choice                                                                                                             |
| -------------- | ------------------------------------------------------------------------------------------------------------------ |
| Monorepo       | Bun workspaces (package manager) + Nx (task runner); Node 24 runtime                                               |
| API            | NestJS, Prisma ORM, Zod                                                                                            |
| Database       | PostgreSQL 16 + PostGIS + btree_gist                                                                               |
| Jobs / cache   | Redis + BullMQ (separate `workers` app, same codebase)                                                             |
| Object storage | S3-compatible, signed upload URLs (RustFS locally)                                                                 |
| Admin web      | React, Vite, TanStack Query, React Router, Tailwind, shadcn/ui, MapLibre                                           |
| App            | Flutter: camera, geolocator (foreground service), drift (SQLite), gen-l10n (English, Hindi), flutter_map, fl_chart |
| Observability  | pino structured logs, request IDs, health checks, Sentry                                                           |
| Testing        | Vitest, flutter_test, Testcontainers, Maestro                                                                      |

## Running it locally

**Step-by-step guide: [`docs/getting-started.md`](docs/getting-started.md).** It covers installing the tools, starting the infrastructure, seeding, logging in, driving a trip in the driver app, offline mode, tests and troubleshooting.

The short version:

```bash
bun install
cp .env.example .env
bun run infra:up              # Postgres+PostGIS :5433, Redis :6380, RustFS :9000
bun run dev                   # api :3000, workers, admin web :5173
```

Before the first `dev`, run `bun run db:migrate && bun run db:seed` to create the schema and the demo fleet. Then sign in at <http://localhost:5173> with a seeded phone number (e.g. `9000000001`, the owner); the OTP is printed in the `bun run dev` log. To try the driver app without an emulator, run `bun run dev:driver-web` in a second terminal and sign in at <http://localhost:5174> as a driver (e.g. `9000000011`), or as the owner (`9000000001`) for owner mode.

## Documentation

| Doc                                                             | What's in it                                                    |
| --------------------------------------------------------------- | --------------------------------------------------------------- |
| [Getting started](docs/getting-started.md)                      | Step-by-step: run the backend, admin web and driver app locally |
| [Development guide](docs/development.md)                        | Local setup, env vars, scripts, testing, conventions            |
| [Architecture](docs/architecture.md)                            | Modules, layering, tenancy, jobs, idempotency, offline sync     |
| [Database](docs/database.md)                                    | ERD, table reference, constraints, partitioning                 |
| [Domain: trips](docs/domain/trips.md)                           | State machine, events, odometer evidence, conflicts             |
| [Domain: fuel audit](docs/domain/fuel-audit.md)                 | Full-tank cycles, baselines, flagging, worked examples          |
| [Domain: GPS telemetry](docs/domain/telemetry.md)               | Ingest, filtering, odometer-vs-GPS check                        |
| [Domain: collections and settlement](docs/domain/settlement.md) | Collections, daily settlement math                              |
| [Evidence and anti-tampering](docs/domain/evidence.md)          | Photo capture, signed uploads, OCR, review queue                |
| [Owner guide](docs/usage/owner-guide.md)                        | How a fleet owner uses the admin web                            |
| [Driver guide](docs/usage/driver-guide.md)                      | How a driver uses the mobile app                                |
| [API usage](docs/usage/api.md)                                  | Auth flow, headers, idempotency, errors, generated client       |
| [Decisions](docs/decisions.md)                                  | Open questions, accepted defaults, known risks                  |
| [Roadmap](docs/roadmap.md)                                      | Milestone checklist                                             |

## Conventions at a glance

- Money is integer **paise**. Times are `timestamptz` in UTC, shown in **IST**.
- Every org-scoped query is tenant-scoped centrally (guard + repository + Postgres RLS), never per endpoint.
- Domain logic is pure and lives in `libs/domain`. Controllers stay thin; services orchestrate; repositories do data access.
- No `any`. All external input is validated with Zod at the boundary.
- External providers (SMS, OCR, maps, payments) sit behind interfaces with stub implementations.
- Conventional commits (`feat(fuel): …`, `fix(trips): …`).
