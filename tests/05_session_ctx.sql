SET search_path = tap, public, ref, app, sec, audit, pg_temp;
SET client_min_messages = warning;
SELECT plan(2);

SET ROLE stat_user_1;
SET search_path = tap, public, ref, app, sec, audit, pg_temp;

-- 1) set_session_ctx: успех
BEGIN;
SELECT lives_ok($$
  SELECT sec.set_session_ctx(
    (SELECT id FROM ref.segment WHERE role_name = current_role),
    2002
  );
$$, 'set_session_ctx succeeds for own segment');

-- проверка контекста
SELECT ok(sec.current_segment() IS NOT NULL, 'current_segment() set after set_session_ctx');
ROLLBACK;

-- 2) set_session_ctx: отказ на чужом сегменте
BEGIN;
SELECT throws_ok($$
  SELECT sec.set_session_ctx(
    (SELECT id FROM ref.segment WHERE role_name <> current_role LIMIT 1),
    2003
  );
$$, '.*(Нет прав на сегмент|28000).*', 'set_session_ctx fails for foreign segment');

ROLLBACK;
RESET ROLE;

SELECT * FROM finish();
