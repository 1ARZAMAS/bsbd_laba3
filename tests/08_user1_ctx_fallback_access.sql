SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;
SET client_min_messages = warning;
SELECT plan(5);

SET ROLE stat_user_1;
SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;

-- 1) fallback current_segment() без локального GUC (clear), должен вернуть сегмент по роли
BEGIN;
SAVEPOINT sp_ctx;
SELECT sec.clear_session_ctx();

SELECT ok(sec.current_segment() IS NOT NULL, 'fallback current_segment() (by role) is not null');

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
SELECT lives_ok($$
  SELECT sec.set_session_ctx(
    (SELECT id FROM ref.segment WHERE role_name = current_role),
    4001
  );
$$, 'set_session_ctx succeeds for own segment');

-- 5) set_session_ctx(): отказ на чужом сегменте
SELECT throws_ok($$
  SELECT sec.set_session_ctx(
    (SELECT id FROM ref.segment WHERE role_name <> current_role LIMIT 1),
    4002
  );
$$, 'Нет прав на сегмент 2', 'set_session_ctx fails for foreign segment');

RESET ROLE;

SELECT * FROM finish();

ROLLBACK TO SAVEPOINT sp_ctx;  -- откатываем только свои изменения
RELEASE SAVEPOINT sp_ctx;