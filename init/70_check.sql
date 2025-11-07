-- Вариант A: CHECK
CREATE TABLE app.shifts_check (
  shift_id bigserial PRIMARY KEY,
  firefighter_id bigint NOT NULL,
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  note text,
  CONSTRAINT shifts_check_time_ok CHECK (
    end_at >= start_at
    AND end_at <= start_at + interval '24 hours'
  )
);

SET ROLE fireadmin;
GRANT USAGE ON SCHEMA audit TO app_owner;

CREATE TABLE IF NOT EXISTS audit.function_calls (
    call_time  timestamptz DEFAULT now(),
    function_name text NOT NULL,
    caller_role  text NOT NULL,
    input_params jsonb,
    success      boolean
);
GRANT USAGE ON SCHEMA audit TO u_auditor;
GRANT SELECT ON TABLE audit.function_calls TO u_auditor;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT SELECT ON TABLES TO u_auditor;

GRANT SELECT ON TABLE audit.function_calls TO auditor;

ALTER FUNCTION audit.log_connection()
    SET search_path = 'audit';