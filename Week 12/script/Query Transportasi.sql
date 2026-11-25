SET database = transport_db;

-- 1. Query Baseline (Transportasi)
SELECT t.trip_id, t.started_at, r.route_name
FROM trips AS t
JOIN routes AS r ON r.route_id = t.route_id
WHERE t.route_id = 12
AND t.started_at >= '2026-11-01';

-- 2. Rencana 1: Join Dahulu, Seleksi Kemudian
SELECT j.trip_id, j.started_at, j.route_name
FROM (
SELECT t.trip_id, t.route_id, t.started_at, r.route_name
FROM trips AS t
JOIN routes AS r ON r.route_id = t.route_id
) AS j
WHERE j.route_id = 12
AND j.started_at >= '2026-11-01';

-- 3. Rencana 2: Seleksi Dahulu (Selection Pushdown)
SELECT s.trip_id, s.started_at, r.route_name
FROM (
SELECT trip_id, route_id, started_at
FROM trips
WHERE route_id = 12
AND started_at >= '2026-11-01'
) AS s
JOIN routes AS r ON r.route_id = s.route_id;

-- 4. EXPLAIN & EXPLAIN ANALYZE Sebelum Index
EXPLAIN
SELECT t.trip_id, t.started_at, r.route_name
FROM trips AS t
JOIN routes AS r ON r.route_id = t.route_id
WHERE t.route_id = 12
AND t.started_at >= '2026-11-01';

EXPLAIN ANALYZE
SELECT t.trip_id, t.started_at, r.route_name
FROM trips AS t
JOIN routes AS r ON r.route_id = t.route_id
WHERE t.route_id = 12
AND t.started_at >= '2026-11-01';

-- 5. Membuat Composite Index
CREATE INDEX idx_trips_route_started ON trips (route_id, started_at);
SHOW INDEXES FROM trips;

-- 6. EXPLAIN ANALYZE Setelah Index
EXPLAIN ANALYZE
SELECT t.trip_id, t.started_at, r.route_name
FROM trips AS t
JOIN routes AS r ON r.route_id = t.route_id
WHERE t.route_id = 12
AND t.started_at >= '2026-11-01';
