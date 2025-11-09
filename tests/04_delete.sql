SET client_min_messages = warning;
SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;

SELECT plan(2);

SET ROLE stat_user_1;
SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;

BEGIN;

SELECT sec.set_session_ctx(
  (SELECT id FROM ref.segment WHERE role_name = current_role),
  1401
);

-- (1) своё удаляется без ошибок
SELECT lives_ok($$
  WITH s AS (
    SELECT station_id
    FROM app.stations
    WHERE segment_id = sec.current_segment()
    ORDER BY station_id
    LIMIT 1
  ),
  ins AS (
    INSERT INTO app.incidents(station_id, segment_id, incident_type, priority, location, reported_at, description)
    SELECT s.station_id, sec.current_segment(), 'Пожар', 'low', 'ул. Простая, 1', now(), 'OWN-DEL'
    FROM s
    RETURNING incident_id
  )
  DELETE FROM app.incidents i
  USING ins
  WHERE i.incident_id = ins.incident_id
$$, 'delete own row succeeds');

-- (2) чужое не трогается: удалённых строк = 0
WITH del AS (
  DELETE FROM app.incidents
  WHERE segment_id <> sec.current_segment()
  RETURNING 1
)
SELECT is(
  (SELECT count(*)::bigint FROM del),
  0::bigint,
  'delete of foreign rows affects 0 rows'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
