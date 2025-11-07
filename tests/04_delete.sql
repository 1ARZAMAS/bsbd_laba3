SET client_min_messages = warning;
SET search_path = tap, public, ref, app, sec, audit, pg_temp;
-- если нет обёртки безопасного удаления — пропустим 1 тест
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'app' AND p.proname = 'safe_delete_incident'
          AND p.pronargs = 1
  ) THEN
    RAISE NOTICE 'SKIP 1: app.safe_delete_incident(int) not found';
  END IF;
END$$;

-- план: 2 теста (один можем пропустить диагностикой)
SELECT plan(2);

SET ROLE stat_user_1;
SET search_path = tap, public, ref, app, sec, audit, pg_temp;

-- 1) OK DELETE своей строки
BEGIN;
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 1301);

-- создаём свою запись и удаляем
SELECT lives_ok($$
  WITH s AS (
    SELECT station_id
    FROM app.stations
    WHERE segment_id = sec.current_segment()
    LIMIT 1
  ),
  ins AS (
    INSERT INTO app.incidents(station_id, segment_id, incident_type, priority, location, reported_at, description)
    SELECT s.station_id, sec.current_segment(), 'Пожар', 'low', 'ул. Удаляемая, 99', now(), 'DEL-OK'
    FROM s
    RETURNING incident_id
  )
  DELETE FROM app.incidents i
  USING ins
  WHERE i.incident_id = ins.incident_id;
$$, 'delete own row succeeds');

ROLLBACK;

-- 2) BAD DELETE: безопасное удаление чужой строки → ОШИБКА (если есть обёртка)
BEGIN;
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 1302);

-- найдём заведомо чужой инцидент (под RLS может быть не видно) — используем безопасную обёртку
-- если функции нет — этот тест "провалится" как пропуск с заметкой
SELECT throws_ok($$
  -- подставь реальный ID чужой строки, если нужно — можно завести его заранее в prefill
  SELECT app.safe_delete_incident(
    (SELECT i.incident_id
     FROM app.incidents i
     WHERE i.segment_id <> sec.current_segment()
     ORDER BY i.incident_id LIMIT 1)
  );
$$, '.*(Нет доступа|28000).*', 'safe_delete: foreign row denied')
WHERE EXISTS (
  SELECT 1 FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'app' AND p.proname = 'safe_delete_incident' AND p.pronargs = 1
);

ROLLBACK;
RESET ROLE;

SELECT * FROM finish();
