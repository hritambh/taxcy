-- Partition maintenance for gps_points, callable by the app role.
-- Creating or dropping partitions requires owning gps_points, which the app role
-- deliberately doesn't, so these run as SECURITY DEFINER (owned by the migration role).

-- Ensures the monthly partition containing `month_start` exists. Rows that already
-- landed in the DEFAULT partition for that month (points synced before the partition
-- was created) are moved into it.
CREATE OR REPLACE FUNCTION ensure_gps_partition(month_start date)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  from_ts date := date_trunc('month', month_start)::date;
  to_ts date := (date_trunc('month', month_start) + interval '1 month')::date;
  part text := format('gps_points_%s', to_char(from_ts, 'YYYY_MM'));
BEGIN
  IF to_regclass(part) IS NOT NULL THEN
    RETURN part;
  END IF;
  EXECUTE format('CREATE TABLE %I (LIKE gps_points INCLUDING DEFAULTS INCLUDING CONSTRAINTS)', part);
  EXECUTE format(
    'WITH moved AS (DELETE FROM gps_points_default WHERE recorded_at >= %L AND recorded_at < %L RETURNING *)
     INSERT INTO %I SELECT * FROM moved', from_ts, to_ts, part);
  EXECUTE format('ALTER TABLE gps_points ATTACH PARTITION %I FOR VALUES FROM (%L) TO (%L)', part, from_ts, to_ts);
  RETURN part;
END
$$;

-- Drops monthly partitions that end on or before `before_month` (retention).
CREATE OR REPLACE FUNCTION drop_gps_partitions_before(before_month date)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  part record;
  dropped integer := 0;
BEGIN
  FOR part IN
    SELECT c.relname
    FROM pg_inherits i
    JOIN pg_class c ON c.oid = i.inhrelid
    WHERE i.inhparent = 'gps_points'::regclass
      AND c.relname ~ '^gps_points_[0-9]{4}_[0-9]{2}$'
      AND to_date(substring(c.relname from 12), 'YYYY_MM') + interval '1 month' <= date_trunc('month', before_month)
  LOOP
    EXECUTE format('DROP TABLE %I', part.relname);
    dropped := dropped + 1;
  END LOOP;
  RETURN dropped;
END
$$;

REVOKE ALL ON FUNCTION ensure_gps_partition(date) FROM PUBLIC;
REVOKE ALL ON FUNCTION drop_gps_partitions_before(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION ensure_gps_partition(date) TO taxcy_app;
GRANT EXECUTE ON FUNCTION drop_gps_partitions_before(date) TO taxcy_app;
