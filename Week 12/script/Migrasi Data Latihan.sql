CREATE DATABASE IF NOT EXISTS transport_db;
SET database = transport_db;

CREATE TABLE routes (
route_id   INT PRIMARY KEY,
route_name STRING NOT NULL
);

CREATE TABLE trips (
trip_id    STRING PRIMARY KEY,
route_id   INT NOT NULL REFERENCES routes (route_id),
started_at TIMESTAMP NOT NULL,
status     STRING NOT NULL
);

INSERT INTO routes (route_id, route_name) VALUES
(12, 'Koridor Pusat–Terminal'),
(15, 'Koridor Kampus–Stasiun'),
(18, 'Koridor Pasar–Kota');

INSERT INTO trips (trip_id, route_id, started_at, status) VALUES
('T001', 12, '2026-11-02 07:10:00', 'completed'),
('T002', 15, '2026-11-02 07:25:00', 'completed'),
('T003', 12, '2026-11-03 08:05:00', 'delayed'),
('T004', 18, '2026-10-29 06:50:00', 'completed'),
('T005', 12, '2026-11-05 17:20:00', 'completed'),
('T006', 15, '2026-11-06 09:15:00', 'cancelled');

SELECT version();
SELECT * FROM routes ORDER BY route_id;
SELECT * FROM trips ORDER BY trip_id;
SHOW CREATE TABLE trips;
