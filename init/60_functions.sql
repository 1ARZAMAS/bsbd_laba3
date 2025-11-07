-- ЛАБА 2
SET ROLE app_owner;

CREATE OR REPLACE FUNCTION app.fn_assign_shift_impl(
  p_firefighter_id integer,
  p_shift_date date,
  p_station_id integer DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS integer
SECURITY DEFINER
SET search_path = pg_catalog, public, app, audit
LANGUAGE plpgsql
AS $$
DECLARE
    v_shift_id integer;
    v_station_id integer;
    eff_role text := COALESCE(NULLIF(current_setting('role', true), ''), session_user);
    v_call_time timestamptz := now();
BEGIN
    BEGIN
        IF eff_role NOT IN ('app_writer', 'dml_admin') THEN
            RAISE EXCEPTION 'Access denied: writer/dml_admin role required'
              USING HINT = 'Обратитесь к security_admin для выдачи роли.';
        END IF;

        IF p_firefighter_id IS NULL OR p_shift_date IS NULL THEN
            RAISE EXCEPTION 'firefighter_id and shift_date are required'
              USING ERRCODE = '22004', DETAIL = 'Переданы NULL параметры.';
        END IF;

        PERFORM 1 FROM app.firefighters WHERE firefighter_id = p_firefighter_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Firefighter % not found', p_firefighter_id;
        END IF;

        IF p_station_id IS NOT NULL THEN
            PERFORM 1 FROM app.stations WHERE station_id = p_station_id;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Station % not found', p_station_id;
            END IF;
            v_station_id := p_station_id;
        ELSE
            SELECT station_id INTO v_station_id
            FROM app.firefighters
            WHERE firefighter_id = p_firefighter_id;

            IF v_station_id IS NULL THEN
                RAISE EXCEPTION 'Не удалось определить станцию сотрудника %', p_firefighter_id;
            END IF;
        END IF;

        INSERT INTO app.shifts(firefighter_id, shift_date, station_id, notes)
        VALUES (p_firefighter_id, p_shift_date, v_station_id, NULLIF(btrim(p_notes), ''))
        ON CONFLICT (firefighter_id, shift_date) DO UPDATE
           SET station_id = EXCLUDED.station_id,
               notes = COALESCE(NULLIF(btrim(EXCLUDED.notes), ''), app.shifts.notes)
        RETURNING shift_id INTO v_shift_id;

        INSERT INTO audit.function_calls(call_time, function_name, caller_role, input_params, success)
        VALUES (v_call_time, 'fn_assign_shift_impl', eff_role,
                jsonb_build_object(
                    'p_firefighter_id', p_firefighter_id,
                    'p_shift_date', p_shift_date,
                    'p_station_id', p_station_id,
                    'p_notes', p_notes
                ), true);

        RETURN v_shift_id;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit.function_calls(call_time, function_name, caller_role, input_params, success)
        VALUES (v_call_time, 'fn_assign_shift_impl', eff_role,
                jsonb_build_object(
                    'p_firefighter_id', p_firefighter_id,
                    'p_shift_date', p_shift_date,
                    'p_station_id', p_station_id,
                    'p_notes', p_notes
                ), false);
        RAISE;
    END;
END;
$$;

REVOKE ALL ON FUNCTION app.fn_assign_shift_impl(integer,date, integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.fn_assign_shift_impl(integer,date,integer, text) TO app_writer, dml_admin;

-- SELECT app.fn_assign_shift_impl(5, '2025-09-03', 2, 'Дневная смена');
-- SELECT app.fn_assign_shift_impl(5, '2025-09-04', NULL, 'Ночная смена');


-- Безопасное закрытие инцидента
CREATE OR REPLACE FUNCTION app.close_incident(
    p_incident_id integer,
    p_cleared_at timestamptz,
    p_comment text DEFAULT NULL
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, app, ref, audit
AS $$
DECLARE
    eff_role text := COALESCE(NULLIF(current_setting('role', true), ''), session_user);
    v_call_time timestamptz := now();
    v_rep timestamptz;
    v_disp timestamptz;
    v_curr_clear timestamptz;
    v_max_assigned timestamptz;
    v_max_arrived timestamptz;
    v_updated integer := 0;
BEGIN
    -- доступ только для писателей данных
    IF eff_role NOT IN ('app_writer', 'dml_admin') THEN
        RAISE EXCEPTION 'Access denied: writer/dml_admin role required'
          USING HINT = 'Обратитесь к security_admin для выдачи роли.';
    END IF;

        IF p_incident_id IS NULL OR p_cleared_at IS NULL THEN
            RAISE EXCEPTION 'incident_id and cleared_at are required'
              USING ERRCODE='22004', DETAIL='Переданы NULL параметры.';
        END IF;

    -- берём инцидент на эксклюзивную блокировку
    SELECT reported_at, dispatched_at, cleared_at
      INTO v_rep, v_disp, v_curr_clear
    FROM app.incidents
    WHERE incident_id = p_incident_id
    FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Инцидент % не найден', p_incident_id
              USING ERRCODE='02000';
        END IF;

        IF v_curr_clear IS NOT NULL THEN
            RAISE EXCEPTION 'Инцидент % уже закрыт (%). Повторное закрытие невозможно.',
                            p_incident_id, v_curr_clear
              USING ERRCODE='22023';
        END IF;

    -- базовая хронология относительно самого инцидента
    IF v_rep  IS NOT NULL AND p_cleared_at < v_rep  THEN
        RAISE EXCEPTION 'cleared_at (%) раньше reported_at (%)', p_cleared_at, v_rep
          USING ERRCODE='22007';
    END IF;
    IF v_disp IS NOT NULL AND p_cleared_at < v_disp THEN
        RAISE EXCEPTION 'cleared_at (%) раньше dispatched_at (%)', p_cleared_at, v_disp
          USING ERRCODE='22007';
    END IF;

        SELECT max(assigned_at), max(arrived_at)
          INTO v_max_assigned, v_max_arrived
        FROM app.responses
        WHERE incident_id = p_incident_id;

        IF v_max_assigned IS NOT NULL AND p_cleared_at < v_max_assigned THEN
            RAISE EXCEPTION 'cleared_at (%) раньше максимального assigned_at (%) среди участников',
                            p_cleared_at, v_max_assigned
              USING ERRCODE='22007';
        END IF;

        IF v_max_arrived IS NOT NULL AND p_cleared_at < v_max_arrived THEN
            RAISE EXCEPTION 'cleared_at (%) раньше максимального arrived_at (%) среди участников',
                            p_cleared_at, v_max_arrived
              USING ERRCODE='22007';
        END IF;

        UPDATE app.responses r
           SET cleared_at = p_cleared_at
         WHERE r.incident_id = p_incident_id
           AND r.cleared_at IS NULL
           AND (r.assigned_at IS NULL OR r.assigned_at <= p_cleared_at)
           AND (r.arrived_at  IS NULL OR r.arrived_at  <= p_cleared_at);
        GET DIAGNOSTICS v_updated = ROW_COUNT;

        IF EXISTS (
            SELECT 1
              FROM app.responses r
             WHERE r.incident_id = p_incident_id
               AND (
                    (r.assigned_at IS NOT NULL AND r.assigned_at > p_cleared_at) OR
                    (r.arrived_at  IS NOT NULL AND r.arrived_at  > p_cleared_at) OR
                    (r.cleared_at  IS NOT NULL AND r.arrived_at IS NOT NULL AND r.cleared_at < r.arrived_at)
                   )
        ) THEN
            RAISE EXCEPTION 'Нарушена хронология в участниках инцидента %, проверьте времена assigned/arrived/cleared', p_incident_id
              USING ERRCODE='22007';
        END IF;

        UPDATE app.incidents
           SET cleared_at  = p_cleared_at,
               description = CASE
                               WHEN NULLIF(btrim(p_comment), '') IS NULL THEN description
                               ELSE COALESCE(description,'') || E'\n[close] ' || btrim(p_comment)
                             END
         WHERE incident_id = p_incident_id;

        INSERT INTO audit.function_calls(call_time, function_name, caller_role, input_params, success)
        VALUES (v_call_time, 'close_incident', eff_role,
                jsonb_build_object(
                    'p_incident_id', p_incident_id,
                    'p_cleared_at', p_cleared_at,
                    'p_comment', p_comment
                ), true);

        RETURN v_updated;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit.function_calls(call_time, function_name, caller_role, input_params, success)
        VALUES (v_call_time, 'close_incident', eff_role,
                jsonb_build_object(
                    'p_incident_id', p_incident_id,
                    'p_cleared_at', p_cleared_at,
                    'p_comment', p_comment
                ), false);
        RAISE;
    END;
$$;

REVOKE ALL ON FUNCTION app.close_incident(integer,timestamptz,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.close_incident(integer,timestamptz,text) TO dml_admin, app_writer;


-- SELECT app.close_incident(1, '2025-09-01 11:00+00', 'Очаг ликвидирован, проливка и вентиляция выполнены');