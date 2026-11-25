-- Mengetahui versi DBMS
SELECT VERSION();

-- Mengetahui informasi DBMS
SELECT @@version_comment;

-- Mengetahui database yang tersedia
SHOW DATABASES;

-- Melihat storage engine
SHOW ENGINES;

-- Melihat karakteristik server
SHOW VARIABLES LIKE 'character_set_server';

```
-- Memeriksa storage engine InnoDB
SHOW ENGINES;

-- Memeriksa dukungan fungsi JSON
SELECT
    JSON_VALID('{"nama":"Budi"}') AS json_valid,
    JSON_EXTRACT(
        '{"nama":"Budi"}',
        '$.nama'
    ) AS nama;

-- Memeriksa informasi waktu server
SELECT NOW();

-- Memeriksa database aktif
SELECT DATABASE();
```

-- Melihat collation
SHOW VARIABLES LIKE 'collation_server';-- F.2 Membuat Database dan Tabel
DROP DATABASE IF EXISTS praktikum_modul11_banksampah;
CREATE DATABASE praktikum_modul11_banksampah
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE praktikum_modul11_banksampah;

-- Tabel wilayah, pengguna, dan dompet saldo (D1, D5)
CREATE TABLE wilayah_rtrw (
    id_wilayah INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rt         CHAR(3)      NOT NULL,
    rw         CHAR(3)      NOT NULL,
    kelurahan  VARCHAR(100) NOT NULL,
    kecamatan  VARCHAR(100) DEFAULT NULL,
    UNIQUE KEY uq_wilayah (rt, rw, kelurahan)
) ENGINE=InnoDB;

