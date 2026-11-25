SET database = transport_db;

CREATE USER IF NOT EXISTS report_user
CREATE USER IF NOT EXISTS operator_user

-- Staf Pelaporan: Hanya SELECT pada trips dan routes
GRANT SELECT ON TABLE transport_db.public.trips TO report_user;
GRANT SELECT ON TABLE transport_db.public.routes TO report_user;

-- Operator Lapangan: SELECT, INSERT, UPDATE pada trips
GRANT SELECT, INSERT, UPDATE ON TABLE transport_db.public.trips TO operator_user;
GRANT SELECT ON TABLE transport_db.public.routes TO operator_user;

SHOW GRANTS FOR report_user;
SHOW GRANTS FOR operator_user;

-- Pengujian dengan akun report_user:
-- (1) Baca: Harus Berhasil
SELECT t.trip_id, t.started_at, r.route_name
FROM trips AS t
JOIN routes AS r ON r.route_id = t.route_id
WHERE t.route_id = 12 AND t.started_at >= '2026-11-01';

-- (2) Hapus: Harus Ditolak (SQLSTATE 42501)
DELETE FROM trips WHERE trip_id = 'T006';

-- REVOKE Hak Akses
REVOKE SELECT ON TABLE transport_db.public.trips FROM report_user;
SHOW GRANTS FOR report_user;

-- (3) Baca Setelah REVOKE: Harus Ditolak (SQLSTATE 42501)
SELECT trip_id, started_at FROM trips WHERE route_id = 12;
