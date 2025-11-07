SELECT sec.set_current_segment( (SELECT id FROM ref.segment WHERE role_name = 'stat_user_1') );

ROLLBACK;
BEGIN;
SELECT sec.set_session_ctx(
  (SELECT id FROM ref.segment WHERE role_name = current_role),
  1001
);
