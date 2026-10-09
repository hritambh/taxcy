-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "org_kind" AS ENUM ('fleet', 'dco');

-- CreateEnum
CREATE TYPE "membership_role" AS ENUM ('owner', 'manager', 'driver');

-- CreateEnum
CREATE TYPE "fuel_type" AS ENUM ('petrol', 'diesel', 'cng', 'petrol_cng');

-- CreateEnum
CREATE TYPE "fuel_kind" AS ENUM ('petrol', 'diesel', 'cng');

-- CreateEnum
CREATE TYPE "audit_track" AS ENUM ('petrol', 'diesel', 'cng', 'bifuel_cost');

-- CreateEnum
CREATE TYPE "trip_type" AS ENUM ('one_way', 'round_trip', 'local_rental');

-- CreateEnum
CREATE TYPE "trip_status" AS ENUM ('created', 'assigned', 'started', 'ended', 'settled', 'cancelled');

-- CreateEnum
CREATE TYPE "booking_channel" AS ENUM ('direct');

-- CreateEnum
CREATE TYPE "doc_type" AS ENUM ('rc', 'insurance', 'permit', 'puc', 'driving_licence');

-- CreateEnum
CREATE TYPE "media_kind" AS ENUM ('odometer', 'fuel_receipt', 'document', 'other');

-- CreateEnum
CREATE TYPE "alert_severity" AS ENUM ('info', 'warning', 'critical');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "phone_e164" TEXT NOT NULL,
    "name" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "organizations" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "kind" "org_kind" NOT NULL,
    "timezone" TEXT NOT NULL DEFAULT 'Asia/Kolkata',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "organizations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "org_settings" (
    "org_id" UUID NOT NULL,
    "fuel_k_sigma" DOUBLE PRECISION NOT NULL DEFAULT 2.0,
    "fuel_min_cycles" INTEGER NOT NULL DEFAULT 3,
    "fuel_pct_threshold" DOUBLE PRECISION NOT NULL DEFAULT 20.0,
    "fuel_ewma_alpha" DOUBLE PRECISION NOT NULL DEFAULT 0.3,
    "odo_gps_tolerance_pct" DOUBLE PRECISION NOT NULL DEFAULT 10.0,
    "doc_alert_days" INTEGER[] DEFAULT ARRAY[30, 7, 1]::INTEGER[],
    "driver_pay_rule" JSONB NOT NULL DEFAULT '{"kind":"none","allowanceToDriver":true}',

    CONSTRAINT "org_settings_pkey" PRIMARY KEY ("org_id")
);

