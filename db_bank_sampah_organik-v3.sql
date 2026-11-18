-- ============================================================================
-- DATABASE: BANK SAMPAH ORGANIK & DISTRIBUSI KOMPOS DIGITAL (SDG 12)
-- VERSI: v3 (Skema Lengkap + Data Dummy Simulasi Terintegrasi)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS db_bank_sampah_organik;
USE db_bank_sampah_organik;

-- Menghapus tabel jika sudah ada (urut dari child ke parent agar tidak error FK)
DROP TABLE IF EXISTS penjualan_kompos;
DROP TABLE IF EXISTS produksi_kompos;
DROP TABLE IF EXISTS stok_kompos;
DROP TABLE IF EXISTS penarikan_saldo;
DROP TABLE IF EXISTS detail_jemput;
DROP TABLE IF EXISTS transaksi_jemput;
DROP TABLE IF EXISTS kategori_sampah;
DROP TABLE IF EXISTS dompet_saldo;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS wilayah_rtrw;

-- ----------------------------------------------------------------------------
-- 1. TABEL WILAYAH RT/RW
-- ----------------------------------------------------------------------------
CREATE TABLE wilayah_rtrw (
    id_wilayah INT PRIMARY KEY AUTO_INCREMENT,
    nama_rt VARCHAR(10) NOT NULL,
    nama_rw VARCHAR(10) NOT NULL,
    kelurahan VARCHAR(100) NOT NULL,
    nama_ketua_rt VARCHAR(100) NOT NULL,
    no_hp_rt VARCHAR(20) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 2. TABEL PENGGUNA (Admin, Ketua RT/RW, Warga, Petugas Kurir, Pembeli Umum)
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    id_user INT PRIMARY KEY AUTO_INCREMENT,
    id_wilayah INT NULL,
    nik VARCHAR(20) UNIQUE,
    nama_lengkap VARCHAR(100) NOT NULL,
    no_hp VARCHAR(20) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    alamat_lengkap TEXT,
    koordinat_maps VARCHAR(100),
    role ENUM('admin', 'rtrw', 'warga', 'petugas', 'pembeli') NOT NULL,
    status_akun ENUM('pending', 'aktif', 'nonaktif') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_wilayah) REFERENCES wilayah_rtrw(id_wilayah)
);

-- ----------------------------------------------------------------------------
-- 3. TABEL DOMPET SALDO WARGA (Aturan Wajib Saldo Mengendap Rp10.000)
-- ----------------------------------------------------------------------------
CREATE TABLE dompet_saldo (
    id_dompet INT PRIMARY KEY AUTO_INCREMENT,
    id_user INT UNIQUE NOT NULL,
    total_saldo DECIMAL(12, 2) DEFAULT 0.00,
    saldo_mengendap DECIMAL(12, 2) DEFAULT 10000.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_user) REFERENCES users(id_user)
);

-- ----------------------------------------------------------------------------
-- 4. TABEL KATEGORI SAMPAH & HARGA BERTINGKAT
-- ----------------------------------------------------------------------------
CREATE TABLE kategori_sampah (
    id_kategori INT PRIMARY KEY AUTO_INCREMENT,
    nama_kategori VARCHAR(50) NOT NULL,
    harga_bersih_per_kg DECIMAL(10, 2) NOT NULL,
    harga_tercampur_per_kg DECIMAL(10, 2) NOT NULL,
    panduan_pemilahan TEXT
);

-- ----------------------------------------------------------------------------
-- 5. TABEL TRANSAKSI PENJEMPUTAN (Syarat Estimasi Berat Minimal 3.00 kg)
-- ----------------------------------------------------------------------------
CREATE TABLE transaksi_jemput (
    id_jemput INT PRIMARY KEY AUTO_INCREMENT,
    id_warga INT NOT NULL,
    id_petugas INT NULL,
    estimasi_berat_kg DECIMAL(8, 2) NOT NULL,
    waktu_request DATETIME DEFAULT CURRENT_TIMESTAMP,
    waktu_dijemput DATETIME NULL,
    status_jemput ENUM('menunggu', 'diproses', 'selesai', 'ditolak') DEFAULT 'menunggu',
    total_berat_aktual_kg DECIMAL(8, 2) DEFAULT 0.00,
    total_rupiah DECIMAL(12, 2) DEFAULT 0.00,
    catatan_petugas TEXT,
    FOREIGN KEY (id_warga) REFERENCES users(id_user),
    FOREIGN KEY (id_petugas) REFERENCES users(id_user)
);

