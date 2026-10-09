# API usage

> **(planned)** This describes the HTTP contract that M0.2–M1.6 will implement. Once the API exists, the generated OpenAPI document at `/docs` is the authoritative reference.

Base URL (local): `http://localhost:3000/v1`

## Authentication

```http
POST /v1/auth/otp/request
{ "phone": "+919812345678" }
→ 202 { "challengeId": "…", "expiresInSeconds": 300 }

POST /v1/auth/otp/verify
{ "phone": "+919812345678", "code": "123456", "deviceId": "6f1c…", "platform": "android" }
→ 200 {
  "accessToken": "…", "refreshToken": "…",
  "activeOrgId": "…",
  "memberships": [{ "orgId": "…", "orgName": "Sharma Travels", "roles": ["owner"] }]
}

POST /v1/auth/refresh        { "refreshToken": "…" }            → 200 new pair
POST /v1/auth/switch-org     { "orgId": "…" }                   → 200 new pair for that org
POST /v1/auth/logout         { "refreshToken": "…" }            → 204
```

Send the access token on every request: `Authorization: Bearer <accessToken>`. The token carries the active org; all data you read or write is scoped to it.

OTP rate limits return `429` with a `Retry-After` header.

## Common headers

| Header | Direction | Purpose |
| --- | --- | --- |
| `Authorization` | request | `Bearer <access token>` |
| `Idempotency-Key` | request | UUID; required on command endpoints (trip transitions, settle) |
| `X-Request-Id` | both | Echoed or generated; include it in bug reports |
| `Idempotent-Replay` | response | `true` when the response is a stored replay |

## Idempotency

- **Create endpoints for offline records** (fills, collections, media, GPS batches): put your own UUID in the body as `id`. Re-sending the same request returns the original result. Re-sending the same `id` with a different body returns `409 IDEMPOTENCY_CONFLICT`.
- **Command endpoints**, for example `POST /v1/trips/{id}/start`, need the `Idempotency-Key` header. Its value becomes the `trip_events.id`.

## Errors

Every error uses one shape:

```json
{
  "error": {
    "code": "ILLEGAL_TRANSITION",
    "message": "Cannot start a trip that is 'created'",
    "details": { "from": "created", "command": "start", "allowed": ["assign", "cancel"] },
    "requestId": "b7e2…"
  }
}
```

| HTTP | Codes |
| --- | --- |
| 400 | `VALIDATION_FAILED` (`details` holds the Zod issues) |
| 401 | `UNAUTHENTICATED`, `TOKEN_EXPIRED` |
| 403 | `FORBIDDEN_ROLE` |
| 404 | `NOT_FOUND` (also returned for other orgs' resources; existence is never leaked) |
| 409 | `ILLEGAL_TRANSITION`, `TRIP_CANCELLED`, `TRIP_REASSIGNED`, `VEHICLE_BUSY`, `DRIVER_BUSY`, `CANCELLATION_PENDING`, `ALREADY_SETTLED`, `IDEMPOTENCY_CONFLICT`, `VERSION_CONFLICT` |
| 422 | `FUEL_TYPE_MISMATCH`, `ODOMETER_BEFORE_START` |
| 429 | `RATE_LIMITED` |

## Endpoint overview

| Area | Endpoints |
| --- | --- |
| Fleet | `GET/POST /vehicles`, `GET/PATCH /vehicles/{id}`, `GET/POST /drivers`, `GET/POST /documents`, `POST /documents/{id}/renew` |
| Media | `POST /media`, `POST /media/{id}/complete`, `GET /media/{id}/url` |
| Trips | `GET/POST /trips`, `GET /trips/{id}`, `POST /trips/{id}/{assign,unassign,start,end,cancel}`, `GET /trips/{id}/events` |
| Trip charges | `POST /trips/{id}/charges`, `POST /trips/{id}/charges/{chargeId}/void` |
| Cancellations | `POST /trips/{id}/cancellation-requests`, `POST /cancellation-requests/{id}/{approve,reject,withdraw}` |
| Telemetry | `POST /trips/{id}/gps-batches`, `GET /trips/{id}/route`, `GET /trips/{id}/distance-check` |
| Fuel | `GET/POST /fuel-fills`, `POST /fuel-fills/{id}/void`, `GET /vehicles/{id}/fuel-cycles` |
| Money | `POST /trips/{id}/collections`, `GET /settlements?date=`, `GET /settlements/{id}`, `POST /settlements/{id}/settle` |
| Settings | `GET/PATCH /settings/audit`, `GET/PATCH /settings/driver-pay`, `PUT /drivers/{id}/pay-rule` |
| Alerts | `GET /alerts`, `PATCH /alerts/{id}`, `GET /review-items`, `POST /review-items/{id}/resolve` |
| Driver sync | `GET /me/trips?since=` (delta pull), `GET /me/sync-state` |
| Platform | `GET /health/live`, `GET /health/ready` |

## Generated TypeScript client

```ts
import { createApiClient } from '@taxcy/api-client';

const api = createApiClient({ baseUrl: 'http://localhost:3000/v1', getToken: () => tokens.access });

const { data, error } = await api.POST('/trips/{id}/start', {
  params: { path: { id: tripId }, header: { 'Idempotency-Key': crypto.randomUUID() } },
  body: { odometer: { id: readingId, typedKm: 48210, mediaId } },
});
```

After changing an endpoint, regenerate the client with `pnpm api:openapi && pnpm api:client`. CI fails if the committed client is out of date.

## Example: a full trip with curl

```bash
TOKEN=…; TRIP=…; H="Authorization: Bearer $TOKEN"

curl -XPOST localhost:3000/v1/trips/$TRIP/assign -H "$H" -H "Idempotency-Key: $(uuidgen)" \
  -H 'content-type: application/json' -d '{"vehicleId":"…","driverId":"…"}'

curl -XPOST localhost:3000/v1/trips/$TRIP/start -H "$H" -H "Idempotency-Key: $(uuidgen)" \
  -H 'content-type: application/json' -d '{"odometer":{"id":"…","typedKm":48210,"mediaId":"…"}}'
```