-- CreateTable
CREATE TABLE "memberships" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "roles" "membership_role"[],
    "status" TEXT NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "memberships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "devices" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "platform" TEXT NOT NULL,
    "app_version" TEXT,
    "last_seen_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "devices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "family_id" UUID NOT NULL,
    "token_hash" TEXT NOT NULL,
    "device_id" UUID,
    "expires_at" TIMESTAMPTZ NOT NULL,
    "revoked_at" TIMESTAMPTZ,
    "replaced_by" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media_objects" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "uploaded_by" UUID NOT NULL,
    "kind" "media_kind" NOT NULL,
    "storage_key" TEXT NOT NULL,
    "content_type" TEXT NOT NULL,
    "byte_size" INTEGER,
    "sha256" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "captured_at" TIMESTAMPTZ NOT NULL,
    "capture_location" geography(Point, 4326),
    "capture_accuracy_m" REAL,
    "is_mock_location" BOOLEAN,
    "device_id" UUID,
    "received_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "uploaded_at" TIMESTAMPTZ,

    CONSTRAINT "media_objects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ocr_results" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "media_id" UUID NOT NULL,
    "provider" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "value_numeric" DOUBLE PRECISION,
    "value_text" TEXT,
    "confidence" REAL,
    "raw" JSONB,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ocr_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicle_models" (
    "id" UUID NOT NULL,
    "org_id" UUID,
    "make" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "fuel_type" "fuel_type" NOT NULL,

    CONSTRAINT "vehicle_models_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fuel_baseline_defaults" (
    "id" UUID NOT NULL,
    "org_id" UUID,
    "vehicle_model_id" UUID,
    "track" "audit_track" NOT NULL,
    "mean_value" DOUBLE PRECISION NOT NULL,
    "std_value" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "fuel_baseline_defaults_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicles" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "registration_no" TEXT NOT NULL,
    "vehicle_model_id" UUID,
    "make" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "year" SMALLINT,
    "fuel_type" "fuel_type" NOT NULL,
    "last_odometer_km" INTEGER,
    "status" TEXT NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vehicles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "drivers" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "membership_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "pay_rule" JSONB,
    "status" TEXT NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "drivers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "documents" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "doc_type" "doc_type" NOT NULL,
    "vehicle_id" UUID,
    "driver_id" UUID,
    "number" TEXT,
    "valid_from" DATE,
    "expires_on" DATE NOT NULL,
    "media_id" UUID,
    "superseded_by" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "odometer_readings" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "vehicle_id" UUID NOT NULL,
    "context" TEXT NOT NULL,
    "typed_km" INTEGER NOT NULL,
    "ocr_km" INTEGER,
    "media_id" UUID NOT NULL,
    "captured_at" TIMESTAMPTZ NOT NULL,
    "created_by" UUID NOT NULL,

    CONSTRAINT "odometer_readings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "customers" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "phone_e164" TEXT,
    "user_id" UUID,

    CONSTRAINT "customers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trips" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "trip_type" "trip_type" NOT NULL,
    "status" "trip_status" NOT NULL DEFAULT 'created',
    "channel" "booking_channel" NOT NULL DEFAULT 'direct',
    "customer_id" UUID,
    "from_text" TEXT NOT NULL,
    "from_point" geography(Point, 4326),
    "to_text" TEXT,
    "to_point" geography(Point, 4326),
    "scheduled_start_at" TIMESTAMPTZ NOT NULL,
    "scheduled_end_at" TIMESTAMPTZ NOT NULL,
    "busy_window" tstzrange,
    "vehicle_id" UUID,
    "driver_id" UUID,
    "quoted_fare_paise" BIGINT NOT NULL,
    "start_odometer_id" UUID,
    "end_odometer_id" UUID,
    "started_at" TIMESTAMPTZ,
    "ended_at" TIMESTAMPTZ,
    "cancelled_at" TIMESTAMPTZ,
    "cancel_reason" TEXT,
    "cancellation_fare_paise" BIGINT,
    "version" INTEGER NOT NULL DEFAULT 0,
    "created_by" UUID NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trips_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trip_events" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "trip_id" UUID NOT NULL,
    "seq" INTEGER NOT NULL,
    "event_type" TEXT NOT NULL,
    "from_status" "trip_status",
    "to_status" "trip_status",
    "actor_user_id" UUID,
    "actor_role" "membership_role",
    "occurred_at" TIMESTAMPTZ NOT NULL,
    "recorded_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "payload" JSONB NOT NULL DEFAULT '{}',

    CONSTRAINT "trip_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trip_cancellation_requests" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "trip_id" UUID NOT NULL,
    "requested_by" UUID NOT NULL,
    "requested_role" "membership_role" NOT NULL,
    "reason" TEXT NOT NULL,
    "end_odometer_id" UUID,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "decided_by" UUID,
    "decided_at" TIMESTAMPTZ,
    "decision_note" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trip_cancellation_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trip_charges" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "trip_id" UUID NOT NULL,
    "kind" TEXT NOT NULL,
    "amount_paise" BIGINT NOT NULL,
    "paid_by_driver" BOOLEAN NOT NULL,
    "media_id" UUID,
    "note" TEXT,
    "entered_by" UUID NOT NULL,
    "entered_role" "membership_role" NOT NULL,
    "voided_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trip_charges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fuel_fills" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "vehicle_id" UUID NOT NULL,
    "driver_id" UUID,
    "trip_id" UUID,
    "fuel" "fuel_kind" NOT NULL,
    "quantity_milli" INTEGER NOT NULL,
    "cost_paise" BIGINT NOT NULL,
    "odometer_id" UUID NOT NULL,
    "is_full_tank" BOOLEAN NOT NULL,
    "receipt_media_id" UUID,
    "ocr_cost_paise" BIGINT,
    "ocr_quantity_milli" INTEGER,
    "paid_by" TEXT NOT NULL,
    "filled_at" TIMESTAMPTZ NOT NULL,
    "voided_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "fuel_fills_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fuel_cycles" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "vehicle_id" UUID NOT NULL,
    "track" "audit_track" NOT NULL,
    "opening_fill_id" UUID NOT NULL,
    "closing_fill_id" UUID NOT NULL,
    "distance_km" INTEGER NOT NULL,
    "fuel_milli" INTEGER,
    "cost_paise" BIGINT NOT NULL,
    "metric" TEXT NOT NULL,
    "metric_value" DOUBLE PRECISION,
    "baseline_mean" DOUBLE PRECISION,
    "baseline_std" DOUBLE PRECISION,
    "prior_cycles" INTEGER NOT NULL,
    "method" TEXT NOT NULL,
    "deviation" DOUBLE PRECISION,
    "verdict" TEXT NOT NULL,
    "included_in_baseline" BOOLEAN NOT NULL,
    "computed_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "superseded_at" TIMESTAMPTZ,

    CONSTRAINT "fuel_cycles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicle_fuel_baselines" (
    "vehicle_id" UUID NOT NULL,
    "track" "audit_track" NOT NULL,
    "org_id" UUID NOT NULL,
    "ewma_mean" DOUBLE PRECISION NOT NULL,
    "ewma_var" DOUBLE PRECISION NOT NULL,
    "n_cycles" INTEGER NOT NULL,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vehicle_fuel_baselines_pkey" PRIMARY KEY ("vehicle_id","track")
);

-- CreateTable
CREATE TABLE "trip_distance_checks" (
    "trip_id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "odometer_km" INTEGER NOT NULL,
    "gps_km" DOUBLE PRECISION,
    "points_total" INTEGER,
    "points_used" INTEGER,
    "max_gap_seconds" INTEGER,
    "coverage_ratio" REAL,
    "result" TEXT NOT NULL,
    "computed_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trip_distance_checks_pkey" PRIMARY KEY ("trip_id")
);

-- CreateTable
CREATE TABLE "trip_collections" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "trip_id" UUID NOT NULL,
    "driver_id" UUID NOT NULL,
    "method" TEXT NOT NULL,
    "amount_paise" BIGINT NOT NULL,
    "reference" TEXT,
    "collected_at" TIMESTAMPTZ NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trip_collections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "settlements" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "driver_id" UUID NOT NULL,
    "business_date" DATE NOT NULL,
    "expected_fare_paise" BIGINT NOT NULL,
    "cash_paise" BIGINT NOT NULL,
    "online_paise" BIGINT NOT NULL,
    "driver_expenses_paise" BIGINT NOT NULL,
    "driver_earnings_paise" BIGINT NOT NULL,
    "carried_adjustment_paise" BIGINT NOT NULL DEFAULT 0,
    "net_payable_paise" BIGINT NOT NULL,
    "pay_rule_snapshot" JSONB,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "settled_by" UUID,
    "settled_at" TIMESTAMPTZ,

    CONSTRAINT "settlements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "settlement_lines" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "settlement_id" UUID NOT NULL,
    "ref_type" TEXT NOT NULL,
    "ref_id" UUID NOT NULL,
    "amount_paise" BIGINT NOT NULL,

    CONSTRAINT "settlement_lines_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "alerts" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "kind" TEXT NOT NULL,
    "severity" "alert_severity" NOT NULL,
    "title" TEXT NOT NULL,
    "explanation" TEXT NOT NULL,
    "vehicle_id" UUID,
    "driver_id" UUID,
    "trip_id" UUID,
    "subject_type" TEXT NOT NULL,
    "subject_id" UUID NOT NULL,
    "data" JSONB NOT NULL DEFAULT '{}',
    "dedupe_key" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'open',
    "resolved_by" UUID,
    "resolved_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "alerts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "review_items" (
    "id" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "kind" TEXT NOT NULL,
    "subject_type" TEXT NOT NULL,
    "subject_id" UUID NOT NULL,
    "media_id" UUID,
    "typed_value" TEXT,
    "ocr_value" TEXT,
    "context" JSONB NOT NULL DEFAULT '{}',
    "status" TEXT NOT NULL DEFAULT 'open',
    "resolution" JSONB,
    "resolved_by" UUID,
    "resolved_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "review_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "idempotency_keys" (
    "key" UUID NOT NULL,
    "org_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "route" TEXT NOT NULL,
    "request_hash" TEXT NOT NULL,
    "response_status" INTEGER NOT NULL,
    "response_body" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "idempotency_keys_pkey" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "outbox" (
    "id" BIGSERIAL NOT NULL,
    "org_id" UUID,
    "topic" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dispatched_at" TIMESTAMPTZ,

    CONSTRAINT "outbox_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_e164_key" ON "users"("phone_e164");

-- CreateIndex
CREATE UNIQUE INDEX "memberships_org_id_user_id_key" ON "memberships"("org_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "refresh_tokens_family_id_idx" ON "refresh_tokens"("family_id");

-- CreateIndex
CREATE UNIQUE INDEX "media_objects_storage_key_key" ON "media_objects"("storage_key");

-- CreateIndex
CREATE INDEX "media_objects_org_id_idx" ON "media_objects"("org_id");

-- CreateIndex
CREATE INDEX "ocr_results_media_id_idx" ON "ocr_results"("media_id");

-- CreateIndex
CREATE UNIQUE INDEX "vehicles_org_id_registration_no_key" ON "vehicles"("org_id", "registration_no");

-- CreateIndex
CREATE UNIQUE INDEX "drivers_membership_id_key" ON "drivers"("membership_id");

-- CreateIndex
CREATE INDEX "drivers_org_id_idx" ON "drivers"("org_id");

-- CreateIndex
CREATE INDEX "odometer_readings_vehicle_id_captured_at_idx" ON "odometer_readings"("vehicle_id", "captured_at");

-- CreateIndex
CREATE INDEX "trips_org_id_status_scheduled_start_at_idx" ON "trips"("org_id", "status", "scheduled_start_at");

-- CreateIndex
CREATE INDEX "trips_driver_id_scheduled_start_at_idx" ON "trips"("driver_id", "scheduled_start_at");

-- CreateIndex
CREATE UNIQUE INDEX "trip_events_trip_id_seq_key" ON "trip_events"("trip_id", "seq");

-- CreateIndex
CREATE INDEX "trip_cancellation_requests_trip_id_idx" ON "trip_cancellation_requests"("trip_id");

-- CreateIndex
CREATE INDEX "trip_charges_trip_id_idx" ON "trip_charges"("trip_id");

-- CreateIndex
CREATE INDEX "fuel_fills_vehicle_id_filled_at_idx" ON "fuel_fills"("vehicle_id", "filled_at");

-- CreateIndex
CREATE INDEX "fuel_cycles_vehicle_id_track_idx" ON "fuel_cycles"("vehicle_id", "track");

-- CreateIndex
CREATE INDEX "trip_collections_trip_id_idx" ON "trip_collections"("trip_id");

-- CreateIndex
CREATE UNIQUE INDEX "settlements_org_id_driver_id_business_date_key" ON "settlements"("org_id", "driver_id", "business_date");

-- CreateIndex
CREATE UNIQUE INDEX "settlement_lines_ref_type_ref_id_key" ON "settlement_lines"("ref_type", "ref_id");

-- CreateIndex
CREATE INDEX "alerts_org_id_status_created_at_idx" ON "alerts"("org_id", "status", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "alerts_org_id_dedupe_key_key" ON "alerts"("org_id", "dedupe_key");

-- CreateIndex
CREATE INDEX "review_items_org_id_status_created_at_idx" ON "review_items"("org_id", "status", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "review_items_kind_subject_type_subject_id_key" ON "review_items"("kind", "subject_type", "subject_id");

-- AddForeignKey
ALTER TABLE "org_settings" ADD CONSTRAINT "org_settings_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "devices" ADD CONSTRAINT "devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_replaced_by_fkey" FOREIGN KEY ("replaced_by") REFERENCES "refresh_tokens"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ocr_results" ADD CONSTRAINT "ocr_results_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media_objects"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_vehicle_model_id_fkey" FOREIGN KEY ("vehicle_model_id") REFERENCES "vehicle_models"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "drivers" ADD CONSTRAINT "drivers_membership_id_fkey" FOREIGN KEY ("membership_id") REFERENCES "memberships"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "odometer_readings" ADD CONSTRAINT "odometer_readings_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "odometer_readings" ADD CONSTRAINT "odometer_readings_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media_objects"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trips" ADD CONSTRAINT "trips_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trips" ADD CONSTRAINT "trips_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trip_events" ADD CONSTRAINT "trip_events_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trip_charges" ADD CONSTRAINT "trip_charges_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_fills" ADD CONSTRAINT "fuel_fills_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_fills" ADD CONSTRAINT "fuel_fills_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_fills" ADD CONSTRAINT "fuel_fills_odometer_id_fkey" FOREIGN KEY ("odometer_id") REFERENCES "odometer_readings"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trip_collections" ADD CONSTRAINT "trip_collections_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trip_collections" ADD CONSTRAINT "trip_collections_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "drivers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "settlement_lines" ADD CONSTRAINT "settlement_lines_settlement_id_fkey" FOREIGN KEY ("settlement_id") REFERENCES "settlements"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
