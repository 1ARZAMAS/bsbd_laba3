SET client_min_messages TO warning;
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
SET search_path = pgtap, app, ref, audit;

SELECT plan(1);

SET ROLE u_reader;

SELECT lives_ok(
  $sql$
    SELECT incident_id, station_id, incident_type, priority,
           reported_at, dispatched_at, cleared_at
    FROM app.incidents
    LIMIT 1
  $sql$::text,
  'u_reader can select allowed columns from app.incidents'::text
);

RESET ROLE;
SELECT * FROM finish();
