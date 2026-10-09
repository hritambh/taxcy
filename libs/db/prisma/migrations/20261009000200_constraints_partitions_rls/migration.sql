-- Hand-written: everything Prisma can't express. See docs/database.md#prisma-notes.

-- ───────── trips: generated busy window + double-booking protection ─────────
ALTER TABLE trips DROP COLUMN busy_window;
ALTER TABLE trips ADD COLUMN busy_window tstzrange
  GENERATED ALWAYS AS (tstzrange(scheduled_start_at, scheduled_end_at, '[)')) STORED;

ALTER TABLE trips
  ADD CONSTRAINT trips_vehicle_no_overlap
    EXCLUDE USING gist (vehicle_id WITH =, busy_window WITH &&) WHERE (status IN ('assigned', 'started')),
  ADD CONSTRAINT trips_driver_no_overlap
    EXCLUDE USING gist (driver_id WITH =, busy_window WITH &&) WHERE (status IN ('assigned', 'started'));

-- ───────── CHECK constraints ─────────
ALTER TABLE memberships ADD CONSTRAINT memberships_roles_nonempty CHECK (cardinality(roles) > 0),
  ADD CONSTRAINT memberships_status_check CHECK (status IN ('invited', 'active', 'suspended'));
ALTER TABLE media_objects ADD CONSTRAINT media_objects_status_check CHECK (status IN ('pending', 'uploaded', 'rejected'));
ALTER TABLE ocr_results ADD CONSTRAINT ocr_results_status_check CHECK (status IN ('ok', 'unreadable', 'error'));
ALTER TABLE vehicles ADD CONSTRAINT vehicles_status_check CHECK (status IN ('active', 'inactive'));
ALTER TABLE drivers ADD CONSTRAINT drivers_status_check CHECK (status IN ('active', 'inactive'));
ALTER TABLE documents
  ADD CONSTRAINT documents_one_subject CHECK ((vehicle_id IS NULL) <> (driver_id IS NULL)),
  ADD CONSTRAINT documents_dl_on_driver CHECK ((doc_type = 'driving_licence') = (driver_id IS NOT NULL));
ALTER TABLE odometer_readings
  ADD CONSTRAINT odometer_readings_context_check CHECK (context IN ('trip_start', 'trip_end', 'fuel_fill', 'adhoc')),
  ADD CONSTRAINT odometer_readings_km_check CHECK (typed_km >= 0);
ALTER TABLE trips
  ADD CONSTRAINT trips_schedule_check CHECK (scheduled_end_at > scheduled_start_at),
  ADD CONSTRAINT trips_fare_check CHECK (quoted_fare_paise >= 0),
  ADD CONSTRAINT trips_cancellation_fare_check CHECK (cancellation_fare_paise >= 0),
  ADD CONSTRAINT trips_assignment_check CHECK (
    status NOT IN ('assigned', 'started', 'ended', 'settled') OR (vehicle_id IS NOT NULL AND driver_id IS NOT NULL));
ALTER TABLE trip_cancellation_requests
  ADD CONSTRAINT trip_cancellation_requests_reason_check CHECK (length(trim(reason)) > 0),
  ADD CONSTRAINT trip_cancellation_requests_status_check CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn'));
ALTER TABLE trip_charges
  ADD CONSTRAINT trip_charges_kind_check CHECK (
    kind IN ('toll', 'parking', 'state_tax', 'driver_allowance', 'night_charge', 'extra_km', 'other')),
  ADD CONSTRAINT trip_charges_amount_check CHECK (amount_paise >= 0);
ALTER TABLE fuel_fills
  ADD CONSTRAINT fuel_fills_quantity_check CHECK (quantity_milli > 0),
  ADD CONSTRAINT fuel_fills_cost_check CHECK (cost_paise >= 0),
  ADD CONSTRAINT fuel_fills_paid_by_check CHECK (paid_by IN ('driver_cash', 'owner', 'fuel_card'));
ALTER TABLE fuel_cycles
  ADD CONSTRAINT fuel_cycles_metric_check CHECK (metric IN ('km_per_unit', 'paise_per_km')),
  ADD CONSTRAINT fuel_cycles_method_check CHECK (method IN ('sigma', 'percent')),
  ADD CONSTRAINT fuel_cycles_verdict_check CHECK (verdict IN ('ok', 'flagged', 'invalid'));
ALTER TABLE trip_distance_checks
  ADD CONSTRAINT trip_distance_checks_result_check CHECK (result IN ('ok', 'flagged', 'inconclusive'));
