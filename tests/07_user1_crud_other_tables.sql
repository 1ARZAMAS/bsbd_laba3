SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;
SET client_min_messages = warning;
SELECT plan(6);

SET ROLE stat_user_1;
SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;

-- 1) INSERT equipment в своём сегменте (без явного PK — проверяем доступ к sequence)
BEGIN;
SAVEPOINT sp_ctx;
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 3101);

SELECT lives_ok($$
  WITH s AS (
    SELECT station_id
    FROM app.stations
    WHERE segment_id = sec.current_segment()
    LIMIT 1
  )
  INSERT INTO app.equipment(station_id, segment_id, name, sku, quantity, condition, last_inspected)
  SELECT s.station_id, sec.current_segment(), 'Рукав тест', 'EQ-T-001', 1, 'good', now()::date
  FROM s;
$$, 'equipment insert (own segment) succeeds');

-- 2) UPDATE vehicles: безопасно меняем поле внутри своего сегмента
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 3102);

SELECT lives_ok($$
  WITH pick AS (
    SELECT vehicle_id
    FROM app.vehicles
    WHERE segment_id = sec.current_segment()
    ORDER BY vehicle_id
    LIMIT 1
  )
  UPDATE app.vehicles v
  SET model = COALESCE(v.model,'') || ' upd'
  FROM pick
  WHERE v.vehicle_id = pick.vehicle_id;
$$, 'vehicles update (own segment) succeeds');

-- 3) UPDATE firefighters: попытка присвоить station_id из чужого сегмента → ОШИБКА (WITH CHECK/FK)
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 3103);

SELECT throws_ok($$
  WITH mine AS (
    SELECT firefighter_id
    FROM app.firefighters
    WHERE segment_id = sec.current_segment()
    LIMIT 1
  ),
  other AS (
    SELECT station_id, segment_id
    FROM app.stations
    WHERE segment_id <> sec.current_segment()
    LIMIT 1
  )
  UPDATE app.firefighters f
  SET station_id = (SELECT station_id FROM other),
      segment_id = (SELECT segment_id FROM other)
  FROM mine
  WHERE f.firefighter_id = mine.firefighter_id;
$$, 'new row violates row-level security policy for table "firefighters"', 'firefighters: move to foreign station/segment fails');

-- 4) INSERT vehicles с неверным segment_id (чужой) при своей station_id → ОШИБКА
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 3104);

SELECT throws_ok($$
  WITH my_station AS (
    SELECT station_id
    FROM app.stations
    WHERE segment_id = sec.current_segment()
    LIMIT 1
  ),
  other_seg AS (
    SELECT id AS seg_id
    FROM ref.segment
    WHERE id <> sec.current_segment()
    LIMIT 1
  )
  INSERT INTO app.vehicles(station_id, type_id, segment_id, model, plate_number, status_id, last_inspected)
  SELECT
    my_station.station_id,
    (SELECT type_id FROM ref.vehicle_types LIMIT 1),
    other_seg.seg_id,
    'TEST-MODEL',
    'TEST-PLATE-' || floor(random()*100000)::text,
    (SELECT status_id FROM ref.vehicle_statuses LIMIT 1),
    now()::date
  FROM my_station, other_seg;
$$, 'new row violates row-level security policy for table "vehicles"', 'vehicles insert with wrong segment fails');

-- 5) DELETE equipment своей строки (ok)
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 3105);
SELECT lives_ok($$
  WITH ins AS (
    WITH s AS (
      SELECT station_id FROM app.stations WHERE segment_id = sec.current_segment() LIMIT 1
    )
    INSERT INTO app.equipment(station_id, segment_id, name, sku, quantity, condition, last_inspected)
    SELECT s.station_id, sec.current_segment(), 'DEL-ME', 'EQ-DEL-1', 1, 'good', now()::date
    FROM s
    RETURNING equipment_id
  )
  DELETE FROM app.equipment e
  USING ins
  WHERE e.equipment_id = ins.equipment_id;
$$, 'equipment delete (own row) succeeds');
-- 6) DELETE vehicles чужой строки через обычный DELETE → 0 строк (не ошибка, проверяем факт нуля)
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 3106);

-- замеряем до/после: количество видимых записей не меняется
WITH tgt AS (
  SELECT vehicle_id
  FROM app.vehicles
  WHERE segment_id <> sec.current_segment()
  ORDER BY vehicle_id
  LIMIT 1
), del AS (
  DELETE FROM app.vehicles v
  USING tgt
  WHERE v.vehicle_id = tgt.vehicle_id
  RETURNING 1
)
SELECT is(
  (SELECT count(*)::bigint FROM del),
  0::bigint,
  'vehicles: plain delete of foreign row affects 0 rows'
);

RESET ROLE;

SELECT * FROM finish();

ROLLBACK TO SAVEPOINT sp_ctx;  -- откатываем только свои изменения
RELEASE SAVEPOINT sp_ctx;