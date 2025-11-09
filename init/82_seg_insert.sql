--INSERT
-- INCIDENTS
CREATE POLICY rls_incidents_insert ON app.incidents
AS PERMISSIVE
FOR INSERT
TO firestation_users
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM app.stations st
    WHERE st.station_id = app.incidents.station_id
      AND st.segment_id = app.incidents.segment_id
  )
  AND (
    (sec.current_segment() IS NOT NULL AND app.incidents.segment_id = sec.current_segment())
  )
);

-- FIREFIGHTERS
CREATE POLICY rls_firefighters_insert ON app.firefighters
AS PERMISSIVE
FOR INSERT 
TO firestation_users
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM app.stations st
    WHERE st.station_id = app.firefighters.station_id
      AND st.segment_id = app.firefighters.segment_id
  )
  AND (
    (sec.current_segment() IS NOT NULL AND app.firefighters.segment_id = sec.current_segment())
  )
);

-- VEHICLES
CREATE POLICY rls_vehicles_insert ON app.vehicles
AS PERMISSIVE
FOR INSERT 
TO firestation_users
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM app.stations st
    WHERE st.station_id = app.vehicles.station_id
      AND st.segment_id = app.vehicles.segment_id
  )
  AND (
    (sec.current_segment() IS NOT NULL AND app.vehicles.segment_id = sec.current_segment())
  )
);

-- EQUIPMENT
CREATE POLICY rls_equipment_insert ON app.equipment
AS PERMISSIVE
FOR INSERT 
TO firestation_users
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM app.stations st
    WHERE st.station_id = app.equipment.station_id
      AND st.segment_id = app.equipment.segment_id
  )
  AND (
    (sec.current_segment() IS NOT NULL AND app.equipment.segment_id = sec.current_segment())
  )
);

-- RESPONSES
CREATE POLICY rls_responses_insert ON app.responses
AS PERMISSIVE
FOR INSERT 
TO firestation_users
WITH CHECK (
  -- инцидент из того же сегмента
  EXISTS (
    SELECT 1 FROM app.incidents i
    WHERE i.incident_id = app.responses.incident_id
      AND i.segment_id  = app.responses.segment_id
  )
  -- если указан автомобиль — он из того же сегмента
  AND (
    app.responses.vehicle_id IS NULL OR
    EXISTS (
      SELECT 1 FROM app.vehicles v
      WHERE v.vehicle_id = app.responses.vehicle_id
        AND v.segment_id  = app.responses.segment_id
    )
  )
  -- если указан пожарный — он из того же сегмента
  AND (
    app.responses.firefighter_id IS NULL OR
    EXISTS (
      SELECT 1 FROM app.firefighters f
      WHERE f.firefighter_id = app.responses.firefighter_id
        AND f.segment_id      = app.responses.segment_id
    )
  )
  -- доступ к самому сегменту
  AND (
    (sec.current_segment() IS NOT NULL AND app.responses.segment_id = sec.current_segment())
  )
);

-- SHIFTS
CREATE POLICY rls_shifts_insert ON app.shifts
AS PERMISSIVE
FOR INSERT 
TO firestation_users
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM app.stations st
    WHERE st.station_id = app.shifts.station_id
      AND st.segment_id = app.shifts.segment_id
  )
  AND (
    (sec.current_segment() IS NOT NULL AND app.shifts.segment_id = sec.current_segment())
  )
);