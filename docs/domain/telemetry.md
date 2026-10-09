# GPS telemetry

## Recording (driver app)

- Recording runs only while a trip is `started`. It uses `expo-location` background updates through `expo-task-manager`, as an Android foreground service with a persistent notification. This is why the app needs a dev build rather than Expo Go.
- Sampling is every 15 s or every 50 m, whichever comes first, at balanced accuracy.
- Each point is written to local SQLite with a client UUID: `{ id, tripId, recordedAt, lat, lng, accuracyM, speedMps, heading, isMock }`.
- The sync engine uploads points in batches of up to 500 to `POST /trips/{id}/gps-batches`.
- On first use, the driver sees a consent screen explaining why location is collected and for how long it's kept (DPDP Act 2023).

## Ingest (API)

- The batch is Zod-validated. Points are inserted with `ON CONFLICT (recorded_at, client_point_id) DO NOTHING`, so re-sending a batch is safe.
- Points are accepted only for trips the caller drives, and only between `started_at − 5 min` and `ended_at + 30 min`. Points outside that window are dropped and counted in the response.
- A batch that arrives after the trip ended re-queues `trip-distance` for that trip.

## Storage

`gps_points` is range-partitioned by `recorded_at`, monthly (`gps_points_2026_10`, …), with a `DEFAULT` partition so a late or clock-skewed point never fails to insert. A daily cron creates partitions two months ahead and drops those older than `GPS_RETENTION_MONTHS` (default 12).

## Distance computation

The filtering lives in `libs/domain/telemetry` as pure functions; the summing runs in PostGIS.

1. **Filter bad points:**
   - accuracy > 100 m
   - points flagged `isMock` (these are also counted, and create a `mock_location` review item)
   - duplicate timestamps
   - **impossible speed**: implied speed from the previous kept point > 150 km/h (configurable)
2. **Order** the remaining points by `recorded_at` and build a line.
3. **Sum** with PostGIS: `ST_Length(ST_MakeLine(location::geometry ORDER BY recorded_at)::geography)`, giving metres on the spheroid.
4. **Measure coverage:**
   - `max_gap_seconds`: the longest gap between consecutive kept points
   - gaps longer than 5 minutes are **bridged** with the straight-line distance between their endpoints. This is a lower bound; real road distance is longer.
   - `coverage_ratio` = time covered by gaps ≤ 5 min ÷ trip duration

## Odometer-vs-GPS check

Runs on `trip.ended`, and again whenever late points arrive.

```
odo_km = end_km − start_km
gps_km = filtered + bridged distance

if coverage_ratio < 0.7 or points_used < 20:  result = inconclusive
elif odo_km > gps_km × (1 + tolerance/100):   result = flagged     (tolerance default 10%)
else:                                          result = ok
```

A `flagged` result raises an `odo_gps_mismatch` alert:

> **Trip on 9 Oct (Pune → Mumbai, MH12 AB 1234) shows more km on the odometer than the GPS route.** The odometer readings say 182 km, but the phone's GPS recorded 151 km, which is 21% less. Allowed difference: 10%. Check the start and end odometer photos.

Severity is `warning` up to twice the tolerance and `critical` beyond that.

### Why "inconclusive" exists

Many Android phones popular in India (Xiaomi, Oppo, Vivo, Realme) aggressively kill background location. Without a coverage check, missing GPS would make honest drivers look like they inflated the odometer. Inconclusive results are shown on the trip detail page but don't raise alerts. A driver whose trips are often inconclusive gets an `info` alert suggesting they fix their battery settings.
