-- ЛАБА 3
-- SET ROLE firestation_users;
CREATE ROLE firestation_users NOLOGIN;
GRANT firestation_users TO stat_user_1, stat_user_2, stat_user_3, stat_user_4, stat_user_5, stat_user_6, stat_user_7, stat_user_8, stat_user_9, stat_user_10; 
GRANT USAGE ON SCHEMA app TO firestation_users;
GRANT USAGE ON SCHEMA ref TO firestation_users;
--GRANT USAGE ON SCHEMA app TO stat_user_1;
--GRANT USAGE ON SCHEMA ref TO stat_user_1;

GRANT SELECT, UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA app TO firestation_users;
GRANT SELECT ON ALL TABLES IN SCHEMA ref TO firestation_users;

GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA app TO firestation_users;


CREATE SCHEMA IF NOT EXISTS sec;

CREATE OR REPLACE FUNCTION sec.current_segment()
RETURNS int
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    NULLIF(current_setting('app.current_segment', true), '')::int,
    (
      SELECT s.id
      FROM ref.segment s
      WHERE pg_has_role(current_user, s.role_name, 'member')
      ORDER BY s.id
      LIMIT 1
    )
  )
$$;

CREATE OR REPLACE FUNCTION sec.has_access_to_segment(p_segment_id int)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
    SELECT EXISTS (
      SELECT 1
      FROM ref.segment s
      WHERE s.id = p_segment_id
          AND (
              s.role_name = current_user
            OR pg_has_role(current_user, s.role_name, 'member')
          )
    );
$$;

-- Установка текущего сегмента 
CREATE OR REPLACE FUNCTION sec.set_current_segment(p_segment_id int)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT sec.has_access_to_segment(p_segment_id) THEN
    RAISE EXCEPTION 'Нет прав на сегмент %', p_segment_id USING ERRCODE = '28000';
  END IF;

  -- FALSE -> значение сохраняется на сессию
  PERFORM set_config('app.current_segment', p_segment_id::text, false);
END
$$;

ALTER FUNCTION sec.set_current_segment(int) SET search_path = public, pg_temp, sec, ref;


GRANT USAGE ON SCHEMA sec TO firestation_users;
GRANT EXECUTE ON FUNCTION sec.current_segment() TO firestation_users;
GRANT EXECUTE ON FUNCTION sec.set_current_segment(int) TO firestation_users;
GRANT EXECUTE ON FUNCTION sec.has_access_to_segment(int) TO firestation_users;

CREATE INDEX IF NOT EXISTS ix_incidents_segment ON app.incidents(segment_id);
CREATE INDEX IF NOT EXISTS ix_stations_segment ON app.stations(segment_id);
CREATE INDEX IF NOT EXISTS ix_firefighters_segment ON app.firefighters(segment_id);
CREATE INDEX IF NOT EXISTS ix_vehicles_segment ON app.vehicles(segment_id);
CREATE INDEX IF NOT EXISTS ix_equipment_segment ON app.equipment(segment_id);
CREATE INDEX IF NOT EXISTS ix_shifts_segment ON app.shifts(segment_id);
CREATE INDEX IF NOT EXISTS ix_responses_segment ON app.responses(segment_id);