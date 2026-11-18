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

-- Melihat collation
SHOW VARIABLES LIKE 'collation_server';

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

-- Membuat database dan tabel
CREATE DATABASE praktikum_modul11_banksampah
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE praktikum_modul11_banksampah;


-- Tabel wilayah, pengguna, dan dompet saldo
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


-- Tabel kategori sampah, penjemputan, dan detail setoran
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


-- Tabel penarikan saldo
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
    -- KF-06: saldo yang tersisa setelah penarikan minimal Rp10.000
    CONSTRAINT chk_saldo_mengendap CHECK (saldo_setelah >= 10000),
    -- KF-07: penarikan offline wajib punya kode unik 6 digit
    CONSTRAINT chk_kode_unik CHECK (
        jenis_penarikan = 'online'
        OR (kode_unik IS NOT NULL AND CHAR_LENGTH(kode_unik) = 6))
) ENGINE=InnoDB;


-- Tabel stok, produksi, dan penjualan kompos
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

--Pengguna (profil tambahan tiap peran)
ALTER TABLE users
    ADD COLUMN profil_tambahan JSON NULL AFTER status_akun;
 
UPDATE users SET profil_tambahan = '{
    "akses": ["master_harga", "verifikasi_akun", "produksi_kompos"]
}' WHERE id_user = 1;
 
UPDATE users SET profil_tambahan = '{"masa_jabatan": "2025-2028"}' WHERE id_user = 2;
UPDATE users SET profil_tambahan = '{"masa_jabatan": "2025-2028"}' WHERE id_user = 3;
 
UPDATE users SET profil_tambahan = '{
    "anggota_keluarga": 4,
    "sumber_sampah": ["dapur"],
    "hari_jemput_favorit": "Sabtu"
}' WHERE id_user = 4;
 
UPDATE users SET profil_tambahan = '{
    "anggota_keluarga": 3,
    "sumber_sampah": ["ternak", "kebun"],
    "jumlah_ternak": {"kambing": 6, "ayam": 20}
}' WHERE id_user = 5;
 
UPDATE users SET profil_tambahan = '{
    "anggota_keluarga": 5,
    "sumber_sampah": ["dapur"]
}' WHERE id_user = 6;
 
UPDATE users SET profil_tambahan = '{
    "kendaraan": "motor",
    "plat_nomor": "AE 4521 XY",
    "wilayah_tugas": ["RT 01/RW 03", "RT 02/RW 03"]
}' WHERE id_user = 7;
 
UPDATE users SET profil_tambahan = '{
    "jenis_pembeli": "petani",
    "luas_lahan_m2": 10000,
    "komoditas": ["padi", "jagung"]
}' WHERE id_user = 8;
 
UPDATE users SET profil_tambahan = '{
    "jenis_pembeli": "pehobi tanaman",
    "koleksi": "anggrek"
}' WHERE id_user = 9;
 
SELECT id_user, nama, peran, profil_tambahan FROM users;


--Kategori sampah dan detail jemput
ALTER TABLE kategori_sampah ADD COLUMN atribut JSON NULL;
 
UPDATE kategori_sampah SET atribut = '{
    "contoh": ["kotoran sapi", "kotoran kambing", "kotoran ayam"],
    "syarat": "kering angin, tidak tercampur tanah",
    "ditolak": ["plastik", "kaca", "bahan berbahaya"]
}' WHERE id_kategori = 1;
 
UPDATE kategori_sampah SET atribut = '{
    "contoh": ["daun kering", "rumput", "ranting cacah"],
    "ukuran_maks_cm": 10,
    "ditolak": ["plastik", "kaca", "bahan berbahaya"]
}' WHERE id_kategori = 2;
 
UPDATE kategori_sampah SET atribut = '{
    "contoh": ["sisa sayur", "kulit buah", "ampas kopi"],
    "syarat": "ditiriskan sebelum disetor",
    "ditolak": ["plastik", "kaca", "bahan berbahaya", "minyak jelantah"]
}' WHERE id_kategori = 3;
 
ALTER TABLE detail_jemput ADD COLUMN catatan_pemilahan JSON NULL;
 
UPDATE detail_jemput
SET catatan_pemilahan = '{"bahan_asing": [], "kondisi": "kering"}'
WHERE id_detail = 1;
 
UPDATE detail_jemput
SET catatan_pemilahan = '{"bahan_asing": ["plastik", "kaca"], "kondisi": "basah"}'
WHERE id_detail = 2;
 
UPDATE detail_jemput
SET catatan_pemilahan = '{"bahan_asing": [], "kondisi": "kering"}'
WHERE id_detail = 3;
UPDATE detail_jemput SET catatan_pemilahan = '{
    "bahan_asing": ["plastik"],
    "kondisi": "basah",
    "tindakan": "dipilah ulang oleh kurir"
}' WHERE id_detail = 4;
 
