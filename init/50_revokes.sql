-- Владелец может видеть и добавлять любые строки
CREATE POLICY admin_all ON app.firefighters TO app_owner USING (true) WITH CHECK (true);
CREATE POLICY admin_all ON app.incidents TO app_owner USING (true) WITH CHECK (true);

CREATE POLICY firefighters_select
    ON app.firefighters
    FOR SELECT
    TO app_reader, app_writer
    USING (true);

CREATE POLICY incidents_select
    ON app.incidents
    FOR SELECT
    TO app_reader, app_writer
    USING (true);

REVOKE SELECT ON app.firefighters FROM app_reader;
REVOKE SELECT ON app.firefighters FROM app_writer;

REVOKE SELECT ON app.incidents FROM app_reader;
REVOKE SELECT ON app.incidents FROM app_writer;

GRANT SELECT
    (firefighter_id, station_id, rank_id, hire_date)
ON app.firefighters TO app_reader;

GRANT SELECT 
    (firefighter_id, station_id, rank_id, hire_date)
ON app.firefighters TO app_writer;

GRANT SELECT
    (incident_id, station_id, incident_type, priority, reported_at, dispatched_at, cleared_at)
ON app.incidents TO app_reader;

GRANT SELECT 
    (incident_id, station_id, incident_type, priority, reported_at, dispatched_at, cleared_at)
ON app.incidents TO app_writer;


-- Разрешаем writer вставлять любые строки
CREATE POLICY incidents_insert
  ON app.incidents
  FOR INSERT
  TO app_writer, dml_admin
  WITH CHECK (true);

-- USING — какие строки можно читать/обновлять; WITH CHECK — какими они могут стать
CREATE POLICY incidents_update
  ON app.incidents
  FOR UPDATE
  TO app_writer, dml_admin
  USING (true)
  WITH CHECK (true);

CREATE POLICY incidents_delete
ON app.incidents
FOR DELETE
TO dml_admin
USING (true);

GRANT INSERT, UPDATE, DELETE ON app.incidents TO app_writer;