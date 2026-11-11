-- 1. Membuat Database
CREATE DATABASE IF NOT EXISTS db_banksampah;
USE db_banksampah;

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

-- Operasi CRUD
-- 1. CREATE (Menambahkan Data Baru)
-- Memasukkan akun pengguna dan data nasabah yang terikat
INSERT INTO pengguna (username, password, role) 
VALUES ('budi_nasabah', 'hash_password_123', 'nasabah');

INSERT INTO nasabah (id_pengguna, nama_nasabah, alamat, no_telepon) 
VALUES (LAST_INSERT_ID(), 'Budi Santoso', 'Jl. Pemuda No. 15', '081234567890');

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
