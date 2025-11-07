SET search_path = tap, public, ref, app, sec, audit, pg_temp;
SET client_min_messages = warning;
SELECT plan(5);

SET ROLE stat_user_1;
SET search_path = tap, public, ref, app, sec, audit, pg_temp;

-- 1) fallback current_segment() без локального GUC (clear), должен вернуть сегмент по роли
BEGIN;
SELECT sec.clear_session_ctx();

SELECT ok(sec.current_segment() IS NOT NULL, 'fallback current_segment() (by role) is not null');

ROLLBACK;

-- 2) has_access_to_segment(): свой сегмент → true
SELECT ok(
  sec.has_access_to_segment((SELECT id FROM ref.segment WHERE role_name = current_role)),
  'has_access_to_segment() is true for own segment'
);

-- 3) has_access_to_segment(): чужой сегмент → false
SELECT ok(
  NOT sec.has_access_to_segment((SELECT id FROM ref.segment WHERE role_name <> current_role LIMIT 1)),
  'has_access_to_segment() is false for foreign segment'
);

-- 4) set_session_ctx(): успех на своём сегменте
BEGIN;
SELECT lives_ok($$
  SELECT sec.set_session_ctx(
    (SELECT id FROM ref.segment WHERE role_name = current_role),
    4001
  );
$$, 'set_session_ctx succeeds for own segment');
ROLLBACK;

-- 5) set_session_ctx(): отказ на чужом сегменте
BEGIN;
SELECT throws_ok($$
  SELECT sec.set_session_ctx(
    (SELECT id FROM ref.segment WHERE role_name <> current_role LIMIT 1),
    4002
  );
$$, '.*(Нет прав на сегмент|28000).*', 'set_session_ctx fails for foreign segment');
ROLLBACK;

RESET ROLE;

SELECT * FROM finish();
