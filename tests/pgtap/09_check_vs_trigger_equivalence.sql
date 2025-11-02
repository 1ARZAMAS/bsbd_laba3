SET client_min_messages TO warning;
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
SET search_path = pgtap, app, audit;

-- helpers
CREATE OR REPLACE FUNCTION pg_temp.sql_lives(q text) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN EXECUTE q; RETURN true; EXCEPTION WHEN OTHERS THEN RETURN false; END$$;
CREATE OR REPLACE FUNCTION pg_temp.sql_throws(q text) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN EXECUTE q; RETURN false; EXCEPTION WHEN OTHERS THEN RETURN true; END$$;

SELECT plan(6);

-- ВАЖНО: вставки выполняем под ролью с INSERT в app.*
SET ROLE app_owner;

-- валидные интервалы проходят
SELECT pgtap.ok(pg_temp.sql_lives($$
  INSERT INTO app.shifts_check(firefighter_id, start_at, end_at)
  VALUES (1, now(), now() + interval '8 hours')
$$), 'CHECK: valid shift accepted');

SELECT pgtap.ok(pg_temp.sql_lives($$
  INSERT INTO app.shifts_trg(firefighter_id, start_at, end_at)
  VALUES (1, now(), now() + interval '8 hours')
$$), 'TRIGGER: valid shift accepted');

-- end_at < start_at отвергается
SELECT pgtap.ok(pg_temp.sql_throws($$
  INSERT INTO app.shifts_check(firefighter_id, start_at, end_at)
  VALUES (1, now(), now() - interval '1 hour')
$$), 'CHECK: end<start rejected');

SELECT pgtap.ok(pg_temp.sql_throws($$
  INSERT INTO app.shifts_trg(firefighter_id, start_at, end_at)
  VALUES (1, now(), now() - interval '1 hour')
$$), 'TRIGGER: end<start rejected');

-- >24h отвергается
SELECT pgtap.ok(pg_temp.sql_throws($$
  INSERT INTO app.shifts_check(firefighter_id, start_at, end_at)
  VALUES (1, now(), now() + interval '25 hours')
$$), 'CHECK: >24h rejected');

SELECT pgtap.ok(pg_temp.sql_throws($$
  INSERT INTO app.shifts_trg(firefighter_id, start_at, end_at)
  VALUES (1, now(), now() + interval '25 hours')
$$), 'TRIGGER: >24h rejected');

RESET ROLE;
SELECT * FROM finish();