ALTER TABLE trip_collections
  ADD CONSTRAINT trip_collections_method_check CHECK (method IN ('cash', 'upi', 'card')),
  ADD CONSTRAINT trip_collections_amount_check CHECK (amount_paise >= 0);
ALTER TABLE settlements ADD CONSTRAINT settlements_status_check CHECK (status IN ('draft', 'settled'));
ALTER TABLE settlement_lines ADD CONSTRAINT settlement_lines_ref_type_check CHECK (
  ref_type IN ('trip', 'trip_charge', 'collection', 'fuel_fill', 'adjustment'));
ALTER TABLE alerts ADD CONSTRAINT alerts_status_check CHECK (status IN ('open', 'acknowledged', 'resolved', 'dismissed'));
ALTER TABLE review_items ADD CONSTRAINT review_items_status_check CHECK (
  status IN ('open', 'accepted_typed', 'accepted_ocr', 'corrected', 'dismissed'));

-- ───────── partial unique indexes ─────────
CREATE UNIQUE INDEX fuel_cycles_current_closing_fill ON fuel_cycles (closing_fill_id) WHERE superseded_at IS NULL;
CREATE UNIQUE INDEX trip_cancellation_requests_one_pending ON trip_cancellation_requests (trip_id) WHERE status = 'pending';
CREATE UNIQUE INDEX fuel_baseline_defaults_scope ON fuel_baseline_defaults (org_id, vehicle_model_id, track) NULLS NOT DISTINCT;
CREATE INDEX documents_current_expiry ON documents (org_id, expires_on) WHERE superseded_by IS NULL;
CREATE INDEX outbox_undispatched ON outbox (id) WHERE dispatched_at IS NULL;

-- ───────── gps_points: monthly range partitions ─────────
CREATE TABLE gps_points (
  org_id uuid NOT NULL,
  trip_id uuid NOT NULL,
  driver_id uuid NOT NULL,
  client_point_id uuid NOT NULL,
  recorded_at timestamptz NOT NULL,
  location geography(Point, 4326) NOT NULL,
  accuracy_m real,
  speed_mps real,
  heading real,
  is_mock boolean NOT NULL DEFAULT false,
  received_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (recorded_at, client_point_id)
) PARTITION BY RANGE (recorded_at);
CREATE TABLE gps_points_default PARTITION OF gps_points DEFAULT;
CREATE INDEX gps_points_trip_id_recorded_at_idx ON gps_points (trip_id, recorded_at);
-- Monthly partitions (gps_points_YYYY_MM) are created ahead of time by the gps-partitions job.

-- ───────── privileges for the application role ─────────
GRANT USAGE ON SCHEMA public TO taxcy_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO taxcy_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO taxcy_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO taxcy_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO taxcy_app;
-- Partition maintenance (CREATE TABLE … PARTITION OF / DROP) runs as the app role.
GRANT CREATE ON SCHEMA public TO taxcy_app;

-- ───────── row-level security ─────────
-- A row is visible when its org matches app.org_id (set per transaction by the API),
-- or when app.bypass_rls = 'on' (system jobs that work across orgs, and login lookups
-- that happen before an org is chosen). This is a backstop behind the repository
-- layer's own org scoping, not a replacement for it.
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'org_settings', 'memberships', 'refresh_tokens', 'media_objects', 'ocr_results',
    'vehicle_models', 'fuel_baseline_defaults', 'vehicles', 'drivers', 'documents',
    'odometer_readings', 'customers', 'trips', 'trip_events', 'trip_cancellation_requests',
    'trip_charges', 'fuel_fills', 'fuel_cycles', 'vehicle_fuel_baselines', 'gps_points',
    'trip_distance_checks', 'trip_collections', 'settlements', 'settlement_lines', 'alerts',
    'review_items', 'idempotency_keys', 'outbox'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY tenant_isolation ON %I USING (%s) WITH CHECK (%s)', t,
      'org_id = NULLIF(current_setting(''app.org_id'', true), '''')::uuid OR current_setting(''app.bypass_rls'', true) = ''on''',
      'org_id = NULLIF(current_setting(''app.org_id'', true), '''')::uuid OR current_setting(''app.bypass_rls'', true) = ''on''');
  END LOOP;
END
$$;

-- Global reference rows (org_id IS NULL) are readable by every org.
CREATE POLICY global_reference_rows ON vehicle_models FOR SELECT USING (org_id IS NULL);
CREATE POLICY global_reference_rows ON fuel_baseline_defaults FOR SELECT USING (org_id IS NULL);
