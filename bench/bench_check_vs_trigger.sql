\set ON_ERROR_STOP 1
\timing on

-- сколько строк вставляем
\set rows 10000

-- работаем под владельцем, чтобы не упереться в RLS/GRANT
SET ROLE app_owner;

-- чистим перед замером
TRUNCATE app.shifts_check RESTART IDENTITY;
TRUNCATE app.shifts_trg   RESTART IDENTITY;
TRUNCATE audit.shift_violations;

-- (необязательно) прогрев статистики
VACUUM ANALYZE app.shifts_check;
VACUUM ANALYZE app.shifts_trg;

\echo '=== TRIGGER: insert :rows rows into app.shifts_trg ==='
INSERT INTO app.shifts_trg(firefighter_id, start_at, end_at, note)
SELECT
  1 + (gs % 50) AS firefighter_id,
  now() + make_interval(hours => (gs % 24)),
  now() + make_interval(hours => (gs % 24) + 8 + (gs % 3)),
  'trg-10k'
FROM generate_series(1, :rows) AS gs;

\echo '=== CHECK: insert :rows rows into app.shifts_check ==='
INSERT INTO app.shifts_check(firefighter_id, start_at, end_at, note)
SELECT
  1 + (gs % 50) AS firefighter_id,
  now() + make_interval(hours => (gs % 24)),
  now() + make_interval(hours => (gs % 24) + 8 + (gs % 3)),
  'check-10k'
FROM generate_series(1, :rows) AS gs;

-- контроль
SELECT 'audit_violations', count(*) FROM audit.shift_violations;
SELECT 'rows_in_shifts_check', count(*) FROM app.shifts_check;
SELECT 'rows_in_shifts_trg',   count(*) FROM app.shifts_trg;

RESET ROLE;
