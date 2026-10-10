# API usage

The API is served under `/v1`: <http://localhost:3000/v1>. Interactive docs are at <http://localhost:3000/docs>, and the OpenAPI document is at <http://localhost:3000/v1/openapi.json>.

Every route is declared once, as a Zod contract in `libs/contracts`. The API binds its handlers to those contracts: requests are validated on the way in, responses are encoded and stripped on the way out, and startup fails if a contract has no handler. The OpenAPI document and the generated TypeScript client (`libs/api-client`) are built from the same contracts.

## Authentication

```http
POST /v1/auth/otp/request
{ "phone": "+919812345678" }
→ 202 { "expiresInSeconds": 300, "resendAfterSeconds": 30 }

POST /v1/auth/otp/verify
{ "phone": "+919812345678", "code": "123456", "deviceId": "<uuid>", "platform": "android" }
→ 200 {
  "accessToken": "…", "accessTokenExpiresAt": "…",
  "refreshToken": "…", "refreshTokenExpiresAt": "…",
  "user": { "id": "…", "phone": "+919812345678", "name": null },
  "activeOrgId": "…" | null,
  "memberships": [{ "orgId": "…", "orgName": "Sharma Travels", "orgKind": "fleet", "roles": ["owner"] }]
}
```

- **Codes.** In development the OTP is printed in the API log (`otp.issued phone=… code=…`). Each code works once and allows 5 attempts; requests are rate-limited per phone (one per 30 s, 3 per 10 min, 10 per day) and per IP (`OTP_IP_LIMIT_PER_HOUR`). A limited request returns `429` with `details.retryAfterSeconds`.
- **Tokens.** Send `Authorization: Bearer <accessToken>`. Access tokens last 15 minutes and carry the active org and your roles in it. Refresh tokens are rotated on every `POST /auth/refresh`. Presenting an already-rotated refresh token revokes every token in its family.
- **First login creates the user.** Users with no org call `POST /orgs` (`fleet`, or `dco` for an owner-driver) and get a session scoped to the new org. Invited drivers' memberships activate on their first sign-in. `POST /auth/switch-org` moves a session to another org you belong to.

## Conventions

| Topic          | Rule                                                                                                                                                                                      |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Money          | Integer **paise** (`350000` = ₹3,500)                                                                                                                                                     |
| Timestamps     | ISO 8601 with offset, e.g. `2026-10-09T03:30:00Z`                                                                                                                                         |
| Calendar dates | `YYYY-MM-DD` in IST (settlement days, document expiry)                                                                                                                                    |
| Fuel quantity  | Integer millilitres (petrol, diesel) or grams (CNG)                                                                                                                                       |
| IDs            | UUIDs. Records created on the driver app (media, odometer readings, fills, charges, collections, cancellation requests, GPS points) use the **client's** UUID, which makes re-sends safe. |
| Device time    | Commands take `occurredAt`, when it happened on the phone, which may be long before it syncs. The server records its own time too.                                                        |

## Idempotency

- **Client-created records** are idempotent on their `id`. Re-sending the same body returns the original result. Re-using an id with different values returns `409 IDEMPOTENCY_CONFLICT`.
- **Commands** (trip transitions, cancellation decisions, settle) require an `Idempotency-Key: <uuid>` header. A replay with the same key and body returns the stored response with `Idempotent-Replay: true`. The same key with a different body returns `409 IDEMPOTENCY_CONFLICT`. For trip commands the key is also the `trip_events` id, so a command can never apply twice.

## Errors

```json
{
  "error": {
    "code": "ILLEGAL_TRANSITION",
    "message": "Cannot end a trip that is assigned",
    "details": { "allowed": ["reassign", "unassign", "start", "cancel"], "status": "assigned" },
    "requestId": "b7e2…"
  }
}
```