-- ----------------------------------------------------------------------------
-- 6. TABEL DETAIL PENIMBANGAN PER JENIS & KUALITAS PEMILAHAN SAMPAH
-- ----------------------------------------------------------------------------
CREATE TABLE detail_jemput (
    id_detail INT PRIMARY KEY AUTO_INCREMENT,
    id_jemput INT NOT NULL,
    id_kategori INT NOT NULL,
    status_pemilahan ENUM('terpilah_bersih', 'tercampur') NOT NULL,
    harga_satuan_dipakai DECIMAL(10, 2) NOT NULL,
    berat_kg DECIMAL(8, 2) NOT NULL,
    subtotal_rupiah DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (id_jemput) REFERENCES transaksi_jemput(id_jemput),
    FOREIGN KEY (id_kategori) REFERENCES kategori_sampah(id_kategori)
);

-- ----------------------------------------------------------------------------
-- 7. TABEL PENARIKAN SALDO (Online Transfer & Offline Tunai + Kode Unik)
-- ----------------------------------------------------------------------------
CREATE TABLE penarikan_saldo (
    id_tarik INT PRIMARY KEY AUTO_INCREMENT,
    id_warga INT NOT NULL,
    id_petugas_pencair INT NULL,
    nominal_tarik DECIMAL(12, 2) NOT NULL,
    metode_tarik ENUM('online_transfer', 'offline_tunai') NOT NULL,
    info_rekening VARCHAR(100) NULL,
    kode_verifikasi_offline VARCHAR(10) NULL,
    status_tarik ENUM('diajukan', 'disetujui', 'selesai', 'ditolak') DEFAULT 'diajukan',
    tanggal_pengajuan DATETIME DEFAULT CURRENT_TIMESTAMP,
    tanggal_pencairan DATETIME NULL,
    FOREIGN KEY (id_warga) REFERENCES users(id_user),
    FOREIGN KEY (id_petugas_pencair) REFERENCES users(id_user)
);

-- ----------------------------------------------------------------------------
-- 8. TABEL STOK & KATALOG VARIAN PUPUK KOMPOS
-- ----------------------------------------------------------------------------
CREATE TABLE stok_kompos (
    id_kompos INT PRIMARY KEY AUTO_INCREMENT,
    nama_produk VARCHAR(100) NOT NULL,
    berat_kemasan_kg DECIMAL(8, 2) NOT NULL,
    stok_tersedia_unit INT DEFAULT 0,
    harga_jual_satuan DECIMAL(10, 2) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 9. TABEL BATCH PRODUKSI / FERMENTASI KOMPOS
-- ----------------------------------------------------------------------------
CREATE TABLE produksi_kompos (
    id_produksi INT PRIMARY KEY AUTO_INCREMENT,
    id_kompos INT NOT NULL,
    kode_batch VARCHAR(30) UNIQUE NOT NULL,
    berat_bahan_baku_kg DECIMAL(10, 2) NOT NULL,
    tanggal_mulai DATE NOT NULL,
    estimasi_panen DATE NOT NULL,
    tanggal_panen_aktual DATE NULL,
    hasil_kompos_jadi_kg DECIMAL(10, 2) DEFAULT 0.00,
    status_produksi ENUM('fermentasi', 'panen_selesai') DEFAULT 'fermentasi',
    FOREIGN KEY (id_kompos) REFERENCES stok_kompos(id_kompos)
);

-- ----------------------------------------------------------------------------
-- 10. TABEL PENJUALAN PUPUK KOMPOS (Komersial Umum)
-- ----------------------------------------------------------------------------
CREATE TABLE penjualan_kompos (
    id_penjualan INT PRIMARY KEY AUTO_INCREMENT,
    id_pembeli INT NOT NULL,
    id_kompos INT NOT NULL,
    jumlah_unit INT NOT NULL,
    total_berat_kg DECIMAL(10, 2) NOT NULL,
    harga_satuan_dipakai DECIMAL(10, 2) NOT NULL,
    total_bayar DECIMAL(12, 2) NOT NULL,
    metode_bayar ENUM('tunai', 'transfer') DEFAULT 'tunai',
    status_bayar ENUM('belum_lunas', 'lunas') DEFAULT 'lunas',
    tanggal_penjualan DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pembeli) REFERENCES users(id_user),
    FOREIGN KEY (id_kompos) REFERENCES stok_kompos(id_kompos)
);

-- ============================================================================
-- DATA DUMMY SIMULASI LENGKAP (SIAP UJI COBA)
-- ============================================================================

