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
