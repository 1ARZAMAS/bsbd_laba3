-- db/tests/pgtap/01_read_access.sql
SET client_min_messages TO warning;
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
SET search_path = pgtap, app, ref, audit;

CREATE OR REPLACE FUNCTION pg_temp.sql_lives(q text) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN EXECUTE q; RETURN true; EXCEPTION WHEN OTHERS THEN RETURN false; END$$;
CREATE OR REPLACE FUNCTION pg_temp.sql_throws_like(q text, pattern text) RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE m text; d text; BEGIN EXECUTE q; RETURN false; EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS m = MESSAGE_TEXT, 
  d = PG_EXCEPTION_DETAIL; RETURN (m ~ pattern) OR (coalesce(d,'') ~ pattern); END$$;

SELECT plan(2);

SET ROLE u_reader;

SELECT pgtap.ok(
  pg_temp.sql_lives($sql$
    SELECT incident_id, station_id, incident_type, priority,
           reported_at, dispatched_at, cleared_at
    FROM app.incidents
    LIMIT 1
  $sql$),
  'u_reader can read allowed columns from app.incidents'::text
);

SELECT pgtap.ok(
  pg_temp.sql_throws_like($$ SELECT email FROM app.firefighters LIMIT 1 $$, 'permission denied'),
  'u_reader cannot select firefighters.email'::text
);

RESET ROLE;
SELECT * FROM finish();
