-- Runs once when the local Postgres volume is created (docker-entrypoint-initdb.d),
-- and in integration tests before migrations.
--
-- taxcy_app  : NOLOGIN group role that migrations grant table privileges to.
-- taxcy_api  : LOGIN role the API and workers connect as. Not a superuser and not
--              the table owner, so row-level security policies apply to it.
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'taxcy_app') THEN
    CREATE ROLE taxcy_app NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'taxcy_api') THEN
    CREATE ROLE taxcy_api LOGIN PASSWORD 'taxcy_api' IN ROLE taxcy_app;
  END IF;
END
$$;
