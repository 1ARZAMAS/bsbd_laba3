-- DELETE
-- INCIDENTS
CREATE POLICY rls_incidents_del ON app.incidents
AS PERMISSIVE
FOR DELETE 
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.incidents.segment_id = sec.current_segment())
);

-- FIREFIGHTERS
CREATE POLICY rls_firefighters_del ON app.firefighters
AS PERMISSIVE
FOR DELETE
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.firefighters.segment_id = sec.current_segment())
);

-- VEHICLES
CREATE POLICY rls_vehicles_del ON app.vehicles
AS PERMISSIVE
FOR DELETE
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.vehicles.segment_id = sec.current_segment())
);

-- EQUIPMENT
CREATE POLICY rls_equipment_del ON app.equipment
AS PERMISSIVE
FOR DELETE
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.equipment.segment_id = sec.current_segment())
);

-- RESPONSES
CREATE POLICY rls_responses_del ON app.responses
AS PERMISSIVE
FOR DELETE
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.responses.segment_id = sec.current_segment())
);

-- SHIFTS
CREATE POLICY rls_shifts_del ON app.shifts
AS PERMISSIVE
FOR DELETE
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.shifts.segment_id = sec.current_segment())
);
