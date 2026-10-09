# Getting started: run Taxcy locally, step by step

> **Current status.** This guide describes the setup that milestones M0.1–M0.5 (backend + admin web) and M1.8 (driver app) will deliver. **None of these steps work yet**, because no code has been written. Each milestone that touches a step re-runs it on a clean machine and updates this page. Check [roadmap.md](roadmap.md) to see what has landed.
>
> | Steps | Usable after |
> | --- | --- |
> | 1–4 (tools, clone, env, infrastructure) | M0.1 |
> | 5–7 (database, seed, run backend) | M0.2–M0.5 |
> | 8–9 (admin web walkthrough) | M1.7 |
> | 10–12 (driver app) | M1.8 |
> | 13 (tests) | grows with every milestone |

This takes about 20 minutes the first time, mostly downloads.

---

## Step 1: Install the tools

### macOS

```bash
# Homebrew (skip if installed): https://brew.sh
brew install fnm                         # Node version manager
fnm install 24 && fnm use 24
corepack enable                          # provides pnpm at the version pinned in package.json
brew install --cask docker               # Docker Desktop. Open it once and let it finish starting.
```

### Linux

Install Node 24 (via `fnm` or `nvm`), run `corepack enable`, and install Docker Engine with the Compose plugin. Add yourself to the `docker` group so Docker runs without `sudo`.

### Windows

Use **WSL 2** (Ubuntu) and follow the Linux steps inside it, with Docker Desktop's WSL integration turned on. Native Windows isn't supported.

### Check

```bash
node -v      # v24.x
pnpm -v      # 11.x
docker info  # must not print "Cannot connect to the Docker daemon"
```

> **Apple Silicon:** the project uses a multi-arch PostGIS image, so no Rosetta or `platform:` override is needed.

## Step 2: Get the code and install dependencies

```bash
git clone <repo-url> taxcy      # no remote yet; for now, use the local folder
cd taxcy
pnpm install                    # also runs `prisma generate`
```

## Step 3: Create your environment file

```bash
cp .env.example .env
```

The defaults work for local development, so you don't need to edit anything. Every variable is listed in [development.md](development.md#environment-variables). If a variable is missing or invalid, the API refuses to start and tells you which one.

## Step 4: Start Postgres, Redis and MinIO

```bash
docker compose up -d
docker compose ps               # wait until postgres, redis and minio are all "healthy"
```

This starts:

| Service | Address | Login |
| --- | --- | --- |
| PostgreSQL 16 + PostGIS | `localhost:5432` | `taxcy` / `taxcy` |
| Redis | `localhost:6379` | — |
| MinIO (S3) | <http://localhost:9000>, console at <http://localhost:9001> | `minioadmin` / `minioadmin` |

The `taxcy-media` bucket is created automatically.

## Step 5: Create the database schema

```bash
pnpm db:migrate
```

Expected output ends with `All migrations have been successfully applied.`

## Step 6: Load sample data

```bash
pnpm db:seed
```

The seed prints the logins it created. Keep this output; you'll need the phone numbers:

```
Seeded org "Sharma Travels"
  owner    Anil Sharma     +91 90000 00001
  manager  Priya Nair      +91 90000 00002
  driver   Ramesh Kumar    +91 90000 00011   (Innova Crysta, diesel)
  driver   Suresh Patil    +91 90000 00012   (Dzire, CNG)
  driver   Imran Shaikh    +91 90000 00013   (Etios, petrol)
```

Re-running the seed is safe; it doesn't create duplicates. To start over from scratch, run `pnpm db:reset`.

## Step 7: Start the backend and the admin web

```bash
pnpm dev
```

This runs three processes with prefixed, colour-coded logs:

| Process | URL |
| --- | --- |
| `api` | <http://localhost:3000>; API docs at <http://localhost:3000/docs> |
| `workers` | Job dashboard at <http://localhost:3001/queues> |
| `admin` | <http://localhost:5173> |

Check that everything is up:

```bash
curl -s localhost:3000/health/ready
# {"status":"ok","checks":{"postgres":"ok","redis":"ok","s3":"ok"}}
```

Leave this terminal running. Use a second terminal for the following steps.

## Step 8: Log in to the admin web

1. Open <http://localhost:5173>.
2. Enter the owner's number from step 6 (`9000000001`).
3. Find the OTP in the `pnpm dev` terminal:
   ```
   [api] INFO otp.issued phone=+919000000001 code=482913 (dev only)
   ```
4. Enter the code. You land on the dashboard for "Sharma Travels".

## Step 9: Try the main flows in the admin web

The seed has already created some activity, so there's something to see straight away:

1. **Alerts:** there's a critical fuel alert on the Dzire, an odometer-vs-GPS alert on one Innova trip, and an insurance-expiry warning.
2. **Fuel → Dzire:** the cycles chart shows one red cycle well below the shaded normal band. Click it to see the fills and the explanation.
3. **Fuel → Etios / Innova:** cycles within the normal band, including partial fills between full-tank fills.
4. **Trips → (any ended trip):** the timeline, odometer photos, and the route on the map.
5. **Review:** an OCR mismatch. Pick "Keep typed value" and watch the item clear.
6. **Settlements → yesterday:** one row per driver. Open one, check the numbers, then **Mark settled**.

