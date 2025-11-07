SET search_path = tap, public, ref, app, sec, audit, pg_temp;
SET client_min_messages = warning;

SELECT plan(8);
SET search_path = tap, public, ref, app, sec, audit, pg_temp;

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

-- 3–8) индексы по segment_id существуют
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_incidents_segment'),
  'ix_incidents_segment exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_stations_segment'),
  'ix_stations_segment exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_firefighters_segment'),
  'ix_firefighters_segment exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_vehicles_segment'),
  'ix_vehicles_segment exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_equipment_segment'),
  'ix_equipment_segment exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='app' AND indexname='ix_shifts_segment'),
  'ix_shifts_segment exists'
);

SELECT * FROM finish();