SELECT nama_kategori, atribut FROM kategori_sampah;
SELECT id_detail, id_jemput, status_pemilahan, catatan_pemilahan FROM detail_jemput;


-- Stok kompos, produksi kompos, dan perilaku saldo
ALTER TABLE stok_kompos ADD COLUMN spesifikasi JSON NULL AFTER stok_kg;
 
UPDATE stok_kompos SET spesifikasi = '{
    "bentuk": "curah halus",
    "kemasan": "karung 25 kg",
    "kadar_air_persen": 35,
    "organik": true
}' WHERE id_stok = 1;
 
UPDATE stok_kompos SET spesifikasi = '{
    "bentuk": "granul",
    "kemasan": "pouch 5 kg",
    "kadar_air_persen": 30,
    "organik": true,
    "rasio_c_n": "15:1"
}' WHERE id_stok = 2;
 
ALTER TABLE produksi_kompos ADD COLUMN parameter_fermentasi JSON NULL;
 
UPDATE produksi_kompos SET parameter_fermentasi = '{
    "aktivator": "EM4", "suhu_rata_rata_c": 55,
    "pembalikan_kali": 6, "kelembapan_persen": 60
}' WHERE id_produksi = 1;
 
UPDATE produksi_kompos SET parameter_fermentasi = '{
    "aktivator": "EM4", "suhu_rata_rata_c": 48, "pembalikan_kali": 2
}' WHERE id_produksi = 2;
 
UPDATE produksi_kompos SET parameter_fermentasi = '{
    "aktivator": "Trichoderma", "suhu_rata_rata_c": 57,
    "pembalikan_kali": 7, "kelembapan_persen": 55,
    "pengayakan": "ayakan 10 mm"
}' WHERE id_produksi = 3;
 
ALTER TABLE penarikan_saldo ADD COLUMN detail_penarikan JSON NULL;
 
-- atribut penarikan berbeda: online (transfer) vs offline (tunai)
UPDATE penarikan_saldo SET detail_penarikan = JSON_OBJECT(
    'bank', 'BRI', 'no_rekening', '****4321', 'atas_nama', 'Siti Aminah',
    'id_transfer', 'TRF-20261106-0001', 'status_transfer', 'berhasil')
WHERE id_penarikan = 1;
 
UPDATE penarikan_saldo SET detail_penarikan = JSON_OBJECT(
    'lokasi_pencairan', 'Pos RT 01', 'divalidasi_kurir', 'Joko Santoso',
    'kode_terverifikasi', true)
WHERE id_penarikan = 2;
 
SELECT nama_produk, spesifikasi FROM stok_kompos;
SELECT id_produksi, status_produksi, parameter_fermentasi FROM produksi_kompos;
SELECT id_penarikan, jenis_penarikan, detail_penarikan FROM penarikan_saldo;


-- Membaca atribut JSON
-- atribut yang tidak dimiliki suatu pengguna akan bernilai NULL
SELECT nama, peran,
       JSON_EXTRACT(profil_tambahan, '$.kendaraan') AS kendaraan
FROM users;
 
SELECT nama, JSON_EXTRACT(profil_tambahan, '$.jenis_pembeli') AS jenis_pembeli
FROM users WHERE peran = 'pembeli';
 
SELECT nama, profil_tambahan->>'$.anggota_keluarga' AS anggota_keluarga
FROM users WHERE peran = 'nasabah' AND status_akun = 'aktif';
 
SELECT nama_produk, JSON_EXTRACT(spesifikasi, '$.rasio_c_n') AS rasio_c_n
FROM stok_kompos;


-- Mencari data berdasarkan atribut JSON
-- Nasabah yang menyetor kotoran ternak
SELECT nama, alamat FROM users
WHERE peran = 'nasabah'
  AND JSON_CONTAINS(profil_tambahan, '"ternak"', '$.sumber_sampah');
 
-- Pembeli berjenis petani
SELECT nama, no_hp FROM users
WHERE JSON_UNQUOTE(JSON_EXTRACT(profil_tambahan, '$.jenis_pembeli')) = 'petani';
 
-- Kurir yang bertugas di RT 01/RW 03 (pencarian di dalam array)
SELECT nama FROM users
WHERE peran = 'kurir'
  AND JSON_CONTAINS(profil_tambahan, '"RT 01/RW 03"', '$.wilayah_tugas');
 
-- Kompos organik berbentuk granul
SELECT nama_produk, harga_per_kg, stok_kg FROM stok_kompos
WHERE JSON_CONTAINS(spesifikasi, 'true', '$.organik')
  AND JSON_UNQUOTE(JSON_EXTRACT(spesifikasi, '$.bentuk')) = 'granul';
 
