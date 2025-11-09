SET client_min_messages = warning;
SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;
SELECT plan(2);

SET ROLE stat_user_1;
SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;

BEGIN;

-- 1) OK UPDATE в своём сегменте
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 1201);

SELECT lives_ok($$
  WITH t AS (
    SELECT incident_id
    FROM app.incidents
    WHERE segment_id = sec.current_segment()
    ORDER BY incident_id LIMIT 1
  )
  UPDATE app.incidents i
     SET description = 'RLS OK (update)'
  FROM t
  WHERE i.incident_id = t.incident_id;
$$, 'update in own segment succeeds');

-- 2) BAD UPDATE: перевод строки в чужой сегмент → ОШИБКА (WITH CHECK)
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 1202);

SELECT throws_ok($$
  WITH t AS (
    SELECT incident_id
    FROM app.incidents
    WHERE segment_id = sec.current_segment()
    ORDER BY incident_id LIMIT 1
  ),
  other AS (
    SELECT id AS seg_id
    FROM ref.segment
    WHERE id <> sec.current_segment()
    ORDER BY id LIMIT 1
  )
  UPDATE app.incidents i
     SET segment_id = (SELECT seg_id FROM other)
  FROM t
  WHERE i.incident_id = t.incident_id;
$$, 'new row violates row-level security policy for table "incidents"', 'update to foreign segment_id fails');

RESET ROLE;

SELECT * FROM finish();

ROLLBACK;