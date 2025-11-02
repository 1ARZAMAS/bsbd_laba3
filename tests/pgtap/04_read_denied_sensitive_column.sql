-- db/tests/pgtap/04_read_denied_sensitive_column.sql
SET client_min_messages TO warning;
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
SET search_path = pgtap, app, ref, audit;

SELECT plan(1);

SET ROLE u_reader;

SELECT throws_ok(
  $$ SELECT email FROM app.firefighters LIMIT 1 $$::text,
  '42501'::text,  -- insufficient_privilege
  'permission denied for table firefighters'::text
);

RESET ROLE;
SELECT * FROM finish();
