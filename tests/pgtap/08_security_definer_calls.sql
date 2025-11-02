-- /tests/pgtap/08_security_definer_calls.sql — простейшая проверка SECURITY DEFINER функций
SET client_min_messages TO warning;
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
SET search_path = pgtap, app, ref, audit;

SELECT plan(2);

SET ROLE app_writer;

-- 1. Проверяем, что fn_assign_shift_impl работает без ошибок
SELECT lives_ok(
  $$
    SELECT app.fn_assign_shift_impl(1, DATE '2025-09-15', NULL, 'test shift');
  $$,
  'fn_assign_shift_impl выполняется без ошибок'
);

-- 2. Проверяем, что close_incident работает без ошибок
SELECT lives_ok(
  $$
    SELECT app.close_incident(11, '2025-09-01 11:00+00', 'Очаг ликвидирован, проливка и вентиляция выполнены');
  $$,
  'close_incident выполняется без ошибок'
);

SELECT * FROM finish();