-- Setoran yang mengandung plastik (KF-04, penilaian pemilahan)
SELECT id_detail, id_jemput, status_pemilahan,
       JSON_EXTRACT(catatan_pemilahan, '$.bahan_asing') AS bahan_asing
FROM detail_jemput
WHERE JSON_CONTAINS(catatan_pemilahan, '"plastik"', '$.bahan_asing');


-- Mengubah atribut JSON
-- kadar air kompos curah turun setelah dijemur ulang
UPDATE stok_kompos
SET spesifikasi = JSON_SET(spesifikasi, '$.kadar_air_persen', 32)
WHERE nama_produk = 'Kompos Padat Curah';
 
SELECT nama_produk, JSON_EXTRACT(spesifikasi, '$.kadar_air_persen') AS kadar_air
FROM stok_kompos WHERE nama_produk = 'Kompos Padat Curah';
 
-- dua atribut sekaligus pada batch yang masih fermentasi
UPDATE produksi_kompos
SET parameter_fermentasi =
    JSON_SET(parameter_fermentasi, '$.suhu_rata_rata_c', 52, '$.pembalikan_kali', 4)
WHERE id_produksi = 2;
 
SELECT id_produksi, parameter_fermentasi FROM produksi_kompos WHERE id_produksi = 2;


-- Menambahkan atribut JSON
-- atribut baru (promo) pada kompos curah, tanpa mengubah struktur tabel
UPDATE stok_kompos
SET spesifikasi = JSON_SET(spesifikasi, '$.promo', 'Diskon 10% pembelian di atas 20 kg')
WHERE nama_produk = 'Kompos Padat Curah';
 
SELECT nama_produk, spesifikasi FROM stok_kompos
WHERE nama_produk = 'Kompos Padat Curah';
 
-- menambah elemen pada array: Rina mulai menyetor sampah kebun
UPDATE users
SET profil_tambahan = JSON_ARRAY_APPEND(profil_tambahan, '$.sumber_sampah', 'kebun')
WHERE nama = 'Rina Wulandari';
 
SELECT nama, JSON_EXTRACT(profil_tambahan, '$.sumber_sampah') AS sumber_sampah
FROM users WHERE nama = 'Rina Wulandari';
 
-- catatan pada penarikan offline
UPDATE penarikan_saldo
SET detail_penarikan =
    JSON_SET(detail_penarikan, '$.catatan', 'uang diserahkan langsung')
WHERE id_penarikan = 2;
 
SELECT id_penarikan, detail_penarikan FROM penarikan_saldo WHERE id_penarikan = 2;


-- Menghapus atribut JSON
-- atribut baru (promo) pada kompos curah, tanpa mengubah struktur tabel
UPDATE stok_kompos
SET spesifikasi = JSON_SET(spesifikasi, '$.promo', 'Diskon 10% pembelian di atas 20 kg')
WHERE nama_produk = 'Kompos Padat Curah';
 
SELECT nama_produk, spesifikasi FROM stok_kompos
WHERE nama_produk = 'Kompos Padat Curah';
 
-- menambah elemen pada array: Rina mulai menyetor sampah kebun
UPDATE users
SET profil_tambahan = JSON_ARRAY_APPEND(profil_tambahan, '$.sumber_sampah', 'kebun')
WHERE nama = 'Rina Wulandari';
 
SELECT nama, JSON_EXTRACT(profil_tambahan, '$.sumber_sampah') AS sumber_sampah
FROM users WHERE nama = 'Rina Wulandari';
 
-- catatan pada penarikan offline
UPDATE penarikan_saldo
SET detail_penarikan =
    JSON_SET(detail_penarikan, '$.catatan', 'uang diserahkan langsung')
WHERE id_penarikan = 2;
 
SELECT id_penarikan, detail_penarikan FROM penarikan_saldo WHERE id_penarikan = 2;


-- Menguji fungsi JSON lainnya
SELECT JSON_OBJECT(
    'nasabah', 'Rina Wulandari',
    'wilayah', 'RT 01/RW 03',
    'saldo', 11000
) AS data_nasabah;
 
SELECT JSON_ARRAY('Kotoran Ternak', 'Sampah Kebun', 'Sampah Dapur') AS kategori_sampah;
 
SELECT JSON_VALID('{"kategori":"Sampah Dapur","bersih":true}') AS json_valid;
 
SELECT nama_kategori, JSON_LENGTH(atribut) AS jumlah_atribut FROM kategori_sampah;
 
SELECT nama_produk, JSON_KEYS(spesifikasi) AS daftar_atribut FROM stok_kompos;


-- Index pada atribut JSON
ALTER TABLE users
    ADD COLUMN jenis_pembeli VARCHAR(30)
        GENERATED ALWAYS AS (
            JSON_UNQUOTE(JSON_EXTRACT(profil_tambahan, '$.jenis_pembeli'))
        ) VIRTUAL,
    ADD INDEX idx_users_jenis_pembeli (jenis_pembeli);
 
