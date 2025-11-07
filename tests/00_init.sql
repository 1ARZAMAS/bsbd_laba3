SET ROLE fireadmin;
SET client_min_messages = warning;
CREATE SCHEMA IF NOT EXISTS tap;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA tap;

CREATE OR REPLACE FUNCTION sec.clear_session_ctx()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
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
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'tap') THEN
    BEGIN
      EXECUTE 'CREATE SCHEMA tap';
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
      EXECUTE 'CREATE EXTENSION pgtap WITH SCHEMA tap';
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
SECURITY DEFINER
SET search_path = ref, pg_catalog, public
AS $$
  SELECT EXISTS(
    SELECT 1
    FROM ref.segment s
    WHERE s.id = p_segment_id
      AND (
           -- основной путь: роль сегмента равна активной роли
           s.role_name = current_role::text
           -- запасной путь: активная роль состоит в роли сегмента
        OR pg_has_role(current_role, s.role_name, 'USAGE')
      )
  );
$$;

GRANT EXECUTE ON FUNCTION sec.has_access_to_segment(int) TO PUBLIC;

-- установка контекста только при наличии доступа
CREATE OR REPLACE FUNCTION sec.set_session_ctx(p_segment_id int, p_request_id int)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ref, sec, pg_catalog, public
AS $$
BEGIN
  -- Явная проверка доступа: активная роль должна соответствовать записи сегмента
  IF NOT EXISTS (
       SELECT 1
       FROM ref.segment s
       WHERE s.id = p_segment_id
         AND (
              s.role_name = current_role::text
           OR pg_has_role(current_role, s.role_name, 'USAGE')
         )
     )
  THEN
    RAISE EXCEPTION 'Нет прав на сегмент %', p_segment_id
      USING ERRCODE = '28000';
  END IF;

  -- Устанавливаем контекст
  PERFORM set_config('sec.current_segment', p_segment_id::text, true);
  PERFORM set_config('sec.request_id',      p_request_id::text, true);
END;
$$;

GRANT EXECUTE ON FUNCTION sec.has_access_to_segment(int) TO PUBLIC;
GRANT EXECUTE ON FUNCTION sec.set_session_ctx(int,int) TO PUBLIC;

GRANT USAGE ON SCHEMA tap TO PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA tap TO PUBLIC;

GRANT USAGE ON SCHEMA ref TO PUBLIC;
GRANT SELECT ON ref.segment TO PUBLIC;

SET search_path = tap, public, ref, app, sec, audit, pg_temp;

SELECT plan(1);
SELECT ok(true, 'bootstrap: pgtap present and search_path set');

SELECT * FROM finish();