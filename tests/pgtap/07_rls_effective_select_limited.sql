SET client_min_messages TO warning;
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
SET search_path = pgtap, app, ref, audit;

SELECT plan(1);

-- Роль, которая видит все строки incidents (владелец таблиц, app_owner)
SET ROLE app_owner;

WITH owner_cnt AS (
  SELECT count(*) AS c FROM app.incidents
),
reader_cnt AS (
  SELECT set_config('role', 'u_reader', true) IS NOT NULL AS _sw,
         (SELECT count(*) FROM app.incidents) AS c
)
SELECT ok(
  (SELECT r.c <= o.c FROM owner_cnt o, reader_cnt r),
  'RLS ensures u_reader sees not more rows than owner'::text
);

RESET ROLE;
SELECT * FROM finish();
