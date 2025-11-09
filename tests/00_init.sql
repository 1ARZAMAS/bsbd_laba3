SET ROLE fireadmin;
SET client_min_messages = warning;
CREATE SCHEMA IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA pgtap;
GRANT USAGE ON SCHEMA pgtap TO PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pgtap TO PUBLIC;

CREATE OR REPLACE FUNCTION sec.clear_session_ctx()
RETURNS void
LANGUAGE plpgsql
SET search_path = sec, public
AS $$
BEGIN
  -- обнуляем локальные GUC-и
  PERFORM set_config('sec.current_segment', '', true);  -- вернёт NULL
  PERFORM set_config('sec.request_id', '', true);
END;
$$;

GRANT EXECUTE ON FUNCTION sec.clear_session_ctx() TO PUBLIC;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'pgtap') THEN
    BEGIN
      EXECUTE 'CREATE SCHEMA pgtap';
    EXCEPTION
      WHEN duplicate_schema THEN
        NULL;
      WHEN unique_violation THEN
        NULL;
    END;
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgtap') THEN
    BEGIN
      EXECUTE 'CREATE EXTENSION pgtap WITH SCHEMA pgtap';
    EXCEPTION
      WHEN duplicate_object THEN
        NULL;
    END;
  END IF;
END$$;

-- кто имеет доступ к сегменту: роль должна совпадать с role_name в ref.segment
CREATE OR REPLACE FUNCTION sec.has_access_to_segment(p_segment_id int)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ref, pg_catalog, public
AS $$
  SELECT EXISTS(
    SELECT 1
    FROM ref.segment s
    WHERE s.id = p_segment_id
      AND s.role_name = current_role::text
  );
$$;

GRANT EXECUTE ON FUNCTION sec.has_access_to_segment(int) TO PUBLIC;

DROP FUNCTION IF EXISTS sec.set_session_ctx(integer,integer);
-- установка контекста только при наличии доступа
CREATE OR REPLACE FUNCTION sec.set_session_ctx(p_segment_id int, p_request_id int)
RETURNS void
LANGUAGE plpgsql
SET search_path = ref, sec, pg_catalog, public
AS $$
BEGIN
  IF NOT EXISTS (
       SELECT 1
       FROM ref.segment s
       WHERE s.id = p_segment_id
         AND s.role_name = current_role::text
     )
  THEN
    RAISE EXCEPTION 'Нет прав на сегмент %', p_segment_id
      USING ERRCODE = '28000';
  END IF;

  PERFORM set_config('sec.current_segment', p_segment_id::text, true);
  PERFORM set_config('sec.request_id',      p_request_id::text, true);
END;
$$;

DO $$
BEGIN
  -- сегмент 1 -> stat_user_1
  IF EXISTS (SELECT 1 FROM ref.segment WHERE id = 1) THEN
    UPDATE ref.segment
       SET role_name = 'stat_user_1'
     WHERE id = 1
       AND role_name IS DISTINCT FROM 'stat_user_1';
  END IF;

  -- сегмент 2 -> stat_user_2 (для проверок "чужого" сегмента)
  IF EXISTS (SELECT 1 FROM ref.segment WHERE id = 2) THEN
    UPDATE ref.segment
       SET role_name = 'stat_user_2'
     WHERE id = 2
       AND role_name IS DISTINCT FROM 'stat_user_2';
  END IF;

  -- если таблица пустая — создадим минимальный набор
  IF NOT EXISTS (SELECT 1 FROM ref.segment) THEN
    INSERT INTO ref.segment(id, name, role_name)
    VALUES (1, 'Segment 1', 'stat_user_1'),
           (2, 'Segment 2', 'stat_user_2');
  END IF;
END$$;

GRANT EXECUTE ON FUNCTION sec.has_access_to_segment(int) TO PUBLIC;
GRANT EXECUTE ON FUNCTION sec.set_session_ctx(int,int) TO PUBLIC;

GRANT USAGE ON SCHEMA pgtap TO PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pgtap TO PUBLIC;

GRANT USAGE ON SCHEMA ref TO PUBLIC;
GRANT SELECT ON ref.segment TO PUBLIC;

RESET ROLE;

SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;

SELECT plan(1);
SELECT ok(true, 'bootstrap: pgtap present and search_path set');

SELECT * FROM finish();