-- Km included in the quoted fare (e.g. a 300 km package). Optional.
ALTER TABLE "trips" ADD COLUMN "included_km" INTEGER;
ALTER TABLE "trips" ADD CONSTRAINT trips_included_km_positive CHECK (included_km IS NULL OR included_km > 0);