EXPLAIN SELECT nama FROM users WHERE jenis_pembeli = 'petani';


-- Query gabungan untuk laporan
-- Volume setoran per RT/RW pada November 2026:
SELECT w.rt, w.rw, k.nama_kategori, d.status_pemilahan,
       SUM(d.berat_aktual) AS total_kg,
       SUM(d.subtotal)     AS total_rupiah
FROM detail_jemput d
JOIN transaksi_jemput t ON t.id_jemput   = d.id_jemput
JOIN users u            ON u.id_user     = t.id_nasabah
JOIN wilayah_rtrw w     ON w.id_wilayah  = u.id_wilayah
JOIN kategori_sampah k  ON k.id_kategori = d.id_kategori
WHERE t.status_jemput = 'selesai'
  AND t.tanggal_jemput >= '2026-11-01' AND t.tanggal_jemput < '2026-12-01'
GROUP BY w.rt, w.rw, k.nama_kategori, d.status_pemilahan
ORDER BY w.rt, w.rw, k.nama_kategori;

-- Pendapatan penjualan kompos yang sudah lunas:
SELECT DATE_FORMAT(p.tanggal_pesan, '%Y-%m') AS bulan,
       s.nama_produk,
       SUM(p.jumlah_kg)   AS kg_terjual,
       SUM(p.total_bayar) AS pendapatan
FROM penjualan_kompos p
JOIN stok_kompos s ON s.id_stok = p.id_stok
WHERE p.status_pembayaran = 'lunas'
GROUP BY DATE_FORMAT(p.tanggal_pesan, '%Y-%m'), s.nama_produk
ORDER BY s.nama_produk;

-- Pengujian transaksi
-- Pembatalan pelunasan kompos dengan ROLLBACK (KF-10):
START TRANSACTION;
 
UPDATE stok_kompos SET stok_kg = stok_kg - 10 WHERE id_stok = 1;
UPDATE penjualan_kompos SET status_pembayaran = 'lunas' WHERE id_penjualan = 3;
 
SELECT id_stok, nama_produk, stok_kg FROM stok_kompos
WHERE id_stok = 1;                                  -- 30.00
SELECT id_penjualan, status_pembayaran FROM penjualan_kompos
WHERE id_penjualan = 3;                             -- lunas
 
ROLLBACK;
 
SELECT id_stok, nama_produk, stok_kg FROM stok_kompos
WHERE id_stok = 1;                                  -- kembali 40.00
SELECT id_penjualan, status_pembayaran FROM penjualan_kompos
WHERE id_penjualan = 3;                             -- belum_lunas

-- Penarikan saldo yang sah dengan COMMIT (KF-06, KF-07):
START TRANSACTION;
 
UPDATE dompet_saldo SET saldo_total = saldo_total - 5000 WHERE id_user = 5;
INSERT INTO penarikan_saldo
(id_user, jumlah, saldo_setelah, jenis_penarikan, status_penarikan)
VALUES (5, 5000, 10000, 'online', 'diajukan');
 
COMMIT;
 
SELECT id_user, saldo_total FROM dompet_saldo WHERE id_user = 5;   -- 10000.00
SELECT id_penarikan, id_user, jumlah, saldo_setelah, status_penarikan
FROM penarikan_saldo WHERE id_user = 5;

-- Penarikan yang melanggar saldo mengendap, seluruh perubahan dibatalkan:
START TRANSACTION;
 
UPDATE dompet_saldo SET saldo_total = saldo_total - 1000
WHERE id_user = 6;                                  -- berhasil sementara
 
INSERT INTO penarikan_saldo
(id_user, jumlah, saldo_setelah, jenis_penarikan, kode_unik, status_penarikan)
VALUES (6, 1000, 4400, 'offline', '615203', 'diajukan');
-- GAGAL: melanggar chk_saldo_mengendap (sisa saldo 4.400 < 10.000)
 
ROLLBACK;
 
SELECT id_user, saldo_total FROM dompet_saldo WHERE id_user = 6;   -- tetap 5400.00

-- Pengujian aturan bisnis SKPL
-- KF-03: estimasi berat kurang dari 3 kg
INSERT INTO transaksi_jemput (id_nasabah, estimasi_berat) VALUES (6, 2.00);
 
-- KF-06: sisa saldo di bawah Rp10.000
INSERT INTO penarikan_saldo (id_user, jumlah, saldo_setelah, jenis_penarikan)
VALUES (6, 1000, 4400, 'online');
 
-- KF-07: penarikan offline tanpa kode unik
INSERT INTO penarikan_saldo (id_user, jumlah, saldo_setelah, jenis_penarikan)
VALUES (4, 1000, 10000, 'offline');
