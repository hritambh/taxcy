# Getting started: run Taxcy locally, step by step

> **What works today (M0.1):** steps 1–6 and 13. The admin web and driver app are still placeholders, and there's no database schema or login yet. Steps marked **(planned, Mx.y)** describe how they'll work once that milestone lands; each milestone re-runs this guide on a clean machine and updates it. See [roadmap.md](roadmap.md).

This takes about 20 minutes the first time, mostly downloads.

---

## Step 1: Install the tools

### macOS

```bash
# Homebrew (skip if installed): https://brew.sh
brew install fnm                          # Node version manager
fnm install 24 && fnm use 24
curl -fsSL https://bun.sh/install | bash  # Bun, used as the package manager
brew install --cask docker                # Docker Desktop. Open it once and let it finish starting.
```

For the driver app, also install Flutter (<https://docs.flutter.dev/get-started/install/macos>). You need Android Studio, Xcode, or both.

### Linux

Install Node 24 (via `fnm` or `nvm`), Bun (`curl -fsSL https://bun.sh/install | bash`), and Docker Engine with the Compose plugin. Add yourself to the `docker` group. Install Flutter and Android Studio for the driver app.

### Windows

Use **WSL 2** (Ubuntu) and follow the Linux steps inside it, with Docker Desktop's WSL integration turned on. To run the driver app on an Android emulator, install Flutter on Windows itself.

### Check

```bash
node -v          # v24.x
bun -v           # 1.4.x
docker info      # must not print "Cannot connect to the Docker daemon"
flutter --version   # 3.38.x (driver app only)
```

## Step 2: Get the code and install dependencies

```bash
git clone https://github.com/hritambh/taxcy.git
cd taxcy
bun install
```

Bun installs every workspace (apps and libs) and writes nothing outside the repo.

## Step 3: Create your environment file

```bash
cp .env.example .env
```

The defaults work for local development. If one of the default host ports (5433, 6380, 9000, 9001, 3000, 5173) is taken on your machine, change it in `.env`.

## Step 4: Start Postgres, Redis and RustFS

```bash
bun run infra:up
```

This runs `docker compose up -d --wait` and returns once everything is healthy:

| Service                 | Address                                 | Login                        |
| ----------------------- | --------------------------------------- | ---------------------------- |
| PostgreSQL 16 + PostGIS | `localhost:5433`                        | `taxcy` / `taxcy`            |
| Redis                   | `localhost:6380`                        | —                            |
| RustFS (S3)             | <http://localhost:9000>                 | `taxcy` / `taxcy-dev-secret` |
| RustFS console          | <http://localhost:9001/rustfs/console/> | same                         |

The `taxcy-media` bucket is created automatically. To check:

```bash
docker compose ps                                     # postgres, redis, s3: healthy
docker compose exec postgres psql -U taxcy -c 'select postgis_version()'
```

## Step 5: Start the API, workers and admin web

```bash
bun run dev
```

Nx builds the shared libs, then runs three processes with prefixed logs:

| Process            | What you should see                                                 |
| ------------------ | ------------------------------------------------------------------- |
| `@taxcy/api`       | `Nest application successfully started`, at <http://localhost:3000> |
| `@taxcy/workers`   | `workers: started, no queues registered yet`                        |
| `@taxcy/admin-web` | `VITE … ready`, at <http://localhost:5173>                          |

Leave this running and use a second terminal for the next steps.

## Step 6: Check that it works

```bash
curl localhost:3000/health/live
# {"status":"ok"}
```

Open <http://localhost:5173>. The placeholder admin page should show **API: up**. That confirms the browser reaches the API through Vite's `/api` proxy.

Edit any file under `apps/api/src` and the API restarts by itself. Edit `apps/admin-web/src/App.tsx` and the page hot-reloads.

---

## Step 7: Create the database and load sample data (planned, M0.2 and M0.5)

```bash
bun run db:migrate
bun run db:seed
```

The seed prints the logins it created. You'll need these phone numbers:

```
Seeded org "Sharma Travels"
  owner    Anil Sharma     +91 90000 00001
  manager  Priya Nair      +91 90000 00002
  driver   Ramesh Kumar    +91 90000 00011   (Innova Crysta, diesel)
  driver   Suresh Patil    +91 90000 00012   (Dzire, CNG)
  driver   Imran Shaikh    +91 90000 00013   (Etios, petrol)
```

Re-running the seed is safe. `bun run db:reset` wipes the database and seeds it again.

## Step 8: Log in to the admin web (planned, M0.3 and M1.7)

1. Open <http://localhost:5173> and enter the owner's number (`9000000001`).
2. Find the OTP in the `bun run dev` terminal:
   ```
   @taxcy/api: otp.issued phone=+919000000001 code=482913 (dev only)
   ```
3. Enter the code.

## Step 9: Explore the seeded data (planned, M1.7)

1. **Alerts:** a critical fuel alert on the Dzire, an odometer-vs-GPS alert on an Innova trip, and an insurance-expiry warning.
2. **Fuel → Dzire:** one red cycle well below the shaded normal band. Click it to see the fills and the explanation.
3. **Trips → (any ended trip):** the timeline, odometer photos, and the route on the map.
4. **Review:** an OCR mismatch. Choose "Keep typed value".
5. **Settlements → yesterday:** open a driver's row, check the numbers, then **Mark settled**.
6. **Trips → New trip:** one way, Pune → Mumbai, starting in 10 minutes, fare ₹3,500, assigned to Ramesh and the Innova. You'll drive it in step 11.

## Step 10: Run the driver app

The placeholder app runs today. From M1.8 it talks to the API.

```bash
cd apps/driver-app
flutter pub get
flutter devices          # list emulators, simulators and phones
flutter run              # pick one
```

From M1.8, tell the app where the API is:

| Target                      | Command                                                       |
| --------------------------- | ------------------------------------------------------------- |
| Android emulator            | `flutter run --dart-define=API_URL=http://10.0.2.2:3000`      |
| iOS simulator               | `flutter run --dart-define=API_URL=http://localhost:3000`     |
| Physical phone (same Wi-Fi) | `flutter run --dart-define=API_URL=http://<your-LAN-IP>:3000` |

On a physical phone, photo uploads also need `S3_PUBLIC_ENDPOINT=http://<your-LAN-IP>:9000` in the root `.env`. Restart `bun run dev` after changing it. On macOS, `ipconfig getifaddr en0` prints your LAN IP.

## Step 11: Drive a trip (planned, M1.8)

1. Log in as **Ramesh** (`9000000011`) with the OTP from the API log, and allow camera and location access.
2. Open the Pune → Mumbai trip and tap **Start trip**. Photograph the odometer (an emulator camera shows a test scene, which is fine because OCR is stubbed), type `48210`, and tap **Start**.
3. **Simulate driving.** On the Android emulator, open **Extended controls → Location → Routes**, load `apps/driver-app/test/fixtures/pune-mumbai.gpx`, and press play. On the iOS simulator, use **Features → Location → Freeway Drive**.
4. Add a ₹250 toll, marked **I paid this**.
5. **End trip:** photograph the odometer, type `48365`, and enter ₹3,500 cash.
6. In the admin web, the trip shows _Ended_, the GPS route, the toll, and an odometer-vs-GPS result within a few seconds.

## Step 12: Try offline mode (planned, M1.8)

1. Turn on airplane mode; the status bar shows 🔴 **Offline**.
2. Log a fuel fill: receipt photo, odometer, 40 L, ₹3,800, **Full tank** on. The bar shows 🟡 **1 pending**.
3. Turn airplane mode off. The bar goes back to 🟢 **Synced**, and the fill appears in the admin web.

To see a sync conflict: put the phone offline, start an assigned trip in the app, cancel that trip in the admin web, then go back online. The app shows _"This trip was cancelled by the owner"_.

---

## Step 13: Run the checks

```bash
bun run verify     # format check, lint, typecheck, unit tests, build: what CI runs
```

Planned additions: `bun run test:integration` (M0.2, API tests against throwaway containers) and `bun run test:e2e:driver` (M1.9, Maestro flow on a running emulator).

## Stopping and resetting

```bash
# stop the dev servers: Ctrl+C in the `bun run dev` terminal
bun run infra:down       # stop containers; data is kept
bun run infra:reset      # DELETE all local data (database, Redis, uploaded files) and start fresh
```

## Troubleshooting

| Symptom                                                                         | Fix                                                                                                                                                                                                          |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Bind for 0.0.0.0:5433 failed: port is already allocated` (or 6380, 9000, 9001) | Something else uses that port. Pick another in `.env` (`POSTGRES_PORT`, `REDIS_PORT`, `S3_PORT`, `S3_CONSOLE_PORT`) and update `DATABASE_URL` / `REDIS_URL` / `S3_ENDPOINT` to match.                        |
| `Port 5173 is already in use`                                                   | Another Vite app is running. Stop it; the admin web uses a fixed port so the API proxy stays predictable.                                                                                                    |
| API logs `EADDRINUSE :::3000`                                                   | Set `PORT=3001` (or another free port) in `.env`, and update the proxy target in `apps/admin-web/vite.config.ts`.                                                                                            |
| Admin page shows **API: down**                                                  | The API isn't running or crashed; check the `@taxcy/api` lines in the `bun run dev` output.                                                                                                                  |
| `Cannot find module '@taxcy/…'` when running an app directly                    | Libs haven't been built. Use `bun run dev` / `bun run build` (Nx builds libs first), or `bunx nx run @taxcy/<lib>:build`.                                                                                    |
| TypeScript can't find `process` or `setInterval` in a new Node package          | Add `@types/node` to that package's `devDependencies` and `"types": ["node"]` to its `tsconfig.json`. TypeScript 6 doesn't auto-load `@types`, and Bun's isolated installs don't share them across packages. |
| `flutter: command not found` during `bun run lint`                              | The driver app's lint/test need Flutter. Install it, or run `bunx nx run-many -t lint --exclude @taxcy/driver-app`.                                                                                          |
| RustFS console shows 403                                                        | Use the full console path: <http://localhost:9001/rustfs/console/>.                                                                                                                                          |
