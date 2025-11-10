-- ЛАБА 3
-- SET ROLE firestation_users;
CREATE ROLE firestation_users NOLOGIN;
GRANT firestation_users TO stat_user_1, stat_user_2, stat_user_3, stat_user_4, stat_user_5, stat_user_6, stat_user_7, stat_user_8, stat_user_9, stat_user_10; 
GRANT USAGE ON SCHEMA app TO firestation_users;
GRANT USAGE ON SCHEMA ref TO firestation_users;

GRANT SELECT, UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA app TO firestation_users;
GRANT SELECT ON ALL TABLES IN SCHEMA ref TO firestation_users;

GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA app TO firestation_users;

CREATE INDEX IF NOT EXISTS ix_incidents_segment_station ON app.incidents(segment_id, station_id);
CREATE INDEX IF NOT EXISTS ix_stations_segment_name ON app.stations(segment_id, name);
CREATE INDEX IF NOT EXISTS ix_firefighters_segment_station ON app.firefighters(segment_id, station_id);
CREATE INDEX IF NOT EXISTS ix_firefighters_segment_last_name ON app.firefighters(segment_id, last_name);
CREATE INDEX IF NOT EXISTS ix_vehicles_segment_station ON app.vehicles(segment_id, station_id);
CREATE INDEX IF NOT EXISTS ix_vehicles_segment_plate ON app.vehicles(segment_id, plate_number);
CREATE INDEX IF NOT EXISTS ix_equipment_segment_station ON app.equipment(segment_id, station_id);
CREATE INDEX IF NOT EXISTS ix_shifts_segment_station_date ON app.shifts(segment_id, station_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_segment_role_active ON ref.segment(role_name) WHERE active;

CREATE SCHEMA IF NOT EXISTS sec;

CREATE OR REPLACE FUNCTION sec.current_segment()
RETURNS int
LANGUAGE plpgsql
STABLE
SET search_path = pg_catalog, public, ref, sec
AS $$
DECLARE
  v_guc text;
  v_seg int;
BEGIN
  v_guc := current_setting('sec.current_segment', true);
  IF v_guc IS NOT NULL AND v_guc <> '' THEN
    v_seg := v_guc::int;
    IF sec.has_access_to_segment(v_seg) THEN
      RETURN v_seg; -- доверяем только валидированному GUC
    END IF;
  END IF;

  SELECT s.id
  INTO v_seg
  FROM ref.segment s
  WHERE s.active
    AND (s.role_name = current_user
         OR pg_has_role(current_user, s.role_name, 'member'))
  ORDER BY s.id
  LIMIT 1;

  RETURN v_seg;
END
$$;

CREATE OR REPLACE FUNCTION sec.has_access_to_segment(p_segment_id int)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = pg_catalog, public, ref
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM ref.segment s
    WHERE s.id = p_segment_id
      AND s.active
      AND (s.role_name = current_user
           OR pg_has_role(current_user, s.role_name, 'member'))
  );
$$;

CREATE OR REPLACE FUNCTION sec.set_session_ctx(p_segment_id int, p_actor_id int)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, ref, sec
AS $$
BEGIN
  IF NOT sec.has_access_to_segment(p_segment_id) THEN
    RAISE EXCEPTION 'Нет прав на сегмент %', p_segment_id USING ERRCODE='28000';
  END IF;

  PERFORM set_config('sec.current_segment', p_segment_id::text, true); -- SET LOCAL
  IF p_actor_id IS NOT NULL THEN
    PERFORM set_config('app.actor_id', p_actor_id::text, true);
  END IF;
END
$$;

ALTER FUNCTION sec.set_session_ctx(int, int) SET search_path = pg_catalog, public, pg_temp, sec, ref;

GRANT USAGE ON SCHEMA sec TO firestation_users;
--GRANT EXECUTE ON FUNCTION sec.current_segment() TO firestation_users;
GRANT EXECUTE ON FUNCTION sec.set_session_ctx(int, int) TO firestation_users;
