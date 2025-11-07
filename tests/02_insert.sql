SET client_min_messages = warning;
SET search_path = tap, public, ref, app, sec, audit, pg_temp;
SELECT plan(2);

SET ROLE stat_user_1;
SET search_path = tap, public, ref, app, sec, audit, pg_temp;

-- 1) BAD INSERT: своя станция + чужой сегмент → ОШИБКА (WITH CHECK)
BEGIN;
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 1101);

SELECT throws_ok($$
  WITH mine AS (
    SELECT station_id
    FROM app.stations
    WHERE segment_id = sec.current_segment()
    LIMIT 1
  ),
  other AS (
    SELECT id AS seg_id
    FROM ref.segment
    WHERE id <> sec.current_segment()
    LIMIT 1
  )
  INSERT INTO app.incidents(station_id, segment_id, incident_type, priority, location, reported_at, description)
  SELECT mine.station_id, other.seg_id, 'Пожар', 'high', 'ул. Чужая, 13', now(), 'RLS SHOULD FAIL (insert)'
  FROM mine, other;
$$, '.*row-level security policy.*', 'insert with wrong segment_id fails');
ROLLBACK;

-- 2) OK INSERT: всё в своём сегменте
BEGIN;
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 1102);

SELECT lives_ok($$
  WITH s AS (
    SELECT station_id
    FROM app.stations
    WHERE segment_id = sec.current_segment()
    ORDER BY station_id LIMIT 1
  )
  INSERT INTO app.incidents(station_id, segment_id, incident_type, priority, location, reported_at, description)
  SELECT s.station_id, sec.current_segment(), 'Пожар', 'high', 'ул. Тестовая, 1', now(), 'RLS OK (insert)'
  FROM s;
$$, 'insert in own segment succeeds');

ROLLBACK;
RESET ROLE;

SELECT * FROM finish();
