SET client_min_messages TO warning;
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
SET search_path = pgtap, app, ref, audit;

SELECT plan(4);

-- incidents
SELECT results_eq(
  $$
  SELECT relrowsecurity FROM pg_catalog.pg_class
  WHERE oid = 'app.incidents'::regclass
  $$,
  $$ VALUES (true) $$,
  'RLS enabled on app.incidents'::text
);

SELECT results_eq(
  $$
  SELECT relforcerowsecurity FROM pg_catalog.pg_class
  WHERE oid = 'app.incidents'::regclass
  $$,
  $$ VALUES (true) $$,
  'FORCE RLS enabled on app.incidents'::text
);

-- firefighters
SELECT results_eq(
  $$
  SELECT relrowsecurity FROM pg_catalog.pg_class
  WHERE oid = 'app.firefighters'::regclass
  $$,
  $$ VALUES (true) $$,
  'RLS enabled on app.firefighters'::text
);

SELECT results_eq(
  $$
  SELECT relforcerowsecurity FROM pg_catalog.pg_class
  WHERE oid = 'app.firefighters'::regclass
  $$,
  $$ VALUES (true) $$,
  'FORCE RLS enabled on app.firefighters'::text
);

SELECT * FROM finish();
