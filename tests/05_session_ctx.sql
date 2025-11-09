SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;
SET client_min_messages = warning;
SELECT plan(3);

SET ROLE stat_user_1;
SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;

BEGIN;

-- 1) set_session_ctx: успех
SELECT lives_ok($$
  SELECT sec.set_session_ctx(
    (SELECT id FROM ref.segment WHERE role_name = current_role),
    2002
  );
$$, 'set_session_ctx succeeds for own segment');

-- проверка контекста
SELECT ok(sec.current_segment() IS NOT NULL, 'current_segment() set after set_session_ctx');

-- 2) set_session_ctx: отказ на чужом сегменте
SELECT throws_ok($$
  SELECT sec.set_session_ctx(
    (SELECT id FROM ref.segment WHERE role_name <> current_role LIMIT 1),
    2003
  );
$$, 'Нет прав на сегмент 2', 'set_session_ctx fails for foreign segment');

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;