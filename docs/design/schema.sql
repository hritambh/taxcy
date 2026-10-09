-- Taxcy — proposed schema for Phase 0 + Phase 1 (design reference, not a migration).
-- Once M0.2 lands, libs/db/prisma (schema.prisma + migrations) is the source of truth.
-- IDs: UUIDv7 generated in the app (server) or UUIDv4 from the client (offline records).

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ───────── enums (ADD VALUE later is non-breaking) ─────────
CREATE TYPE org_kind        AS ENUM ('fleet','dco');
CREATE TYPE membership_role AS ENUM ('owner','manager','driver');
CREATE TYPE fuel_type       AS ENUM ('petrol','diesel','cng','petrol_cng');   -- vehicle capability
CREATE TYPE fuel_kind       AS ENUM ('petrol','diesel','cng');                -- what a fill contains
CREATE TYPE audit_track     AS ENUM ('petrol','diesel','cng','bifuel_cost');  -- what a fuel cycle measures
CREATE TYPE trip_type       AS ENUM ('one_way','round_trip','local_rental');
CREATE TYPE trip_status     AS ENUM ('created','assigned','started','ended','settled','cancelled');
CREATE TYPE booking_channel AS ENUM ('direct');            -- later: 'passenger_app','ota_partner'
CREATE TYPE doc_type        AS ENUM ('rc','insurance','permit','puc','driving_licence');
CREATE TYPE media_kind      AS ENUM ('odometer','fuel_receipt','document','other');
CREATE TYPE alert_severity  AS ENUM ('info','warning','critical');