| HTTP | Codes                                                                                                                                                                                       |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 400  | `VALIDATION_FAILED` (`details.issues` lists each problem), `IDEMPOTENCY_KEY_REQUIRED`                                                                                                       |
| 401  | `UNAUTHENTICATED`, `TOKEN_EXPIRED`, `OTP_INVALID` (`details.attemptsLeft`), `OTP_EXPIRED`                                                                                                   |
| 403  | `FORBIDDEN_ROLE`, `NO_ACTIVE_ORG`                                                                                                                                                           |
| 404  | `NOT_FOUND`, also returned for other orgs' records, so existence is never leaked                                                                                                            |
| 409  | `ILLEGAL_TRANSITION`, `TRIP_CANCELLED`, `TRIP_REASSIGNED`, `VEHICLE_BUSY`, `DRIVER_BUSY`, `CANCELLATION_PENDING`, `ALREADY_SETTLED`, `IDEMPOTENCY_CONFLICT`, `VERSION_CONFLICT`, `CONFLICT` |
| 422  | `FUEL_TYPE_MISMATCH`, `ODOMETER_BEFORE_START`, `UPLOAD_NOT_FOUND`, `UPLOAD_MISMATCH`                                                                                                        |
| 429  | `RATE_LIMITED`                                                                                                                                                                              |

Every response carries `X-Request-Id`; send your own to correlate logs.

## Uploading a photo

1. `POST /v1/media` with `{ id, kind, contentType, sha256, byteSize, capturedAt, location?, isMockLocation?, deviceId? }`. The response has `uploadUrl` and `uploadHeaders`.
2. `PUT` the bytes to `uploadUrl`, sending `uploadHeaders`.
3. `POST /v1/media/{id}/complete`. The server re-hashes the object and rejects a mismatch with `422 UPLOAD_MISMATCH`.
4. Use the media id in odometer readings (`odometer.mediaId`) and fills (`receiptMediaId`). Registering (step 1) is enough for a command to reference the photo; the upload can finish later.

Photos are OCR'd in the background. A disagreement between typed and OCR values creates a review item and never blocks the driver.

## Endpoints

### Health

| Endpoint            | Who    | Idempotency-Key | What it does                                     |
| ------------------- | ------ | --------------- | ------------------------------------------------ |
| `GET /health/live`  | public |                 | Process is up                                    |
| `GET /health/ready` | public |                 | Dependencies (Postgres, Redis, S3) are reachable |

### Auth and orgs

| Endpoint                 | Who       | Idempotency-Key | What it does                                                          |
| ------------------------ | --------- | --------------- | --------------------------------------------------------------------- |
| `POST /auth/otp/request` | public    |                 | Send a one-time login code by SMS                                     |
| `POST /auth/otp/verify`  | public    |                 | Exchange a login code for a session (creates the user on first login) |
| `POST /auth/refresh`     | public    |                 | Rotate the refresh token and get a new access token                   |
| `POST /auth/logout`      | public    |                 | Revoke the refresh token (and every token rotated from it)            |
| `POST /auth/switch-org`  | signed in |                 | Get a session scoped to another org you belong to                     |
| `GET /me`                | signed in |                 | The signed-in user and their memberships                              |
| `PATCH /me`              | signed in |                 | Update your profile                                                   |
| `POST /orgs`             | signed in |                 | Create an organization; you become its owner (and driver, for a DCO)  |

### Members

