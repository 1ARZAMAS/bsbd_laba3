--UPDATE
CREATE POLICY rls_incidents_upd ON app.incidents
AS PERMISSIVE
FOR UPDATE
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.incidents.segment_id = sec.current_segment())
)
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

-- STATIONS
CREATE POLICY rls_stations_upd ON app.stations
AS PERMISSIVE
FOR UPDATE
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.stations.segment_id = sec.current_segment())
)
WITH CHECK (
  (sec.current_segment() IS NOT NULL AND app.stations.segment_id = sec.current_segment())
);

-- FIREFIGHTERS
CREATE POLICY rls_firefighters_upd ON app.firefighters
AS PERMISSIVE
FOR UPDATE
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.firefighters.segment_id = sec.current_segment())
)
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
CREATE POLICY rls_vehicles_upd ON app.vehicles
AS PERMISSIVE
FOR UPDATE
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.vehicles.segment_id = sec.current_segment())
)
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
CREATE POLICY rls_equipment_upd ON app.equipment
AS PERMISSIVE
FOR UPDATE 
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.equipment.segment_id = sec.current_segment())
)
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
CREATE POLICY rls_responses_upd ON app.responses
AS PERMISSIVE
FOR UPDATE
TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.responses.segment_id = sec.current_segment())
)
WITH CHECK (
  -- тот же сегмент, что у инцидента
  EXISTS (
    SELECT 1 FROM app.incidents i
    WHERE i.incident_id = app.responses.incident_id
      AND i.segment_id  = app.responses.segment_id
  )
  -- vehicle из того же сегмента
  AND (
    app.responses.vehicle_id IS NULL OR
    EXISTS (SELECT 1 FROM app.vehicles v
            WHERE v.vehicle_id = app.responses.vehicle_id
              AND v.segment_id  = app.responses.segment_id)
  )
  -- firefighter из того же сегмента
  AND (
    app.responses.firefighter_id IS NULL OR
    EXISTS (SELECT 1 FROM app.firefighters f
            WHERE f.firefighter_id = app.responses.firefighter_id
              AND f.segment_id      = app.responses.segment_id)
  )
  AND (
    (sec.current_segment() IS NOT NULL AND app.responses.segment_id = sec.current_segment())
  )
);

-- SHIFTS
CREATE POLICY rls_shifts_upd ON app.shifts
AS PERMISSIVE
FOR UPDATE TO firestation_users
USING (
  (sec.current_segment() IS NOT NULL AND app.shifts.segment_id = sec.current_segment())
)
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

