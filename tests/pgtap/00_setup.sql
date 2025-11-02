SET client_min_messages TO warning;

-- 1) pgTAP как было
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
GRANT USAGE ON SCHEMA pgtap TO u_reader, u_auditor, u_writer, app_owner, app_writer, dml_admin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pgtap TO u_reader, u_auditor, u_writer, app_owner, app_writer, dml_admin;

-- 2) Схемы должны принадлежать app_owner (иначе владельцу неудобно создавать/грантить)
CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS audit;
ALTER SCHEMA app   OWNER TO app_owner;
ALTER SCHEMA audit OWNER TO app_owner;

-- 3) ВСЕ служебные объекты создаём под владельцем данных
SET ROLE app_owner;

-- аудит для триггерной версии
CREATE TABLE IF NOT EXISTS audit.shift_violations (
  violation_id   bigserial PRIMARY KEY,
  occurred_at    timestamptz NOT NULL DEFAULT now(),
  firefighter_id bigint,
  start_at       timestamptz,
  end_at         timestamptz,
  reason         text
);

-- CHECK-вариант смен
CREATE TABLE IF NOT EXISTS app.shifts_check (
  shift_id       bigserial PRIMARY KEY,
  firefighter_id bigint NOT NULL,
  start_at       timestamptz NOT NULL,
  end_at         timestamptz NOT NULL,
  note           text,
  CONSTRAINT shifts_check_time_ok CHECK (
    end_at >= start_at
    AND end_at <= start_at + interval '24 hours'
  )
);

-- TRIGGER-вариант смен
CREATE TABLE IF NOT EXISTS app.shifts_trg (
  shift_id       bigserial PRIMARY KEY,
  firefighter_id bigint NOT NULL,
  start_at       timestamptz NOT NULL,
  end_at         timestamptz NOT NULL,
  note           text
);

CREATE OR REPLACE FUNCTION app.fn_validate_shift()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.end_at < NEW.start_at THEN
    INSERT INTO audit.shift_violations(firefighter_id, start_at, end_at, reason)
    VALUES (NEW.firefighter_id, NEW.start_at, NEW.end_at, 'end_at < start_at');
    RAISE EXCEPTION 'Shift end_at (% ) earlier than start_at (%)', NEW.end_at, NEW.start_at
      USING ERRCODE = '23514';
  ELSIF NEW.end_at > NEW.start_at + interval '24 hours' THEN
    INSERT INTO audit.shift_violations(firefighter_id, start_at, end_at, reason)
    VALUES (NEW.firefighter_id, NEW.start_at, NEW.end_at, 'duration > 24h');
    RAISE EXCEPTION 'Shift duration exceeds 24h (start %, end %)', NEW.start_at, NEW.end_at
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_shift_biu ON app.shifts_trg;
CREATE TRIGGER trg_validate_shift_biu
BEFORE INSERT OR UPDATE ON app.shifts_trg
FOR EACH ROW
EXECUTE FUNCTION app.fn_validate_shift();

-- 4) Права на схемы/таблицы (теперь мы владелец, GRANT сработает)
GRANT USAGE ON SCHEMA app   TO u_reader, u_auditor, u_writer, app_writer, dml_admin;
GRANT USAGE ON SCHEMA audit TO u_reader, u_auditor, u_writer, app_writer, dml_admin;

-- для тестов чтения
GRANT SELECT (
  incident_id, station_id, incident_type, priority,
  reported_at, dispatched_at, cleared_at
) ON app.incidents TO u_reader;
GRANT SELECT ON app.incidents TO u_reader;

GRANT SELECT (
  firefighter_id, station_id, rank_id, hire_date
) ON app.firefighters TO u_reader;

-- для сравнения CHECK vs TRIGGER
GRANT INSERT ON audit.shift_violations TO app_owner, app_writer;  -- триггер пишет аудит
-- app_owner владеет shifts_* → отдельные GRANT INSERT ему не нужны, но можно явно:
-- GRANT INSERT ON app.shifts_check TO app_owner;
-- GRANT INSERT ON app.shifts_trg   TO app_owner;

RESET ROLE;

-- 5) TAP-план
SET search_path = pgtap, app, audit;
SELECT no_plan();

SELECT has_schema('app',   'schema app exists');
SELECT has_schema('audit', 'schema audit exists');
SELECT has_table('app','incidents','app.incidents exists');
SELECT has_table('app','firefighters','app.firefighters exists');
SELECT has_table('app','shifts_check','app.shifts_check exists');
SELECT has_table('app','shifts_trg','app.shifts_trg exists');
SELECT has_table('audit','shift_violations','audit.shift_violations exists');

SELECT * FROM finish();
