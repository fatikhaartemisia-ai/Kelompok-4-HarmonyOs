-- 1. Membuat Database
CREATE DATABASE IF NOT EXISTS bank_sampah_digital;
USE bank_sampah_digital;

-- 2. Tabel Pengguna (Manajemen Akun Login)
CREATE TABLE IF NOT EXISTS pengguna (
    id_pengguna INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'petugas', 'nasabah') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 3. Tabel Nasabah
CREATE TABLE IF NOT EXISTS nasabah (
    id_nasabah INT AUTO_INCREMENT PRIMARY KEY,
    id_pengguna INT,
    nama_nasabah VARCHAR(100) NOT NULL,
    alamat TEXT,
    no_telepon VARCHAR(15),
    total_setoran_rp DECIMAL(12,2) DEFAULT 0.00,
    FOREIGN KEY (id_pengguna) REFERENCES pengguna(id_pengguna) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 4. Tabel Petugas
CREATE TABLE IF NOT EXISTS petugas (
    id_petugas INT AUTO_INCREMENT PRIMARY KEY,
    id_pengguna INT,
    nama_petugas VARCHAR(100) NOT NULL,
    no_telepon VARCHAR(15),
    FOREIGN KEY (id_pengguna) REFERENCES pengguna(id_pengguna) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 5. Tabel Pengurus Admin
CREATE TABLE IF NOT EXISTS pengurus_admin (
    id_admin INT AUTO_INCREMENT PRIMARY KEY,
    id_pengguna INT,
    nama_admin VARCHAR(100) NOT NULL,
    jabatan VARCHAR(50),
    FOREIGN KEY (id_pengguna) REFERENCES pengguna(id_pengguna) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 6. Tabel Jenis Sampah
CREATE TABLE IF NOT EXISTS jenis_sampah (
    id_jenis INT AUTO_INCREMENT PRIMARY KEY,
    nama_jenis VARCHAR(50) NOT NULL,
    kategori VARCHAR(50) -- Contoh: Plastik, Kertas, Logam
) ENGINE=InnoDB;

-- 7. Tabel Harga Sampah
CREATE TABLE IF NOT EXISTS harga_sampah (
    id_harga INT AUTO_INCREMENT PRIMARY KEY,
    id_jenis INT,
    harga_per_kg DECIMAL(10,2) NOT NULL,
    tanggal_berlaku DATE,
    FOREIGN KEY (id_jenis) REFERENCES jenis_sampah(id_jenis) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 8. Tabel Request Penjemputan
CREATE TABLE IF NOT EXISTS request_penjemputan (
    id_request INT AUTO_INCREMENT PRIMARY KEY,
    id_nasabah INT,
    tanggal_request DATETIME DEFAULT CURRENT_TIMESTAMP,
    status_request ENUM('Pending', 'Proses', 'Selesai', 'Dibatalkan') DEFAULT 'Pending',
    catatan TEXT,
    FOREIGN KEY (id_nasabah) REFERENCES nasabah(id_nasabah) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9. Tabel Setoran Sampah
CREATE TABLE IF NOT EXISTS setoran (
    id_setoran INT AUTO_INCREMENT PRIMARY KEY,
    id_nasabah INT,
    id_petugas INT,
    id_jenis INT,
    berat_kg DECIMAL(8,2) NOT NULL,
    total_harga DECIMAL(10,2) NOT NULL,
    tanggal_setor DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_nasabah) REFERENCES nasabah(id_nasabah) ON DELETE CASCADE,
    FOREIGN KEY (id_petugas) REFERENCES petugas(id_petugas) ON DELETE SET NULL,
    FOREIGN KEY (id_jenis) REFERENCES jenis_sampah(id_jenis) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 10. Tabel Penarikan Saldo
CREATE TABLE IF NOT EXISTS penarikan (
    id_penarikan INT AUTO_INCREMENT PRIMARY KEY,
    id_nasabah INT,
    jumlah_penarikan DECIMAL(10,2) NOT NULL,
    tanggal_penarikan DATETIME DEFAULT CURRENT_TIMESTAMP,
    status_penarikan ENUM('Berhasil', 'Pending', 'Gagal') DEFAULT 'Berhasil',
    FOREIGN KEY (id_nasabah) REFERENCES nasabah(id_nasabah) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 11. Tabel Laporan
CREATE TABLE IF NOT EXISTS laporan (
    id_laporan INT AUTO_INCREMENT PRIMARY KEY,
    id_admin INT,
    jenis_laporan VARCHAR(50), -- Contoh: Bulanan, Tahunan
    periode_awal DATE,
    periode_akhir DATE,
    tanggal_generate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_admin) REFERENCES pengurus_admin(id_admin) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Memeriksa Struktur Relasi & Tabel
SHOW TABLES;
SHOW CREATE TABLE nasabah;
SHOW CREATE TABLE setoran;
SHOW TABLE STATUS;

-- Data Awal Sampel
INSERT INTO jenis_sampah (id_jenis, nama_jenis, kategori) VALUES
    (1, 'Plastik PET', 'Plastik'),
    (2, 'Kardus', 'Kertas'),
    (3, 'Kertas HVS', 'Kertas'),
    (4, 'Botol Kaca', 'Kaca'),
    (5, 'Kaleng Aluminium', 'Logam');

INSERT INTO harga_sampah (id_jenis, harga_per_kg, tanggal_berlaku) VALUES
    (1, 3500, '2026-01-01'),
    (2, 2000, '2026-01-01'),
    (3, 2500, '2026-01-01'),
    (4, 1000, '2026-01-01'),
    (5, 12000, '2026-01-01');


-- Operasi CRUD
-- 1. CREATE (Menambahkan Data Baru)
-- Memasukkan akun pengguna dan data nasabah yang terikat
INSERT INTO pengguna (username, password, role) 
VALUES ('budi_nasabah', 'hash_password_123', 'nasabah');

INSERT INTO nasabah (id_pengguna, nama_nasabah, alamat, no_telepon) 
VALUES (LAST_INSERT_ID(), 'Budi Santoso', 'Jl. Pemuda No. 15', '081234567890');

INSERT INTO pengguna (username, password, role) 
VALUES ('rina_petugas', 'hash_password_123', 'petugas');

INSERT INTO petugas (id_pengguna, nama_petugas, no_telepon) 
VALUES (LAST_INSERT_ID(), 'Rina', '081300000001');

-- 2. READ (Membaca/Menampilkan Data)
-- Menampilkan data nasabah beserta username akun login-nya
SELECT n.id_nasabah, n.nama_nasabah, p.username, n.alamat, n.no_telepon 
FROM nasabah n
JOIN pengguna p ON n.id_pengguna = p.id_pengguna;

-- 3. UPDATE (Memperbarui Data)
-- Memperbarui alamat dan nomor telepon nasabah Budi Santoso
UPDATE nasabah 
SET alamat = 'Jl. Gajah Mada No. 88', no_telepon = '081999888777' 
WHERE nama_nasabah = 'Budi Santoso';

-- 4. DELETE (Menghapus Data)
-- Menghapus data nasabah Budi Santoso
DELETE FROM nasabah WHERE nama_nasabah = 'Budi Santoso';

-- Pengujian Inttegritas
-- PK
INSERT INTO nasabah (id_nasabah, nama_nasabah, alamat) 
VALUES (3, 'Budi Santoso', 'Jl. Gajah Mada No. 88');
-- FK dan Constraint
INSERT INTO setoran (id_nasabah, id_petugas, id_jenis, berat_kg, total_harga)
VALUES (9999999, 1, 1, 1.00, 3500);

-- Commit
INSERT INTO nasabah (id_nasabah, nama_nasabah, alamat, no_telepon)
VALUES (501, 'Siti Rahayu', 'Jl. Merdeka No. 10', '081200000501');
START TRANSACTION;
INSERT INTO setoran (id_nasabah, id_petugas, id_jenis, berat_kg, total_harga, tanggal_setor)
VALUES (501, 1, 1, 5.00, 17500, '2026-10-05 09:00:00');
UPDATE nasabah SET total_setoran_rp = total_setoran_rp + 17500 WHERE id_nasabah = 501;
COMMIT;
SELECT * FROM setoran WHERE id_nasabah = 501;
SELECT id_nasabah, nama_nasabah, total_setoran_rp FROM nasabah WHERE id_nasabah = 501;  -- 17500

-- Rollback
START TRANSACTION;
INSERT INTO setoran (id_nasabah, id_petugas, id_jenis, berat_kg, total_harga, tanggal_setor)
VALUES (501, 1, 5, 2.00, 24000, '2026-10-06 10:00:00');
UPDATE nasabah SET total_setoran_rp = total_setoran_rp + 24000 WHERE id_nasabah = 501;
ROLLBACK;
SELECT * FROM setoran WHERE id_nasabah = 501;  -- tetap 1 baris (yang COMMIT)
SELECT id_nasabah, nama_nasabah, total_setoran_rp FROM nasabah WHERE id_nasabah = 501;  -- tetap 17500

-- TAHAP 5 - ANALISIS PERFORMA (DATA BERJUTA-JUTA)
-- Tabel bantu angka 0..999999 (portabel MySQL & MariaDB)
CREATE TABLE digit (d TINYINT UNSIGNED NOT NULL PRIMARY KEY) ENGINE=InnoDB;
INSERT INTO digit VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

CREATE TABLE angka (n INT UNSIGNED NOT NULL PRIMARY KEY) ENGINE=InnoDB;
INSERT INTO angka (n)
SELECT a.d + 10*b.d + 100*c.d + 1000*d.d + 10000*e.d + 100000*f.d
FROM digit a, digit b, digit c, digit d, digit e, digit f;

SELECT COUNT(*) AS jumlah_angka FROM angka;   -- 1.000.000

-- 10.000 nasabah (id 1001..11000) dan 3 petugas (id 101..103)
INSERT INTO nasabah (id_nasabah, nama_nasabah, alamat, no_telepon)
SELECT 1000 + n + 1,
       CONCAT('Nasabah ', n + 1),
       CONCAT('Jl. Contoh No. ', n + 1),
       CONCAT('0812', LPAD(n + 1, 8, '0'))
FROM angka
WHERE n < 10000;

INSERT INTO petugas (id_petugas, nama_petugas, no_telepon) VALUES
    (101, 'Petugas A', '081300000101'),
    (102, 'Petugas B', '081300000102'),
    (103, 'Petugas C', '081300000103');

-- 1.000.000 setoran acak (2024-01-01 s.d. kira-kira 2026-11-01)
SET foreign_key_checks = 0;
SET unique_checks = 0;

INSERT INTO setoran (id_nasabah, id_petugas, id_jenis, berat_kg, total_harga, tanggal_setor)
SELECT 1001 + FLOOR(RAND() * 10000),
       101 + FLOOR(RAND() * 3),
       1 + FLOOR(RAND() * 5),
       ROUND(1 + RAND() * 49, 2),
       0,
       DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * 1035 * 86400) SECOND)
FROM angka;

SET unique_checks = 1;
SET foreign_key_checks = 1;

-- Hitung total_harga = berat x harga per kg
UPDATE setoran s
JOIN harga_sampah h ON h.id_jenis = s.id_jenis
SET s.total_harga = ROUND(s.berat_kg * h.harga_per_kg, 2)
WHERE s.total_harga = 0;

-- Hapus tabel bantu agar database bersih
DROP TABLE angka;
DROP TABLE digit;

ANALYZE TABLE setoran;
SELECT COUNT(*) AS jumlah_setoran FROM setoran;

-- EXPLAIN SEBELUM INDEKS --
SHOW INDEX FROM setoran;

-- Query 1: pencarian berdasarkan rentang tanggal
EXPLAIN
SELECT id_setoran, id_nasabah, tanggal_setor, berat_kg, total_harga
FROM setoran
WHERE tanggal_setor >= '2026-10-01' AND tanggal_setor < '2026-11-01';

-- Query 2: JOIN + GROUP BY (rekap per jenis sampah, Oktober 2026)
EXPLAIN
SELECT j.nama_jenis,
       COUNT(*)           AS jumlah_setoran,
       SUM(s.berat_kg)    AS total_kg,
       SUM(s.total_harga) AS total_rp
FROM setoran s
JOIN jenis_sampah j ON j.id_jenis = s.id_jenis
WHERE s.tanggal_setor >= '2026-10-01' AND s.tanggal_setor < '2026-11-01'
GROUP BY j.id_jenis, j.nama_jenis;

-- Query 3: JOIN (10 nasabah dengan setoran terbesar, Oktober 2026)
EXPLAIN
SELECT n.nama_nasabah, SUM(s.total_harga) AS total_rp
FROM setoran s
JOIN nasabah n ON n.id_nasabah = s.id_nasabah
WHERE s.tanggal_setor >= '2026-10-01' AND s.tanggal_setor < '2026-11-01'
GROUP BY n.id_nasabah, n.nama_nasabah
ORDER BY total_rp DESC
LIMIT 10;


-- ---------- B. BUAT INDEKS ----------
CREATE INDEX idx_setoran_tanggal ON setoran(tanggal_setor);
SHOW INDEX FROM setoran;

--EXPLAIN SESUDAH INDEKS ---
EXPLAIN
SELECT id_setoran, id_nasabah, tanggal_setor, berat_kg, total_harga
FROM setoran
WHERE tanggal_setor >= '2026-10-01' AND tanggal_setor < '2026-11-01';

EXPLAIN
SELECT j.nama_jenis,
       COUNT(*)           AS jumlah_setoran,
       SUM(s.berat_kg)    AS total_kg,
       SUM(s.total_harga) AS total_rp
FROM setoran s
JOIN jenis_sampah j ON j.id_jenis = s.id_jenis
WHERE s.tanggal_setor >= '2026-10-01' AND s.tanggal_setor < '2026-11-01'
GROUP BY j.id_jenis, j.nama_jenis;

EXPLAIN
SELECT n.nama_nasabah, SUM(s.total_harga) AS total_rp
FROM setoran s
JOIN nasabah n ON n.id_nasabah = s.id_nasabah
WHERE s.tanggal_setor >= '2026-10-01' AND s.tanggal_setor < '2026-11-01'
GROUP BY n.id_nasabah, n.nama_nasabah
ORDER BY total_rp DESC
LIMIT 10;

-- Validasi hasil restore
USE backup_bank_sampah;
SHOW TABLES;
SELECT COUNT(*) FROM pengguna;
SELECT COUNT(*) FROM nasabah;
SELECT COUNT(*) FROM petugas;
SELECT COUNT(*) FROM jenis_sampah;
SELECT COUNT(*) FROM harga_sampah;
SELECT COUNT(*) FROM setoran;
SELECT COUNT(*) FROM penarikan;
