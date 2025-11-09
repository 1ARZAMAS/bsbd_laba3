GRANT USAGE ON SCHEMA app TO auditor;
GRANT SELECT ON ALL TABLES IN SCHEMA app TO auditor;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO auditor;

-- SELECT
-- INCIDENTS
CREATE POLICY rls_incidents_auditor ON app.incidents
AS PERMISSIVE
FOR SELECT
TO auditor
USING (true);

-- STATIONS
CREATE POLICY rls_stations_auditor ON app.stations
AS PERMISSIVE
FOR SELECT
TO auditor
USING (true);

-- FIREFIGHTERS
CREATE POLICY rls_firefighters_auditor ON app.firefighters
AS PERMISSIVE
FOR SELECT
TO auditor
USING (true);

-- VEHICLES
CREATE POLICY rls_vehicles_auditor ON app.vehicles
AS PERMISSIVE
FOR SELECT
TO auditor
USING (true);

-- EQUIPMENT
CREATE POLICY rls_equipment_auditor ON app.equipment
AS PERMISSIVE
FOR SELECT
TO auditor
USING (true);

-- RESPONSES
CREATE POLICY rls_responses_auditor ON app.responses
AS PERMISSIVE
FOR SELECT
TO auditor
USING (true);

-- SHIFTS
CREATE POLICY rls_shifts_auditor ON app.shifts
AS PERMISSIVE
FOR SELECT
TO auditor
USING (true);