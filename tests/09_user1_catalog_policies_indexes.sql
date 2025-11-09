SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;
SET client_min_messages = warning;

SELECT plan(10);
SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;

BEGIN;
SAVEPOINT sp_ctx;

-- 1) на ключевых таблицах включён RLS
WITH rels AS (
  SELECT n.nspname, c.relname, c.relrowsecurity, c.relforcerowsecurity
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'app'
    AND c.relname IN ('incidents','stations','firefighters','vehicles','equipment','shifts')
)
SELECT ok(
  (SELECT bool_and(relrowsecurity) FROM rels),
  'RLS enabled on key tables'
);

-- 2) на ключевых таблицах включён Force RLS
WITH rels AS (
  SELECT n.nspname, c.relname, c.relrowsecurity, c.relforcerowsecurity
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'app'
    AND c.relname IN ('incidents','stations','firefighters','vehicles','equipment','shifts')
)
SELECT ok(
  (SELECT bool_and(relforcerowsecurity) FROM rels),
  'Force RLS enabled on key tables'
);

-- 3–10) индексы по segment_id существуют
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_incidents_segment_station'),
  'ix_incidents_segment_station exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_stations_segment_name'),
  'ix_stations_segment_name exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_firefighters_segment_station'),
  'ix_firefighters_segment_station exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_firefighters_segment_last_name'),
  'ix_firefighters_segment_last_name exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_vehicles_segment_station'),
  'ix_vehicles_segment_station exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_vehicles_segment_plate'),
  'ix_vehicles_segment_plate exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_equipment_segment_station'),
  'ix_equipment_segment_station exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_shifts_segment_station_date'),
  'ix_shifts_segment_station_date exists'
);

SELECT * FROM finish();

ROLLBACK TO SAVEPOINT sp_ctx;  -- откатываем только свои изменения
RELEASE SAVEPOINT sp_ctx;