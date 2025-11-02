-- db/tests/pgtap/02_no_ddl_for_nonadmin.sql
SET client_min_messages TO warning;
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
SET search_path = pgtap, app, ref, audit;

-- helper
CREATE OR REPLACE FUNCTION pg_temp.sql_throws_like(q text, pattern text)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE m text; d text;
BEGIN
  EXECUTE q;
  RETURN false;
EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS m = MESSAGE_TEXT, d = PG_EXCEPTION_DETAIL;
  RETURN (m ~ pattern) OR (coalesce(d,'') ~ pattern);
END$$;

SELECT plan(2);

SET ROLE u_writer;
SELECT pgtap.ok(
  pg_temp.sql_throws_like($$ CREATE TABLE app.tmp_ddl_test(id int) $$, 'permission denied'),
  'u_writer cannot CREATE TABLE in app schema'::text
);

SET ROLE dml_admin;
SELECT pgtap.ok(
  pg_temp.sql_throws_like($$ CREATE TABLE app.tmp_ddl_test2(id int) $$, 'permission denied'),
  'dml_admin cannot CREATE TABLE in app schema'::text
);

RESET ROLE;
SELECT * FROM finish();
