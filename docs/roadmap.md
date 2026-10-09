# Roadmap

Each milestone ends with lint, typecheck and tests passing, a summary of what changed, a list of shortcuts and TODOs, and a review stop.

## Phase 0: Foundations

- [x] **M0.1 Scaffold:** Bun workspaces + Nx; all apps/libs stubbed (Flutter driver app); ESLint (no `any`), Prettier, strict TS 6, Vitest, strict Dart analysis; GitHub Actions (TypeScript + Flutter jobs); docker-compose (PostGIS 16, Redis, RustFS + bucket init); `bun run dev`
- [x] **M0.2 API platform:** typed Zod config; pino + request IDs; health checks; Sentry hook; `libs/db` with Prisma + full schema migration (hand-edited SQL for PostGIS, exclusion constraints, partitions, RLS) + drift check; tenant context + base repository; outbox; OpenAPI → `libs/api-client`; Testcontainers harness
- [x] **M0.3 Identity:** OTP (`SmsProvider` + console stub), Redis rate limits, JWT access/refresh with rotation, orgs, memberships, role guard, org switch
- [x] **M0.4 Media + workers:** signed uploads, upload verification, workers app (BullMQ, outbox relay, cron), `OcrProvider` stub → review items, idempotency interceptor
- [x] **M0.5 Seed** (built after M1.6, so it runs through the real audit logic)**:** 1 org, 3 vehicles (diesel, CNG, petrol), 3 drivers, about 2 months of fills including a suspicious cycle, trips in every state with GPS tracks

## Phase 1: Fleet audit MVP

- [x] **M1.1 `libs/domain` (test-first):** fuel cycles, EWMA baseline, sigma/percent flags, bi-fuel cost/km track, driver pay rules, GPS filtering/distance/coverage, odometer-vs-GPS verdict, trip state machine, settlement and pay math, alert explanations
- [x] **M1.2 Fleet:** vehicles, drivers (invite by phone), documents (+ renew), daily expiry job
- [x] **M1.3 Trips:** CRUD, assign/reassign/unassign with conflict errors, transitions + `trip_events`, odometer readings, charges (driver or owner), cancellation (direct, or request → approve/reject once started), conflict semantics
- [x] **M1.4 Fuel:** fills, cycle recomputation for out-of-order fills, baselines, alerts and review items
- [x] **M1.5 Telemetry:** batched GPS ingest, partition maintenance, PostGIS distance check
- [x] **M1.6 Money + inbox:** collections, daily settlement (draft → settled, carry-forward), alerts and review queue APIs
- [ ] **M1.7 Admin web:** login; fleet CRUD; trips (create/assign/list/detail with photos and map); fuel cycles chart; alerts; review queue; settlements
- [ ] **M1.8 Driver app (Flutter):** login; my trips; start (odometer camera); live trip; end (odometer + collections); fuel fill (receipt camera, full-tank toggle); offline indicator + sync engine
- [ ] **M1.9 End-to-end tests:** integration tests for trip lifecycle, idempotent and conflicting sync, tenant isolation; Maestro start → end flow; docs pass

## Later (out of scope for now)

- Passenger app
- Return-leg matching
- OTA partner API
- Real SMS/OCR/maps/payment providers
- Device attestation
- Push/WhatsApp notifications for alerts
- Rate-card fare engine
