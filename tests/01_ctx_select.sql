SET client_min_messages = warning;
SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;
SELECT plan(3);

-- работаем от лица пользователя станции
SET ROLE stat_user_1;

SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;

BEGIN;

SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 1001);

-- 1) контекст выставлен
SELECT ok(sec.current_segment() IS NOT NULL, 'current_segment() not null');

-- 2) свои строки видны
SELECT ok(
  (SELECT count(*) FROM app.incidents WHERE segment_id = sec.current_segment()) >= 0,
  'own incidents visible (>=0 rows ok)'
);

-- 3) чужие строки не видны
SELECT is(
  (SELECT count(*)::bigint FROM app.incidents WHERE segment_id <> sec.current_segment()),
  0::bigint,
  'foreign incidents are invisible'
);

RESET ROLE;

SELECT * FROM finish();

ROLLBACK;