-- 1. CREATE (Menambahkan Data Baru)
INSERT INTO pengguna (username, password, role) 
VALUES ('budi_nasabah', 'hash_password_123', 'nasabah');

INSERT INTO nasabah (id_pengguna, nama_nasabah, alamat, no_telepon) 
VALUES (LAST_INSERT_ID(), 'Budi Santoso', 'Jl. Pemuda No. 15', '081234567890');

-- 2. READ (Membaca/Menampilkan Data)
SELECT n.id_nasabah, n.nama_nasabah, p.username, n.alamat, n.no_telepon 
FROM nasabah n
JOIN pengguna p ON n.id_pengguna = p.id_pengguna;

-- 3. UPDATE (Memperbarui Data)
UPDATE nasabah 
SET alamat = 'Jl. Gajah Mada No. 88', no_telepon = '081999888777' 
WHERE nama_nasabah = 'Budi Santoso';

-- 4. DELETE (Menghapus Data)
DELETE FROM nasabah WHERE nama_nasabah = 'Budi Santoso';
