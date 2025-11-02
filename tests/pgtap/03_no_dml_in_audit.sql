-- db/tests/pgtap/03_no_dml_in_audit.sql
SET client_min_messages TO warning;
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
SET search_path = pgtap, app, ref, audit;

-- helpers
CREATE OR REPLACE FUNCTION pg_temp.sql_throws_like(q text, pattern text) RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE m text; d text; BEGIN EXECUTE q; RETURN false; EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS m = MESSAGE_TEXT, 
d = PG_EXCEPTION_DETAIL; RETURN (m ~ pattern) OR (coalesce(d,'') ~ pattern); END$$;

SELECT plan(1);

SET ROLE u_auditor;

SELECT ok(
  pg_temp.sql_throws_like($$
    INSERT INTO audit.login_log(username, client_ip) VALUES ('x','127.0.0.1')
  $$, 'permission denied'),
  'u_auditor cannot INSERT into audit.login_log'
);

RESET ROLE;
SELECT * FROM finish();