| Endpoint                       | Who            | Idempotency-Key | What it does                                                                             |
| ------------------------------ | -------------- | --------------- | ---------------------------------------------------------------------------------------- |
| `GET /members`                 | owner, manager |                 | People with access to the org, with their roles                                          |
| `POST /members/managers`       | owner          |                 | Give someone manager access by phone (managers can't change settings or pay rules)       |
| `DELETE /members/{id}/manager` | owner          |                 | Take away manager access; other roles stay, and a member with no roles left is suspended |

Drivers are added with `POST /drivers`, which also creates their driver profile. A removed manager keeps their current access token until it expires (at most 15 minutes).

### Media

| Endpoint                    | Who                    | Idempotency-Key | What it does                                                             |
| --------------------------- | ---------------------- | --------------- | ------------------------------------------------------------------------ |
| `POST /media`               | owner, manager, driver |                 | Register a captured photo and get a signed upload URL (idempotent on id) |
| `POST /media/{id}/complete` | owner, manager, driver |                 | Confirm the upload; the server verifies size and checksum                |
| `GET /media/{id}/url`       | owner, manager, driver |                 | Short-lived signed URL to view an uploaded object                        |

### Fleet

| Endpoint                     | Who                    | Idempotency-Key | What it does                                                                   |
| ---------------------------- | ---------------------- | --------------- | ------------------------------------------------------------------------------ |
| `GET /vehicles`              | owner, manager, driver |                 | Vehicles in the org                                                            |
| `POST /vehicles`             | owner, manager         |                 | Add a vehicle                                                                  |
| `GET /vehicles/{id}`         | owner, manager, driver |                 | A vehicle                                                                      |
| `PATCH /vehicles/{id}`       | owner, manager         |                 | Update a vehicle                                                               |
| `GET /vehicle-models`        | owner, manager, driver |                 | Known vehicle models (used to seed fuel baselines)                             |
| `GET /drivers`               | owner, manager         |                 | Drivers in the org                                                             |
| `POST /drivers`              | owner, manager         |                 | Invite a driver by phone; they sign in to the app with that number             |
| `GET /drivers/{id}`          | owner, manager         |                 | A driver                                                                       |
| `PATCH /drivers/{id}`        | owner, manager         |                 | Update a driver                                                                |
| `PUT /drivers/{id}/pay-rule` | owner                  |                 | Override a driver's pay rule (null = use the org default)                      |
| `GET /documents`             | owner, manager         |                 | Current documents (renewed ones are hidden unless includeSuperseded)           |
| `POST /documents`            | owner, manager         |                 | Add a document to a vehicle (RC, insurance, permit, PUC) or a driver (licence) |
| `POST /documents/{id}/renew` | owner, manager         |                 | Replace a document with its renewed copy (keeps history, clears its alerts)    |

### Settings

| Endpoint                   | Who            | Idempotency-Key | What it does                                                     |
| -------------------------- | -------------- | --------------- | ---------------------------------------------------------------- |
| `GET /settings/audit`      | owner, manager |                 | Fuel and distance audit thresholds                               |
| `PATCH /settings/audit`    | owner          |                 | Change audit thresholds                                          |
| `GET /settings/driver-pay` | owner, manager |                 | Default driver pay rule                                          |
| `PUT /settings/driver-pay` | owner          |                 | Change the default driver pay rule (affects unsettled days only) |

### Trips

| Endpoint                                    | Who                    | Idempotency-Key | What it does                                                                                                                                     |
| ------------------------------------------- | ---------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `GET /trips`                                | owner, manager         |                 | Trips, newest scheduled first                                                                                                                    |
| `POST /trips`                               | any member             |                 | Create a trip (optional `includedKm`; idempotent on optional client `id`). Drivers create trips assigned to themselves, in the vehicle they pick |
| `GET /trips/{id}`                           | owner, manager, driver |                 | A trip (drivers see only their own)                                                                                                              |
| `PATCH /trips/{id}`                         | owner, manager         |                 | Edit trip details before it starts                                                                                                               |
| `GET /trips/{id}/events`                    | owner, manager, driver |                 | Every transition, with actor and device/server times                                                                                             |
| `POST /trips/{id}/assign`                   | owner, manager         | required        | Assign or reassign a vehicle and driver                                                                                                          |
| `POST /trips/{id}/unassign`                 | owner, manager         | required        | Remove the assignment                                                                                                                            |
| `POST /trips/{id}/start`                    | owner, manager, driver | required        | Start the trip with an odometer reading                                                                                                          |
| `POST /trips/{id}/end`                      | owner, manager, driver | required        | End the trip with an odometer reading, plus what was collected and spent                                                                         |
| `POST /trips/{id}/cancel`                   | owner, manager         | required        | Cancel a trip that has not started                                                                                                               |
| `POST /trips/{id}/cancellation-requests`    | owner, manager, driver | required        | Ask to cancel a started trip (needs a reason and the end odometer; staff approve)                                                                |
| `POST /cancellation-requests/{id}/approve`  | owner, manager         | required        | Approve a cancellation request; optionally charge a cancellation fare                                                                            |
| `POST /cancellation-requests/{id}/reject`   | owner, manager         | required        | Reject a cancellation request; the trip continues                                                                                                |
| `POST /cancellation-requests/{id}/withdraw` | owner, manager, driver | required        | Withdraw your cancellation request                                                                                                               |
| `POST /trips/{id}/charges`                  | owner, manager, driver |                 | Add a toll, parking, allowance or other charge (driver or staff; idempotent on id)                                                               |
| `POST /trips/{id}/charges/{chargeId}/void`  | owner, manager         |                 | Void a wrong charge before the day is settled                                                                                                    |
| `GET /me/trips`                             | driver                 |                 | The signed-in driver's current and recent trips (for the app to sync)                                                                            |

### Fuel

| Endpoint                         | Who                    | Idempotency-Key | What it does                                                                     |
| -------------------------------- | ---------------------- | --------------- | -------------------------------------------------------------------------------- |
| `POST /fuel-fills`               | owner, manager, driver |                 | Record a fuel fill (idempotent on id; fills may arrive late from offline phones) |
| `GET /fuel-fills`                | owner, manager         |                 | Fuel fills, newest first                                                         |
| `POST /fuel-fills/{id}/void`     | owner, manager         |                 | Void a wrong fill; the vehicle audit is recomputed                               |
| `GET /vehicles/{id}/fuel-cycles` | owner, manager         |                 | A vehicle's fuel cycles, baseline and verdicts                                   |

### Telemetry

| Endpoint                         | Who                    | Idempotency-Key | What it does                                                              |
| -------------------------------- | ---------------------- | --------------- | ------------------------------------------------------------------------- |
| `POST /trips/{id}/gps-batches`   | owner, manager, driver |                 | Upload recorded GPS points for a trip (deduplicated by point id)          |
| `GET /trips/{id}/route`          | owner, manager, driver |                 | The cleaned GPS route of a trip (bad points removed, thinned for display) |
| `GET /trips/{id}/distance-check` | owner, manager         |                 | Odometer vs GPS distance verdict (null until the trip ends)               |

### Money

| Endpoint                                             | Who                    | Idempotency-Key | What it does                                                         |
| ---------------------------------------------------- | ---------------------- | --------------- | -------------------------------------------------------------------- |
| `POST /trips/{id}/collections`                       | owner, manager, driver |                 | Record what the customer paid (idempotent on id)                     |
| `GET /settlements`                                   | owner, manager         |                 | Each driver's settlement for an IST day (drafts are computed live)   |
| `GET /settlements/{date}/drivers/{driverId}`         | owner, manager         |                 | A driver’s settlement for a day, with every item it covers           |
| `POST /settlements/{date}/drivers/{driverId}/settle` | owner, manager         | required        | Mark the day settled: freezes the totals and settles its ended trips |

### Alerts and review

| Endpoint                          | Who            | Idempotency-Key | What it does                                                                                              |
| --------------------------------- | -------------- | --------------- | --------------------------------------------------------------------------------------------------------- |
| `GET /alerts`                     | owner, manager |                 | Alerts inbox, newest first                                                                                |
| `GET /alerts/summary`             | owner, manager |                 | Open alert and review counts, for badges                                                                  |
| `PATCH /alerts/{id}`              | owner, manager |                 | Acknowledge, resolve or dismiss an alert (dismissing a fuel alert as a false alarm retrains the baseline) |
| `GET /review-items`               | owner, manager |                 | Review queue, oldest first                                                                                |
| `POST /review-items/{id}/resolve` | owner, manager |                 | Decide a review item; using the OCR or a corrected value updates the record and re-runs its checks        |

### Text in the user's language

The API doesn't translate. Where it produces text, it also sends the data behind it so each app can phrase it in the user's language:

- **Alerts** have `message: { key, params }` next to the English `title` and `explanation`. `key` is the alert kind (`fuel_efficiency_low`, `fuel_cost_high`, `odo_gps_mismatch`, `document_expiring`, `document_expired`, `cancellation_requested`); `params` holds pre-rounded numbers, IST dates (`YYYY-MM-DD`) and names. Alerts raised before messages existed have `message: null`; show the English text for those.
- **Settlement lines** have `item` (the trip, charge, collection or fuel fill the line is for) next to the English `description`.
- **Review items** for implausible fuel cycles have `context.reasonCode` next to the English `context.reason`.
- **Errors** have a stable `error.code`; translate by code and fall back to `error.message`.

## Generated TypeScript client

```ts
import { createApiClient } from '@taxcy/api-client';

const api = createApiClient({ baseUrl: '/api/v1', getAccessToken: () => session.accessToken });

const { data, error } = await api.POST('/trips/{id}/assign', {
  params: { path: { id: tripId }, header: { 'Idempotency-Key': crypto.randomUUID() } },
  body: { vehicleId, driverId },
});
```

After changing a contract, run `bun run api:client` (it rebuilds `libs/api-client/openapi.json` and `src/schema.ts`). CI fails if the committed client is stale.
