CREATE DATABASE IF NOT EXISTS banksampah_crdb;
SET database = banksampah_crdb;

CREATE TYPE enum_pemilahan AS ENUM ('bersih', 'tercampur');
CREATE TYPE enum_status_jemput AS ENUM ('menunggu', 'ditugaskan', 'dijemput', 'selesai', 'dibatalkan');

CREATE TABLE wilayah_rtrw (
id_wilayah UUID PRIMARY KEY DEFAULT gen_random_uuid(),
rt         STRING NOT NULL,
rw         STRING NOT NULL,
kelurahan  STRING NOT NULL,
UNIQUE (rt, rw, kelurahan)
);

CREATE TABLE users (
id_user         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
id_wilayah      UUID REFERENCES wilayah_rtrw (id_wilayah),
nama            STRING NOT NULL,
peran           STRING NOT NULL
CHECK (peran IN ('admin', 'ketua_rtrw', 'nasabah', 'kurir', 'pembeli')),
profil_tambahan JSONB
);

CREATE TABLE kategori_sampah (
id_kategori     INT PRIMARY KEY,
nama_kategori   STRING NOT NULL UNIQUE,
harga_bersih    DECIMAL(10,2) NOT NULL CHECK (harga_bersih >= 0),
harga_tercampur DECIMAL(10,2) NOT NULL CHECK (harga_tercampur >= 0)
);

CREATE TABLE transaksi_jemput (
id_jemput       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
id_nasabah      UUID NOT NULL REFERENCES users (id_user),
id_kurir        UUID REFERENCES users (id_user),
tanggal_request TIMESTAMP NOT NULL DEFAULT now(),
tanggal_jemput  TIMESTAMP,
estimasi_berat  DECIMAL(6,2) NOT NULL CHECK (estimasi_berat >= 3),
status_jemput   enum_status_jemput NOT NULL DEFAULT 'menunggu',
total_rupiah    DECIMAL(14,2) NOT NULL DEFAULT 0 CHECK (total_rupiah >= 0),
INDEX idx_jemput_status_tgl (status_jemput, tanggal_jemput)
);

CREATE TABLE detail_jemput (
id_detail         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
id_jemput         UUID NOT NULL REFERENCES transaksi_jemput (id_jemput),
id_kategori       INT NOT NULL REFERENCES kategori_sampah (id_kategori),
berat_aktual      DECIMAL(6,2) NOT NULL CHECK (berat_aktual > 0),
status_pemilahan  enum_pemilahan NOT NULL,
harga_satuan      DECIMAL(10,2) NOT NULL,
subtotal          DECIMAL(14,2) NOT NULL,
catatan_pemilahan JSONB,
CHECK (subtotal = round(berat_aktual * harga_satuan, 2)),
INDEX idx_detail_jemput (id_jemput)
STORING (id_kategori, berat_aktual, status_pemilahan, subtotal)
);

-- Query Rekap Bulanan Volume & Nilai Setoran per RT/RW (Fitur KF-11)
SELECT w.rt, w.rw, k.nama_kategori, d.status_pemilahan,
SUM(d.berat_aktual) AS total_kg,
SUM(d.subtotal)     AS total_rupiah
FROM detail_jemput d
JOIN transaksi_jemput t ON t.id_jemput   = d.id_jemput
JOIN users u            ON u.id_user     = t.id_nasabah
JOIN wilayah_rtrw w     ON w.id_wilayah  = u.id_wilayah
JOIN kategori_sampah k  ON k.id_kategori = d.id_kategori
WHERE t.status_jemput = 'selesai'
AND t.tanggal_jemput >= '2026-11-01'
AND t.tanggal_jemput <  '2026-12-01'
GROUP BY w.rt, w.rw, k.nama_kategori, d.status_pemilahan
ORDER BY w.rt, w.rw, k.nama_kategori;

-- View Laporan Setoran Wilayah
CREATE VIEW v_setoran_wilayah AS
SELECT w.rt, w.rw,
date_trunc('month', t.tanggal_jemput) AS bulan,
k.nama_kategori, d.status_pemilahan,
SUM(d.berat_aktual) AS total_kg,
SUM(d.subtotal)     AS total_rupiah
FROM detail_jemput d
JOIN transaksi_jemput t ON t.id_jemput   = d.id_jemput
JOIN users u            ON u.id_user     = t.id_nasabah
JOIN wilayah_rtrw w     ON w.id_wilayah  = u.id_wilayah
JOIN kategori_sampah k  ON k.id_kategori = d.id_kategori
WHERE t.status_jemput = 'selesai'
GROUP BY w.rt, w.rw, date_trunc('month', t.tanggal_jemput),
k.nama_kategori, d.status_pemilahan;

-- Definisi Role dan Pengaturan DCL RBAC
CREATE ROLE IF NOT EXISTS role_pelaporan;
CREATE ROLE IF NOT EXISTS role_kurir;

GRANT SELECT ON TABLE v_setoran_wilayah TO role_pelaporan;

GRANT SELECT ON TABLE transaksi_jemput, kategori_sampah TO role_kurir;
GRANT UPDATE ON TABLE transaksi_jemput TO role_kurir;
GRANT INSERT, UPDATE ON TABLE detail_jemput TO role_kurir;

CREATE USER IF NOT EXISTS laporan_app WITH PASSWORD 'GANTI_DENGAN_PASSWORD_KUAT';
CREATE USER IF NOT EXISTS kurir_app   WITH PASSWORD 'GANTI_DENGAN_PASSWORD_KUAT';

GRANT role_pelaporan TO laporan_app;
GRANT role_kurir     TO kurir_app;

SHOW GRANTS FOR laporan_app;
SHOW GRANTS FOR kurir_app;