-- A. Data Wilayah RT/RW
INSERT INTO wilayah_rtrw (id_wilayah, nama_rt, nama_rw, kelurahan, nama_ketua_rt, no_hp_rt) VALUES
(1, 'RT 01', 'RW 03', 'Kelurahan Demangan', 'Bapak Sutrisno', '081234567801'),
(2, 'RT 02', 'RW 03', 'Kelurahan Demangan', 'Bapak Hendra Wijaya', '081234567802');

-- B. Data Pengguna (Semua Role)
INSERT INTO users (id_user, id_wilayah, nik, nama_lengkap, no_hp, password, alamat_lengkap, koordinat_maps, role, status_akun) VALUES
(1, NULL, '3577010101900001', 'Admin Bank Sampah Pusat', '081111111101', '$2y$10$hashpasswordadmin', 'Jl. Raya Demangan No. 10, Madiun', '-7.6412, 111.5234', 'admin', 'aktif'),
(2, 1, '3577010202800002', 'Bapak Sutrisno (Ketua RT 01)', '081234567801', '$2y$10$hashpasswordrt01', 'Jl. Melati No. 05 RT 01/RW 03', '-7.6420, 111.5240', 'rtrw', 'aktif'),
(3, NULL, '3577010303950003', 'Rizky Pratama (Kurir)', '081333333303', '$2y$10$hashpasswordkurir', 'Jl. Anggrek No. 12, Madiun', '-7.6405, 111.5220', 'petugas', 'aktif'),
(4, 1, '3577014404850004', 'Ibu Siti Aminah', '081444444404', '$2y$10$hashpasswordwarga1', 'Jl. Melati Gang 2 No. 14 RT 01', '-7.6425, 111.5245', 'warga', 'aktif'),
(5, 1, '3577010505780005', 'Bapak Joko Susilo', '081555555505', '$2y$10$hashpasswordwarga2', 'Jl. Melati Gang 3 No. 08 RT 01', '-7.6430, 111.5250', 'warga', 'aktif'),
(6, 2, '3577014606920006', 'Ibu Dewi Lestari (Menunggu Verifikasi)', '081666666606', '$2y$10$hashpasswordwarga3', 'Jl. Kenanga No. 21 RT 02', '-7.6440, 111.5260', 'warga', 'pending'),
(7, NULL, '3577010707750007', 'Pak Slamet (Petani / Pembeli)', '081777777707', '$2y$10$hashpasswordpembeli1', 'Desa Banjarsari, Kab. Madiun', '-7.6510, 111.5310', 'pembeli', 'aktif'),
(8, NULL, '3577014808940008', 'Mbak Nabila (Pehobi Tanaman)', '081888888808', '$2y$10$hashpasswordpembeli2', 'Perum Griya Indah Blok C-4, Madiun', '-7.6380, 111.5190', 'pembeli', 'aktif');

-- C. Data Dompet Saldo Warga (Wajib Mengendap Rp10.000)
-- Ibu Siti (id_user=4) punya total saldo Rp45.000 (bisa tarik maks Rp35.000)
-- Bapak Joko (id_user=5) punya total saldo Rp18.500 (bisa tarik maks Rp8.500)
INSERT INTO dompet_saldo (id_dompet, id_user, total_saldo, saldo_mengendap) VALUES
(1, 4, 45000.00, 10000.00),
(2, 5, 18500.00, 10000.00);

-- D. Data Kategori Sampah Organik & Harga Bertingkat
INSERT INTO kategori_sampah (id_kategori, nama_kategori, harga_bersih_per_kg, harga_tercampur_per_kg, panduan_pemilahan) VALUES
(1, 'Kotoran Ternak', 1000.00, 500.00, 'Kotoran sapi, kambing, atau ayam murni tanpa campuran plastik/batu'),
(2, 'Sampah Kebun', 600.00, 300.00, 'Daun kering, rumput, dan ranting kecil tanpa sampah plastik'),
(3, 'Sampah Dapur', 400.00, 150.00, 'Sisa sayur, kulit buah, nasi basi. Dilarang plastik, kaca, tulang besar, & minyak');