CREATE TABLE users (
    id_user       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_wilayah    INT UNSIGNED DEFAULT NULL,
    nik           CHAR(16)     DEFAULT NULL,
    nama          VARCHAR(100) NOT NULL,
    no_hp         VARCHAR(20)  NOT NULL,
    password_hash CHAR(64)     NOT NULL,
    peran         ENUM('admin','ketua_rtrw','nasabah','kurir','pembeli') NOT NULL,
    alamat        VARCHAR(200) DEFAULT NULL,
    latitude      DECIMAL(10,7) DEFAULT NULL,
    longitude     DECIMAL(10,7) DEFAULT NULL,
    status_akun   ENUM('menunggu','aktif','nonaktif') NOT NULL DEFAULT 'menunggu',
    UNIQUE KEY uq_users_nik (nik),
    UNIQUE KEY uq_users_hp (no_hp),
    KEY idx_users_nama (nama),
    KEY idx_users_peran (peran),
    CONSTRAINT fk_users_wilayah FOREIGN KEY (id_wilayah)
        REFERENCES wilayah_rtrw (id_wilayah) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE dompet_saldo (
    id_dompet       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_user         INT UNSIGNED  NOT NULL,
    saldo_total     DECIMAL(14,2) NOT NULL DEFAULT 0,
    saldo_mengendap DECIMAL(14,2) NOT NULL DEFAULT 10000,
    diperbarui_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                    ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dompet_user (id_user),
    CONSTRAINT fk_dompet_user FOREIGN KEY (id_user)
        REFERENCES users (id_user) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_saldo_total CHECK (saldo_total >= 0)
) ENGINE=InnoDB;

-- Tabel kategori sampah, penjemputan, dan detail setoran (D2, D3, D4)
CREATE TABLE kategori_sampah (
    id_kategori     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_kategori   VARCHAR(50)   NOT NULL,
    harga_bersih    DECIMAL(10,2) NOT NULL,
    harga_tercampur DECIMAL(10,2) NOT NULL,
    UNIQUE KEY uq_kategori_nama (nama_kategori),
    CONSTRAINT chk_harga_kategori
        CHECK (harga_bersih >= 0 AND harga_tercampur >= 0)
) ENGINE=InnoDB;

CREATE TABLE transaksi_jemput (
    id_jemput       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_nasabah      INT UNSIGNED  NOT NULL,
    id_kurir        INT UNSIGNED  DEFAULT NULL,
    tanggal_request DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tanggal_jemput  DATETIME      DEFAULT NULL,
    estimasi_berat  DECIMAL(6,2)  NOT NULL,
    status_jemput   ENUM('menunggu','ditugaskan','dijemput','selesai','dibatalkan')
                    NOT NULL DEFAULT 'menunggu',
    total_rupiah    DECIMAL(14,2) NOT NULL DEFAULT 0,
    KEY idx_jemput_status (status_jemput),
    KEY idx_jemput_tanggal (tanggal_request),
    CONSTRAINT fk_jemput_nasabah FOREIGN KEY (id_nasabah)
        REFERENCES users (id_user) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_jemput_kurir FOREIGN KEY (id_kurir)
        REFERENCES users (id_user) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_min_jemput   CHECK (estimasi_berat >= 3),
    CONSTRAINT chk_total_jemput CHECK (total_rupiah >= 0)
) ENGINE=InnoDB;

CREATE TABLE detail_jemput (
    id_detail        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_jemput        INT UNSIGNED  NOT NULL,
    id_kategori      INT UNSIGNED  NOT NULL,
    berat_aktual     DECIMAL(6,2)  NOT NULL,
    status_pemilahan ENUM('bersih','tercampur') NOT NULL,
    harga_satuan     DECIMAL(10,2) NOT NULL,
    subtotal         DECIMAL(14,2) NOT NULL,
    CONSTRAINT fk_detail_jemput FOREIGN KEY (id_jemput)
        REFERENCES transaksi_jemput (id_jemput) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_detail_kategori FOREIGN KEY (id_kategori)
        REFERENCES kategori_sampah (id_kategori) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_berat_aktual CHECK (berat_aktual > 0),
    CONSTRAINT chk_harga_detail CHECK (harga_satuan >= 0),
    CONSTRAINT chk_subtotal_detail
        CHECK (subtotal = ROUND(berat_aktual * harga_satuan, 2))
) ENGINE=InnoDB;

-- Tabel penarikan saldo (D5)
CREATE TABLE penarikan_saldo (
    id_penarikan      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_user           INT UNSIGNED  NOT NULL,
    tanggal_pengajuan DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    jumlah            DECIMAL(14,2) NOT NULL,
    saldo_setelah     DECIMAL(14,2) NOT NULL,
    jenis_penarikan   ENUM('online','offline') NOT NULL,
    kode_unik         CHAR(6)       DEFAULT NULL,
    status_penarikan  ENUM('diajukan','disetujui','dicairkan','ditolak')
                      NOT NULL DEFAULT 'diajukan',
    KEY idx_tarik_user (id_user),
    CONSTRAINT fk_tarik_user FOREIGN KEY (id_user)
        REFERENCES users (id_user) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_jumlah_tarik CHECK (jumlah > 0),
    CONSTRAINT chk_saldo_mengendap CHECK (saldo_setelah >= 10000),
    CONSTRAINT chk_kode_unik CHECK (
        jenis_penarikan = 'online'
        OR (kode_unik IS NOT NULL AND CHAR_LENGTH(kode_unik) = 6))
) ENGINE=InnoDB;

-- Tabel stok, produksi, dan penjualan kompos (D6, D7)
CREATE TABLE stok_kompos (
    id_stok      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_produk  VARCHAR(100)  NOT NULL,
    harga_per_kg DECIMAL(10,2) NOT NULL,
    stok_kg      DECIMAL(10,2) NOT NULL DEFAULT 0,
    UNIQUE KEY uq_stok_nama (nama_produk),
    CONSTRAINT chk_harga_kompos CHECK (harga_per_kg >= 0),
    CONSTRAINT chk_stok_kompos  CHECK (stok_kg >= 0)
) ENGINE=InnoDB;

CREATE TABLE produksi_kompos (
    id_produksi      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_stok          INT UNSIGNED  NOT NULL,
    id_admin         INT UNSIGNED  NOT NULL,
    berat_bahan_baku DECIMAL(10,2) NOT NULL,
    tanggal_mulai    DATE          NOT NULL,
    tanggal_panen    DATE          DEFAULT NULL,
    hasil_panen_kg   DECIMAL(10,2) DEFAULT NULL,
    status_produksi  ENUM('fermentasi','panen') NOT NULL DEFAULT 'fermentasi',
    CONSTRAINT fk_produksi_stok FOREIGN KEY (id_stok)
        REFERENCES stok_kompos (id_stok) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_produksi_admin FOREIGN KEY (id_admin)
        REFERENCES users (id_user) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_bahan_baku CHECK (berat_bahan_baku > 0),
    CONSTRAINT chk_tgl_panen
        CHECK (tanggal_panen IS NULL OR tanggal_panen >= tanggal_mulai),
    CONSTRAINT chk_hasil_panen CHECK (hasil_panen_kg IS NULL OR hasil_panen_kg >= 0)
) ENGINE=InnoDB;

CREATE TABLE penjualan_kompos (
    id_penjualan      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_stok           INT UNSIGNED  NOT NULL,
    id_pembeli        INT UNSIGNED  NOT NULL,
    tanggal_pesan     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    jumlah_kg         DECIMAL(10,2) NOT NULL,
    harga_satuan      DECIMAL(10,2) NOT NULL,
    total_bayar       DECIMAL(14,2) NOT NULL,
    status_pembayaran ENUM('belum_lunas','lunas') NOT NULL DEFAULT 'belum_lunas',
    KEY idx_penjualan_tanggal (tanggal_pesan),
    CONSTRAINT fk_penjualan_stok FOREIGN KEY (id_stok)
        REFERENCES stok_kompos (id_stok) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_penjualan_pembeli FOREIGN KEY (id_pembeli)
        REFERENCES users (id_user) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_jumlah_jual CHECK (jumlah_kg > 0),
    CONSTRAINT chk_total_jual
        CHECK (total_bayar = ROUND(jumlah_kg * harga_satuan, 2))
) ENGINE=InnoDB;

-- F.3 Mengisi Data Inti
INSERT INTO wilayah_rtrw (id_wilayah, rt, rw, kelurahan, kecamatan) VALUES
(1, '01', '03', 'Sumbersari', 'Sejahtera'),
(2, '02', '03', 'Sumbersari', 'Sejahtera');

INSERT INTO users
(id_user, id_wilayah, nik, nama, no_hp, password_hash, peran, alamat,
 latitude, longitude, status_akun) VALUES
(1, NULL, NULL, 'Dewi Lestari', '081200000001',
 SHA2('admin12345', 256), 'admin', 'Kantor Bank Sampah Pusat',
 NULL, NULL, 'aktif'),
(2, 1, '3500000000000002', 'Bambang Hartono', '081200000002',
 SHA2('rt01pass', 256), 'ketua_rtrw', 'Jl. Melati No. 2',
 -7.6291000, 111.5231000, 'aktif'),
(3, 2, '3500000000000003', 'Slamet Riyadi', '081200000003',
 SHA2('rt02pass', 256), 'ketua_rtrw', 'Jl. Kenanga No. 7',
 -7.6342000, 111.5287000, 'aktif'),
(4, 1, '3500000000000004', 'Rina Wulandari', '081200000004',
 SHA2('rina12345', 256), 'nasabah', 'Jl. Melati No. 10',
 -7.6295000, 111.5236000, 'aktif'),
(5, 1, '3500000000000005', 'Siti Aminah', '081200000005',
 SHA2('siti12345', 256), 'nasabah', 'Jl. Melati No. 14',
 -7.6298000, 111.5240000, 'aktif'),
(6, 2, '3500000000000006', 'Agus Prasetyo', '081200000006',
 SHA2('agus12345', 256), 'nasabah', 'Jl. Kenanga No. 21',
 -7.6349000, 111.5293000, 'aktif'),
(7, NULL, '3500000000000007', 'Joko Santoso', '081200000007',
 SHA2('joko12345', 256), 'kurir', 'Jl. Mawar No. 3',
 NULL, NULL, 'aktif'),
(8, NULL, NULL, 'Sutrisno', '081200000008',
 SHA2('tani12345', 256), 'pembeli', 'Desa Sidomulyo',
 NULL, NULL, 'aktif'),
(9, NULL, NULL, 'Maya Kusuma', '081200000009',
 SHA2('maya12345', 256), 'pembeli', 'Jl. Anggrek No. 5',
 NULL, NULL, 'aktif'),
(10, 1, '3500000000000010', 'Hendra Kurniawan', '081200000010',
 SHA2('hendra123', 256), 'nasabah', 'Jl. Melati No. 18',
 -7.6301000, 111.5244000, 'menunggu');

INSERT INTO dompet_saldo (id_dompet, id_user, saldo_total, saldo_mengendap) VALUES
(1, 4, 11000, 10000),
(2, 5, 15000, 10000),
(3, 6,  5400, 10000);

INSERT INTO kategori_sampah
(id_kategori, nama_kategori, harga_bersih, harga_tercampur) VALUES
(1, 'Kotoran Ternak', 1500, 800),
(2, 'Sampah Kebun',   1000, 500),
(3, 'Sampah Dapur',   1200, 600);

INSERT INTO transaksi_jemput
(id_jemput, id_nasabah, id_kurir, tanggal_request, tanggal_jemput,
 estimasi_berat, status_jemput, total_rupiah) VALUES
(1, 4, 7, '2026-11-02 08:00:00', '2026-11-02 09:15:00', 15.00, 'selesai', 19000),
(2, 5, 7, '2026-11-03 07:30:00', '2026-11-03 08:40:00', 20.00, 'selesai', 30000),
(3, 6, 7, '2026-11-05 08:00:00', '2026-11-05 09:30:00', 10.00, 'selesai',  5400),
(4, 4, NULL, '2026-11-12 10:00:00', NULL,                3.50, 'menunggu',     0);

INSERT INTO detail_jemput
(id_detail, id_jemput, id_kategori, berat_aktual, status_pemilahan,
 harga_satuan, subtotal) VALUES
(1, 1, 3, 12.50, 'bersih',    1200, 15000),
(2, 1, 2,  8.00, 'tercampur',  500,  4000),
(3, 2, 1, 20.00, 'bersih',    1500, 30000),
(4, 3, 3,  9.00, 'tercampur',  600,  5400);

INSERT INTO penarikan_saldo
(id_penarikan, id_user, tanggal_pengajuan, jumlah, saldo_setelah,
 jenis_penarikan, kode_unik, status_penarikan) VALUES
(1, 5, '2026-11-06 10:00:00', 15000, 15000, 'online',  NULL,     'dicairkan'),
(2, 4, '2026-11-08 09:00:00',  8000, 11000, 'offline', '482915', 'dicairkan');

INSERT INTO stok_kompos (id_stok, nama_produk, harga_per_kg, stok_kg) VALUES
(1, 'Kompos Padat Curah', 3500, 40.00),
(2, 'Kompos Granul',      6000, 35.00);

INSERT INTO produksi_kompos
(id_produksi, id_stok, id_admin, berat_bahan_baku, tanggal_mulai,
 tanggal_panen, hasil_panen_kg, status_produksi) VALUES
(1, 1, 1, 100.00, '2026-10-01', '2026-10-30', 60.00, 'panen'),
(2, 1, 1, 150.00, '2026-11-05', NULL,          NULL, 'fermentasi'),
(3, 2, 1,  80.00, '2026-10-10', '2026-10-28', 40.00, 'panen');

INSERT INTO penjualan_kompos
(id_penjualan, id_stok, id_pembeli, tanggal_pesan, jumlah_kg,
 harga_satuan, total_bayar, status_pembayaran) VALUES
(1, 1, 8, '2026-11-04 10:00:00', 20.00, 3500, 70000, 'lunas'),
(2, 2, 9, '2026-11-06 14:00:00',  5.00, 6000, 30000, 'lunas'),
(3, 1, 8, '2026-11-13 09:00:00', 10.00, 3500, 35000, 'belum_lunas');

-- F.4 Mengisi Data dengan JSON
ALTER TABLE users ADD COLUMN profil_tambahan JSON NULL AFTER status_akun;
UPDATE users SET profil_tambahan = '{"akses": ["master_harga", "verifikasi_akun", "produksi_kompos"]}' WHERE id_user = 1;
UPDATE users SET profil_tambahan = '{"masa_jabatan": "2025-2028"}' WHERE id_user = 2;
UPDATE users SET profil_tambahan = '{"masa_jabatan": "2025-2028"}' WHERE id_user = 3;
UPDATE users SET profil_tambahan = '{"anggota_keluarga": 4, "sumber_sampah": ["dapur"], "hari_jemput_favorit": "Sabtu"}' WHERE id_user = 4;
UPDATE users SET profil_tambahan = '{"anggota_keluarga": 3, "sumber_sampah": ["ternak", "kebun"], "jumlah_ternak": {"kambing": 6, "ayam": 20}}' WHERE id_user = 5;
UPDATE users SET profil_tambahan = '{"anggota_keluarga": 5, "sumber_sampah": ["dapur"]}' WHERE id_user = 6;
UPDATE users SET profil_tambahan = '{"kendaraan": "motor", "plat_nomor": "AE 4521 XY", "wilayah_tugas": ["RT 01/RW 03", "RT 02/RW 03"]}' WHERE id_user = 7;
UPDATE users SET profil_tambahan = '{"jenis_pembeli": "petani", "luas_lahan_m2": 10000, "komoditas": ["padi", "jagung"]}' WHERE id_user = 8;
UPDATE users SET profil_tambahan = '{"jenis_pembeli": "pehobi tanaman", "koleksi": "anggrek"}' WHERE id_user = 9;

ALTER TABLE kategori_sampah ADD COLUMN atribut JSON NULL;
UPDATE kategori_sampah SET atribut = '{"contoh": ["kotoran sapi", "kotoran kambing", "kotoran ayam"], "syarat": "kering angin, tidak tercampur tanah", "ditolak": ["plastik", "kaca", "bahan berbahaya"]}' WHERE id_kategori = 1;
UPDATE kategori_sampah SET atribut = '{"contoh": ["daun kering", "rumput", "ranting cacah"], "ukuran_maks_cm": 10, "ditolak": ["plastik", "kaca", "bahan berbahaya"]}' WHERE id_kategori = 2;
UPDATE kategori_sampah SET atribut = '{"contoh": ["sisa sayur", "kulit buah", "ampas kopi"], "syarat": "ditiriskan sebelum disetor", "ditolak": ["plastik", "kaca", "bahan berbahaya", "minyak jelantah"]}' WHERE id_kategori = 3;

ALTER TABLE detail_jemput ADD COLUMN catatan_pemilahan JSON NULL;
UPDATE detail_jemput SET catatan_pemilahan = '{"bahan_asing": [], "kondisi": "kering"}' WHERE id_detail = 1;
UPDATE detail_jemput SET catatan_pemilahan = '{"bahan_asing": ["plastik", "kaca"], "kondisi": "basah"}' WHERE id_detail = 2;
UPDATE detail_jemput SET catatan_pemilahan = '{"bahan_asing": [], "kondisi": "kering"}' WHERE id_detail = 3;
UPDATE detail_jemput SET catatan_pemilahan = '{"bahan_asing": ["plastik"], "kondisi": "basah", "tindakan": "dipilah ulang oleh kurir"}' WHERE id_detail = 4;

ALTER TABLE stok_kompos ADD COLUMN spesifikasi JSON NULL AFTER stok_kg;
UPDATE stok_kompos SET spesifikasi = '{"bentuk": "curah halus", "kemasan": "karung 25 kg", "kadar_air_persen": 35, "organik": true}' WHERE id_stok = 1;
UPDATE stok_kompos SET spesifikasi = '{"bentuk": "granul", "kemasan": "pouch 5 kg", "kadar_air_persen": 30, "organik": true, "rasio_c_n": "15:1"}' WHERE id_stok = 2;

ALTER TABLE produksi_kompos ADD COLUMN parameter_fermentasi JSON NULL;
UPDATE produksi_kompos SET parameter_fermentasi = '{"aktivator": "EM4", "suhu_rata_rata_c": 55, "pembalikan_kali": 6, "kelembapan_persen": 60}' WHERE id_produksi = 1;
UPDATE produksi_kompos SET parameter_fermentasi = '{"aktivator": "EM4", "suhu_rata_rata_c": 48, "pembalikan_kali": 2}' WHERE id_produksi = 2;
UPDATE produksi_kompos SET parameter_fermentasi = '{"aktivator": "Trichoderma", "suhu_rata_rata_c": 57, "pembalikan_kali": 7, "kelembapan_persen": 55, "pengayakan": "ayakan 10 mm"}' WHERE id_produksi = 3;

ALTER TABLE penarikan_saldo ADD COLUMN detail_penarikan JSON NULL;
UPDATE penarikan_saldo SET detail_penarikan = JSON_OBJECT('bank', 'BRI', 'no_rekening', '****4321', 'atas_nama', 'Siti Aminah', 'id_transfer', 'TRF-20261106-0001', 'status_transfer', 'berhasil') WHERE id_penarikan = 1;
UPDATE penarikan_saldo SET detail_penarikan = JSON_OBJECT('lokasi_pencairan', 'Pos RT 01', 'divalidasi_kurir', 'Joko Santoso', 'kode_terverifikasi', true) WHERE id_penarikan = 2;

-- F.5 - F.11 Operasi CRUD JSON & Index
SELECT nama, peran, JSON_EXTRACT(profil_tambahan, '$.kendaraan') AS kendaraan FROM users;
SELECT nama, alamat FROM users WHERE peran = 'nasabah' AND JSON_CONTAINS(profil_tambahan, '"ternak"', '$.sumber_sampah');

UPDATE stok_kompos SET spesifikasi = JSON_SET(spesifikasi, '$.kadar_air_persen', 32) WHERE nama_produk = 'Kompos Padat Curah';
UPDATE stok_kompos SET spesifikasi = JSON_SET(spesifikasi, '$.promo', 'Diskon 10% pembelian di atas 20 kg') WHERE nama_produk = 'Kompos Padat Curah';
UPDATE users SET profil_tambahan = JSON_ARRAY_APPEND(profil_tambahan, '$.sumber_sampah', 'kebun') WHERE nama = 'Rina Wulandari';

UPDATE stok_kompos SET spesifikasi = JSON_REMOVE(spesifikasi, '$.promo') WHERE nama_produk = 'Kompos Padat Curah';
UPDATE users SET profil_tambahan = JSON_REMOVE(profil_tambahan, '$.hari_jemput_favorit') WHERE nama = 'Rina Wulandari';

ALTER TABLE users
    ADD COLUMN jenis_pembeli VARCHAR(30)
        GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(profil_tambahan, '$.jenis_pembeli'))) VIRTUAL,
    ADD INDEX idx_users_jenis_pembeli (jenis_pembeli);

-- F.13 Pengujian Transaksi (COMMIT & ROLLBACK)
START TRANSACTION;
UPDATE stok_kompos SET stok_kg = stok_kg - 10 WHERE id_stok = 1;
UPDATE penjualan_kompos SET status_pembayaran = 'lunas' WHERE id_penjualan = 3;
ROLLBACK;

START TRANSACTION;
UPDATE dompet_saldo SET saldo_total = saldo_total - 5000 WHERE id_user = 5;
INSERT INTO penarikan_saldo (id_user, jumlah, saldo_setelah, jenis_penarikan, status_penarikan)
VALUES (5, 5000, 10000, 'online', 'diajukan');
COMMIT;