Then create something yourself:

7. **Trips → New trip:** one way, Pune → Mumbai, starting in 10 minutes, fare ₹3,500. Assign it to Ramesh and the Innova. You'll drive this trip from the driver app in step 11.

## Step 10: Set up the driver app

The driver app needs a native **dev build** (it uses background location and a custom camera), so Expo Go won't work.

### Prerequisites

- **Android:** Android Studio with an emulator (Pixel, API 34+) **or** a phone with USB debugging enabled.
- **iOS (macOS only):** Xcode with a simulator **or** an iPhone with a free Apple developer account.

### Point the app at your API

Create `apps/driver-app/.env`:

```bash
# Android emulator:
EXPO_PUBLIC_API_URL=http://10.0.2.2:3000
# iOS simulator:
# EXPO_PUBLIC_API_URL=http://localhost:3000
# Physical device on the same Wi-Fi (find your IP with `ipconfig getifaddr en0` on macOS):
# EXPO_PUBLIC_API_URL=http://192.168.1.23:3000
```

Physical devices also need to reach MinIO for photo uploads. Set `S3_PUBLIC_ENDPOINT=http://<your-LAN-IP>:9000` in the root `.env` and restart `pnpm dev`.

### Build and run

```bash
pnpm --filter driver-app android     # first build takes 5–10 minutes
# or
pnpm --filter driver-app ios
```

Later runs reuse the build and start in seconds. Re-run the command above only after changing native dependencies.

## Step 11: Drive a trip in the app

1. Log in as **Ramesh** (`9000000011`) with the OTP from the `pnpm dev` log.
2. Allow camera and location access.
3. **My trips** shows the Pune → Mumbai trip from step 9. Tap it, then **Start trip**.
4. Take the odometer photo. On an emulator, the camera shows a test pattern; that's fine, because OCR is stubbed. Type `48210` and tap **Start**.
5. **Simulate driving.** On the Android emulator, open **Extended controls (…) → Location → Routes**, load `apps/driver-app/e2e/fixtures/pune-mumbai.gpx`, and press play. On the iOS simulator, use **Features → Location → Freeway Drive**.
6. Add a ₹250 toll from the live trip screen, marked **I paid this**.
7. **End trip:** take a photo, type `48365`, and enter ₹3,500 cash. Tap **End**.
8. Back in the admin web, refresh the trip. It shows *Ended*, the GPS route, the toll, and an odometer-vs-GPS result within a few seconds (the workers compute it).

## Step 12: Try offline mode

1. In the app, turn on airplane mode. The status bar turns 🔴 **Offline**.
2. Log a fuel fill: receipt photo, odometer, 40 L, ₹3,800, **Full tank** on.
3. Watch the bar show 🟡 **1 pending**.
4. Turn airplane mode off. The bar goes back to 🟢 **Synced**, and the fill appears under **Fuel** in the admin web.

To see a sync conflict: create and assign a trip, put the phone in airplane mode, start the trip in the app, cancel it in the admin web, then go back online. The app shows *"This trip was cancelled by the owner"*.

## Step 13: Run the checks

```bash
pnpm verify              # lint, format check, typecheck, unit tests (what CI runs)
pnpm test:integration    # API tests against throwaway containers (needs Docker; about 2 minutes)
pnpm test:e2e:driver     # Maestro start → end trip flow (needs a running emulator with the app installed)
```

## Stopping and resetting

```bash
# stop the dev servers: Ctrl+C in the `pnpm dev` terminal
docker compose stop            # stop infrastructure; data is kept
docker compose down -v         # stop and DELETE all local data (database, Redis, uploaded photos)
pnpm db:reset                  # wipe and re-seed the database only (infrastructure keeps running)
```

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `port 5432 is already allocated` | Another Postgres is running. Stop it (`brew services stop postgresql`), or set `POSTGRES_PORT=5433` in `.env` and update `DATABASE_URL`. |
| API exits with `Invalid environment: …` | A variable in `.env` is missing or malformed. Compare with `.env.example`. |
| `pnpm db:migrate` can't connect | Postgres isn't healthy yet. Wait for `docker compose ps` to show `healthy`. |
| No OTP in the log | Check `SMS_PROVIDER=console`. If you requested too many codes, you're rate-limited for 10 minutes; restart Redis (`docker compose restart redis`) to clear it in dev. |
| Driver app shows "Network request failed" | Wrong `EXPO_PUBLIC_API_URL`. Emulators can't use `localhost` for your machine; use `10.0.2.2`. Phones need your LAN IP, on the same Wi-Fi, with the macOS firewall allowing Node. |
| Photos stay "pending upload" on a phone | `S3_PUBLIC_ENDPOINT` still points to `localhost`; set it to your LAN IP. |
| Trip shows odometer-vs-GPS **inconclusive** | Too few GPS points were recorded. On an emulator, make sure the route playback ran during the trip. |
| `prisma` client errors after pulling changes | Run `pnpm db:generate && pnpm db:migrate`. |
| Metro can't resolve a workspace package | Run `pnpm --filter driver-app start --clear`. |