-- E. Data Transaksi Penjemputan Sampah
-- Jemput 1: Ibu Siti (Selesai) -> Setor gabungan Kotoran Ternak & Sampah Kebun
-- Jemput 2: Bapak Joko (Selesai) -> Setor Sampah Dapur (tercampur plastik) & Sampah Kebun
-- Jemput 3: Ibu Siti (Menunggu) -> Order baru estimasi 5.50 kg (>= 3 kg)
INSERT INTO transaksi_jemput (id_jemput, id_warga, id_petugas, estimasi_berat_kg, waktu_request, waktu_dijemput, status_jemput, total_berat_aktual_kg, total_rupiah, catatan_petugas) VALUES
(1, 4, 3, 25.00, '2026-11-10 08:30:00', '2026-11-10 10:15:00', 'selesai', 27.00, 23000.00, 'Sampah sudah dipilah rapi dalam karung terpisah'),
(2, 5, 3, 15.00, '2026-11-12 09:00:00', '2026-11-12 11:00:00', 'selesai', 16.00, 5100.00, 'Sampah dapur masih tercampur sedikit kantong plastik'),
(3, 4, NULL, 5.50, '2026-11-16 14:20:00', NULL, 'menunggu', 0.00, 0.00, NULL);

-- F. Detail Penimbangan Sampah
-- Rincian Jemput 1 (Ibu Siti):
--   - 20 kg Kotoran Ternak (terpilah_bersih @ Rp1.000) = Rp20.000
--   - 5 kg Sampah Kebun (terpilah_bersih @ Rp600) = Rp3.000 -> Total Rp23.000
-- Rincian Jemput 2 (Bapak Joko):
--   - 10 kg Sampah Dapur (tercampur @ Rp150) = Rp1.500
--   - 6 kg Sampah Kebun (terpilah_bersih @ Rp600) = Rp3.600 -> Total Rp5.100
INSERT INTO detail_jemput (id_detail, id_jemput, id_kategori, status_pemilahan, harga_satuan_dipakai, berat_kg, subtotal_rupiah) VALUES
(1, 1, 1, 'terpilah_bersih', 1000.00, 20.00, 20000.00),
(2, 1, 2, 'terpilah_bersih', 600.00, 5.00, 3000.00),
(3, 2, 3, 'tercampur', 150.00, 10.00, 1500.00),
(4, 2, 2, 'terpilah_bersih', 600.00, 6.00, 3600.00);

-- G. Data Penarikan Saldo (Online Transfer & Offline Tunai dengan Kode Unik)
INSERT INTO penarikan_saldo (id_tarik, id_warga, id_petugas_pencair, nominal_tarik, metode_tarik, info_rekening, kode_verifikasi_offline, status_tarik, tanggal_pengajuan, tanggal_pencairan) VALUES
(1, 4, NULL, 20000.00, 'online_transfer', 'BCA - 1770981234 a.n Siti Aminah', NULL, 'selesai', '2026-11-13 13:00:00', '2026-11-13 15:30:00'),
(2, 5, 3, 10000.00, 'offline_tunai', NULL, '849201', 'selesai', '2026-11-14 08:45:00', '2026-11-14 10:20:00');

-- H. Data Stok & Katalog Varian Kemasan Pupuk Kompos
INSERT INTO stok_kompos (id_kompos, nama_produk, berat_kemasan_kg, stok_tersedia_unit, harga_jual_satuan) VALUES
(1, 'Pupuk Kompos Organik - Eceran (1 kg)', 1.00, 120, 3500.00),
(2, 'Pupuk Kompos Organik - Paket Kebun (5 kg)', 5.00, 45, 15000.00),
(3, 'Pupuk Kompos Organik - Karung Tani (25 kg)', 25.00, 30, 37500.00);

-- I. Data Batch Produksi / Fermentasi Kompos
INSERT INTO produksi_kompos (id_produksi, id_kompos, kode_batch, berat_bahan_baku_kg, tanggal_mulai, estimasi_panen, tanggal_panen_aktual, hasil_kompos_jadi_kg, status_produksi) VALUES
(1, 3, 'BATCH-2026-001', 1500.00, '2026-10-15', '2026-11-05', '2026-11-05', 850.00, 'panen_selesai'),
(2, 1, 'BATCH-2026-002', 400.00, '2026-11-08', '2026-11-29', NULL, 0.00, 'fermentasi');

-- J. Data Penjualan Pupuk Kompos (Komersial Umum)
INSERT INTO penjualan_kompos (id_penjualan, id_pembeli, id_kompos, jumlah_unit, total_berat_kg, harga_satuan_dipakai, total_bayar, metode_bayar, status_bayar, tanggal_penjualan) VALUES
(1, 7, 3, 4, 100.00, 37500.00, 150000.00, 'tunai', 'lunas', '2026-11-11 09:30:00'),
(2, 8, 1, 3, 3.00, 3500.00, 10500.00, 'transfer', 'lunas', '2026-11-15 16:10:00');
