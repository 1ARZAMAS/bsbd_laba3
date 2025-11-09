SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;
SET client_min_messages = warning;
SELECT plan(4);

SET ROLE stat_user_1;
SET search_path = pgtap, public, ref, app, sec, audit, pg_temp;

BEGIN;
SAVEPOINT sp_ctx;
SELECT sec.set_session_ctx((SELECT id FROM ref.segment WHERE role_name = current_role), 3001);

-- 1) join incidents→stations: в результате все строки должны принадлежать текущему сегменту
SELECT ok(
  NOT EXISTS (
    SELECT 1
    FROM app.incidents i
    JOIN app.stations  s ON s.station_id = i.station_id
    WHERE i.segment_id = s.segment_id
      AND i.segment_id <> sec.current_segment()
  ),
  'JOIN incidents→stations returns only current segment'
);

-- 2) join vehicles→stations: видим только свой сегмент
SELECT ok(
  NOT EXISTS (
    SELECT 1
    FROM app.vehicles v
    JOIN app.stations s ON s.station_id = v.station_id
    WHERE v.segment_id = s.segment_id
      AND v.segment_id <> sec.current_segment()
  ),
  'JOIN vehicles→stations returns only current segment'
);

-- 3) count по join совпадает с count по фильтру (incidents)
SELECT is(
  (
    SELECT count(*)::bigint
    FROM app.incidents i
    JOIN app.stations  s ON s.station_id = i.station_id
    WHERE i.segment_id = s.segment_id
      AND i.segment_id = sec.current_segment()
  ),
  (
    SELECT count(*)::bigint
    FROM app.incidents
    WHERE segment_id = sec.current_segment()
  ),
  'JOIN count equals filtered count (incidents)'
);

-- 4) аналогично для vehicles
SELECT is(
  (
    SELECT count(*)::bigint
    FROM app.vehicles v
    JOIN app.stations s ON s.station_id = v.station_id
    WHERE v.segment_id = s.segment_id
      AND v.segment_id = sec.current_segment()
  ),
  (
    SELECT count(*)::bigint
    FROM app.vehicles
    WHERE segment_id = sec.current_segment()
  ),
  'JOIN count equals filtered count (vehicles)'
);

RESET ROLE;

SELECT * FROM finish();

ROLLBACK TO SAVEPOINT sp_ctx;  -- откатываем только свои изменения
RELEASE SAVEPOINT sp_ctx;