-- ───────── identity ─────────
CREATE TABLE users (
  id uuid PRIMARY KEY,
  phone_e164 text NOT NULL UNIQUE,
  name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE organizations (
  id uuid PRIMARY KEY,
  name text NOT NULL,
  kind org_kind NOT NULL,
  timezone text NOT NULL DEFAULT 'Asia/Kolkata',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE org_settings (
  org_id uuid PRIMARY KEY REFERENCES organizations,
  fuel_k_sigma numeric(4,2) NOT NULL DEFAULT 2.0,
  fuel_min_cycles int NOT NULL DEFAULT 3,
  fuel_pct_threshold numeric(5,2) NOT NULL DEFAULT 20.0,
  fuel_ewma_alpha numeric(4,3) NOT NULL DEFAULT 0.3,
  odo_gps_tolerance_pct numeric(5,2) NOT NULL DEFAULT 10.0,
  doc_alert_days int[] NOT NULL DEFAULT '{30,7,1}',
  driver_pay_rule jsonb NOT NULL DEFAULT '{"kind":"none","allowanceToDriver":true}'   -- Zod-validated; see docs/domain/settlement.md
);

CREATE TABLE memberships (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL REFERENCES organizations,
  user_id uuid NOT NULL REFERENCES users,
  roles membership_role[] NOT NULL CHECK (cardinality(roles) > 0),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('invited','active','suspended')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, user_id)
);

CREATE TABLE devices (
  id uuid PRIMARY KEY,                -- client-generated install id
  user_id uuid NOT NULL REFERENCES users,
  platform text NOT NULL,
  app_version text,
  last_seen_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users,
  org_id uuid NOT NULL REFERENCES organizations,
  family_id uuid NOT NULL,
  token_hash text NOT NULL UNIQUE,
  device_id uuid REFERENCES devices,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  replaced_by uuid REFERENCES refresh_tokens,
  created_at timestamptz NOT NULL DEFAULT now()
);
-- OTP challenges + rate-limit counters live in Redis (TTL'd)

-- ───────── media / evidence ─────────
CREATE TABLE media_objects (
  id uuid PRIMARY KEY,                -- client UUID (idempotent)
  org_id uuid NOT NULL REFERENCES organizations,
  uploaded_by uuid NOT NULL REFERENCES users,
  kind media_kind NOT NULL,
  storage_key text NOT NULL UNIQUE,
  content_type text NOT NULL,
  byte_size int,
  sha256 text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','uploaded','rejected')),
  captured_at timestamptz NOT NULL,
  capture_location geography(Point,4326),
  capture_accuracy_m real,
  is_mock_location boolean,
  device_id uuid REFERENCES devices,
  received_at timestamptz NOT NULL DEFAULT now(),
  uploaded_at timestamptz
);

CREATE TABLE ocr_results (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL,
  media_id uuid NOT NULL REFERENCES media_objects,
  provider text NOT NULL,
  status text NOT NULL CHECK (status IN ('ok','unreadable','error')),
  value_numeric numeric,
  value_text text,
  confidence real,
  raw jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ───────── fleet ─────────
CREATE TABLE vehicle_models (
  id uuid PRIMARY KEY,
  org_id uuid REFERENCES organizations,          -- NULL = global reference row
  make text NOT NULL,
  model text NOT NULL,
  fuel_type fuel_type NOT NULL
);

CREATE TABLE fuel_baseline_defaults (
  id uuid PRIMARY KEY,
  org_id uuid REFERENCES organizations,
  vehicle_model_id uuid REFERENCES vehicle_models,
  track audit_track NOT NULL,
  mean_value double precision NOT NULL,          -- km/L, km/kg, or paise/km for bifuel_cost
  std_value double precision NOT NULL,
  UNIQUE NULLS NOT DISTINCT (org_id, vehicle_model_id, track)
);

CREATE TABLE vehicles (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL REFERENCES organizations,
  registration_no text NOT NULL,
  vehicle_model_id uuid REFERENCES vehicle_models,
  make text NOT NULL,
  model text NOT NULL,
  year smallint,
  fuel_type fuel_type NOT NULL,
  last_odometer_km int,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, registration_no)
);

CREATE TABLE drivers (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL REFERENCES organizations,
  membership_id uuid NOT NULL UNIQUE REFERENCES memberships,
  user_id uuid NOT NULL REFERENCES users,
  name text NOT NULL,
  pay_rule jsonb,                                -- per-driver override of org_settings.driver_pay_rule
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE documents (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL REFERENCES organizations,
  doc_type doc_type NOT NULL,
  vehicle_id uuid REFERENCES vehicles,
  driver_id uuid REFERENCES drivers,
  number text,
  valid_from date,
  expires_on date NOT NULL,                      -- IST calendar date
  media_id uuid REFERENCES media_objects,
  superseded_by uuid REFERENCES documents,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((vehicle_id IS NULL) <> (driver_id IS NULL)),
  CHECK ((doc_type = 'driving_licence') = (driver_id IS NOT NULL))
);
CREATE INDEX ON documents (org_id, expires_on) WHERE superseded_by IS NULL;

CREATE TABLE odometer_readings (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL,
  vehicle_id uuid NOT NULL REFERENCES vehicles,
  context text NOT NULL CHECK (context IN ('trip_start','trip_end','fuel_fill','adhoc')),
  typed_km int NOT NULL CHECK (typed_km >= 0),
  ocr_km int,
  media_id uuid NOT NULL REFERENCES media_objects,
  captured_at timestamptz NOT NULL,
  created_by uuid NOT NULL REFERENCES users
);

-- ───────── trips ─────────
CREATE TABLE customers (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL,
  name text NOT NULL,
  phone_e164 text,
  user_id uuid REFERENCES users                  -- future passenger account
);

CREATE TABLE trips (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL REFERENCES organizations,
  trip_type trip_type NOT NULL,
  status trip_status NOT NULL DEFAULT 'created',
  channel booking_channel NOT NULL DEFAULT 'direct',
  customer_id uuid REFERENCES customers,
  from_text text NOT NULL,
  from_point geography(Point,4326),
  to_text text,                                  -- NULL for local_rental
  to_point geography(Point,4326),
  scheduled_start_at timestamptz NOT NULL,
  scheduled_end_at timestamptz NOT NULL,
  busy_window tstzrange GENERATED ALWAYS AS (tstzrange(scheduled_start_at, scheduled_end_at, '[)')) STORED,
  vehicle_id uuid REFERENCES vehicles,
  driver_id uuid REFERENCES drivers,
  quoted_fare_paise bigint NOT NULL CHECK (quoted_fare_paise >= 0),
  start_odometer_id uuid REFERENCES odometer_readings,
  end_odometer_id uuid REFERENCES odometer_readings,
  started_at timestamptz,
  ended_at timestamptz,
  cancelled_at timestamptz,
  cancel_reason text,
  cancellation_fare_paise bigint CHECK (cancellation_fare_paise >= 0),   -- set on approval of a started-trip cancellation
  version int NOT NULL DEFAULT 0,                -- optimistic lock for transitions
  created_by uuid NOT NULL REFERENCES users,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (scheduled_end_at > scheduled_start_at),
  CHECK (status NOT IN ('assigned','started','ended','settled')
         OR (vehicle_id IS NOT NULL AND driver_id IS NOT NULL)),
  EXCLUDE USING gist (vehicle_id WITH =, busy_window WITH &&) WHERE (status IN ('assigned','started')),
  EXCLUDE USING gist (driver_id  WITH =, busy_window WITH &&) WHERE (status IN ('assigned','started'))
);
CREATE INDEX ON trips (org_id, status, scheduled_start_at);
CREATE INDEX ON trips (driver_id, scheduled_start_at);

CREATE TABLE trip_events (
  id uuid PRIMARY KEY,                           -- client/command UUID = idempotency key
  org_id uuid NOT NULL,
  trip_id uuid NOT NULL REFERENCES trips,
  seq int NOT NULL,
  event_type text NOT NULL,
  from_status trip_status,
  to_status trip_status,
  actor_user_id uuid REFERENCES users,           -- NULL = system
  actor_role membership_role,
  occurred_at timestamptz NOT NULL,              -- device clock
  recorded_at timestamptz NOT NULL DEFAULT now(),
  payload jsonb NOT NULL DEFAULT '{}',
  UNIQUE (trip_id, seq)
);

CREATE TABLE trip_cancellation_requests (
  id uuid PRIMARY KEY,                           -- client UUID
  org_id uuid NOT NULL,
  trip_id uuid NOT NULL REFERENCES trips,
  requested_by uuid NOT NULL REFERENCES users,
  requested_role membership_role NOT NULL,
  reason text NOT NULL CHECK (length(trim(reason)) > 0),
  end_odometer_id uuid REFERENCES odometer_readings,   -- required when the trip was started (enforced in domain)
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','withdrawn')),
  decided_by uuid REFERENCES users,
  decided_at timestamptz,
  decision_note text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ON trip_cancellation_requests (trip_id) WHERE status = 'pending';

CREATE TABLE trip_charges (
  id uuid PRIMARY KEY,                           -- client UUID
  org_id uuid NOT NULL,
  trip_id uuid NOT NULL REFERENCES trips,
  kind text NOT NULL CHECK (kind IN ('toll','parking','state_tax','driver_allowance','night_charge','extra_km','other')),
  amount_paise bigint NOT NULL CHECK (amount_paise >= 0),
  paid_by_driver boolean NOT NULL,               -- true: driver paid out of pocket, reimbursed in settlement
  media_id uuid REFERENCES media_objects,
  note text,
  entered_by uuid NOT NULL REFERENCES users,     -- driver, owner or manager
  entered_role membership_role NOT NULL,
  voided_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ───────── fuel ─────────
CREATE TABLE fuel_fills (
  id uuid PRIMARY KEY,                           -- client UUID
  org_id uuid NOT NULL,
  vehicle_id uuid NOT NULL REFERENCES vehicles,
  driver_id uuid REFERENCES drivers,
  trip_id uuid REFERENCES trips,
  fuel fuel_kind NOT NULL,
  quantity_milli int NOT NULL CHECK (quantity_milli > 0),   -- ml or g, unit implied by fuel
  cost_paise bigint NOT NULL CHECK (cost_paise >= 0),
  odometer_id uuid NOT NULL REFERENCES odometer_readings,
  is_full_tank boolean NOT NULL,
  receipt_media_id uuid REFERENCES media_objects,
  ocr_cost_paise bigint,
  ocr_quantity_milli int,
  paid_by text NOT NULL CHECK (paid_by IN ('driver_cash','owner','fuel_card')),
  filled_at timestamptz NOT NULL,
  voided_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON fuel_fills (vehicle_id, fuel, filled_at) WHERE voided_at IS NULL;

CREATE TABLE fuel_cycles (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL,
  vehicle_id uuid NOT NULL REFERENCES vehicles,
  track audit_track NOT NULL,
  opening_fill_id uuid NOT NULL REFERENCES fuel_fills,
  closing_fill_id uuid NOT NULL REFERENCES fuel_fills,
  distance_km int NOT NULL,
  fuel_milli int,                                -- NULL for bifuel_cost (mixed units)
  cost_paise bigint NOT NULL,
  metric text NOT NULL CHECK (metric IN ('km_per_unit','paise_per_km')),
  metric_value double precision,                 -- higher is better for km_per_unit, worse for paise_per_km
  baseline_mean double precision,
  baseline_std double precision,
  prior_cycles int NOT NULL,
  method text NOT NULL CHECK (method IN ('sigma','percent')),
  deviation double precision,
  verdict text NOT NULL CHECK (verdict IN ('ok','flagged','invalid')),
  included_in_baseline boolean NOT NULL,
  computed_at timestamptz NOT NULL DEFAULT now(),
  superseded_at timestamptz
);
CREATE UNIQUE INDEX ON fuel_cycles (closing_fill_id) WHERE superseded_at IS NULL;

CREATE TABLE vehicle_fuel_baselines (
  vehicle_id uuid NOT NULL REFERENCES vehicles,
  track audit_track NOT NULL,
  org_id uuid NOT NULL,
  ewma_mean double precision NOT NULL,
  ewma_var double precision NOT NULL,
  n_cycles int NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (vehicle_id, track)
);

-- ───────── telemetry ─────────
CREATE TABLE gps_points (
  org_id uuid NOT NULL,
  trip_id uuid NOT NULL,
  driver_id uuid NOT NULL,
  client_point_id uuid NOT NULL,
  recorded_at timestamptz NOT NULL,
  location geography(Point,4326) NOT NULL,
  accuracy_m real,
  speed_mps real,
  heading real,
  is_mock boolean NOT NULL DEFAULT false,
  received_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (recorded_at, client_point_id)     -- partition key must be in PK; dedupes re-sent batches
) PARTITION BY RANGE (recorded_at);
CREATE TABLE gps_points_default PARTITION OF gps_points DEFAULT;
-- monthly partitions (gps_points_YYYY_MM) are created by the gps-partitions cron
CREATE INDEX ON gps_points (trip_id, recorded_at);

CREATE TABLE trip_distance_checks (
  trip_id uuid PRIMARY KEY REFERENCES trips,
  org_id uuid NOT NULL,
  odometer_km int NOT NULL,
  gps_km double precision,
  points_total int,
  points_used int,
  max_gap_seconds int,
  coverage_ratio real,
  result text NOT NULL CHECK (result IN ('ok','flagged','inconclusive')),
  computed_at timestamptz NOT NULL DEFAULT now()
);

-- ───────── collections & settlement ─────────
CREATE TABLE trip_collections (
  id uuid PRIMARY KEY,                           -- client UUID
  org_id uuid NOT NULL,
  trip_id uuid NOT NULL REFERENCES trips,
  driver_id uuid NOT NULL REFERENCES drivers,
  method text NOT NULL CHECK (method IN ('cash','upi','card')),
  amount_paise bigint NOT NULL CHECK (amount_paise >= 0),
  reference text,
  collected_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE settlements (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL,
  driver_id uuid NOT NULL REFERENCES drivers,
  business_date date NOT NULL,                   -- IST
  expected_fare_paise bigint NOT NULL,
  cash_paise bigint NOT NULL,
  online_paise bigint NOT NULL,
  driver_expenses_paise bigint NOT NULL,
  driver_earnings_paise bigint NOT NULL,
  carried_adjustment_paise bigint NOT NULL DEFAULT 0,
  net_payable_paise bigint NOT NULL,             -- > 0: driver owes org
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','settled')),
  settled_by uuid REFERENCES users,
  settled_at timestamptz,
  UNIQUE (org_id, driver_id, business_date)
);

CREATE TABLE settlement_lines (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL,
  settlement_id uuid NOT NULL REFERENCES settlements,
  ref_type text NOT NULL CHECK (ref_type IN ('trip','trip_charge','collection','fuel_fill','adjustment')),
  ref_id uuid NOT NULL,
  amount_paise bigint NOT NULL,
  UNIQUE (ref_type, ref_id)                      -- each item is settled at most once
);

-- ───────── alerts & review ─────────
CREATE TABLE alerts (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL,
  kind text NOT NULL,   -- fuel_efficiency_low | odo_gps_mismatch | document_expiring | document_expired | cancellation_requested
  severity alert_severity NOT NULL,
  title text NOT NULL,
  explanation text NOT NULL,
  vehicle_id uuid,
  driver_id uuid,
  trip_id uuid,
  subject_type text NOT NULL,
  subject_id uuid NOT NULL,
  data jsonb NOT NULL DEFAULT '{}',
  dedupe_key text NOT NULL,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','acknowledged','resolved','dismissed')),
  resolved_by uuid,
  resolved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, dedupe_key)
);

CREATE TABLE review_items (
  id uuid PRIMARY KEY,
  org_id uuid NOT NULL,
  kind text NOT NULL,   -- ocr_mismatch_odometer | ocr_mismatch_receipt | odometer_regression | implausible_efficiency | mock_location | orphan_evidence | clock_skew
  subject_type text NOT NULL,
  subject_id uuid NOT NULL,
  media_id uuid REFERENCES media_objects,
  typed_value text,
  ocr_value text,
  context jsonb NOT NULL DEFAULT '{}',
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','accepted_typed','accepted_ocr','corrected','dismissed')),
  resolution jsonb,
  resolved_by uuid,
  resolved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (kind, subject_type, subject_id)
);

-- ───────── infra ─────────
CREATE TABLE idempotency_keys (
  key uuid PRIMARY KEY,
  org_id uuid NOT NULL,
  user_id uuid NOT NULL,
  route text NOT NULL,
  request_hash text NOT NULL,
  response_status int NOT NULL,
  response_body jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);  -- same key + different request_hash → 409 IDEMPOTENCY_CONFLICT

CREATE TABLE outbox (
  id bigserial PRIMARY KEY,
  org_id uuid,
  topic text NOT NULL,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  dispatched_at timestamptz
);
CREATE INDEX ON outbox (id) WHERE dispatched_at IS NULL;

-- RLS: ENABLE ROW LEVEL SECURITY + policy `org_id = current_setting('app.org_id')::uuid`
-- on every table with org_id. The API connects as a non-owner role; migrations use the owner.
