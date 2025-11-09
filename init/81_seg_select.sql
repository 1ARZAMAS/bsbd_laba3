-- SELECT
-- INCIDENTS
CREATE POLICY rls_incident_select ON app.incidents
AS PERMISSIVE
FOR SELECT
TO firestation_users
USING (
    (sec.current_segment() IS NOT NULL AND segment_id = sec.current_segment())
);

-- STATIONS
CREATE POLICY rls_stations_select ON app.stations
AS PERMISSIVE
FOR SELECT
TO firestation_users
USING (
    (sec.current_segment() IS NOT NULL AND segment_id = sec.current_segment()) 
);

-- FIREFIGHTERS
CREATE POLICY rls_firefighters_select ON app.firefighters
AS PERMISSIVE
FOR SELECT
TO firestation_users
USING (
    (sec.current_segment() IS NOT NULL AND segment_id = sec.current_segment())
);

-- VEHICLES
CREATE POLICY rls_vehicles_select ON app.vehicles
AS PERMISSIVE
FOR SELECT
TO firestation_users
USING (
    (sec.current_segment() IS NOT NULL AND segment_id = sec.current_segment()) 
);

-- EQUIPMENT
CREATE POLICY rls_equipment_select ON app.equipment
AS PERMISSIVE
FOR SELECT
TO firestation_users
USING (
    (sec.current_segment() IS NOT NULL AND segment_id = sec.current_segment())
);

-- RESPONSES
CREATE POLICY rls_responses_select ON app.responses
AS PERMISSIVE
FOR SELECT
TO firestation_users
USING (
    (sec.current_segment() IS NOT NULL AND segment_id = sec.current_segment()) 
);

-- SHIFTS
CREATE POLICY rls_shifts_select ON app.shifts
AS PERMISSIVE
FOR SELECT
TO firestation_users
USING (
    (sec.current_segment() IS NOT NULL AND segment_id = sec.current_segment()) 
);
