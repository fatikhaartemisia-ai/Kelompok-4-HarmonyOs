TAHAP 1: EKSPLORASI JOIN (Sebelum Denormalisasi)
SELECT p.id_pengguna,       
       p.nama,       
       COUNT(s.id_setoran) AS jumlah_setoran,       
       SUM(s.berat)        AS total_berat,       
       SUM(s.total)        AS total_nilai_rp
FROM pengguna p
JOIN nasabah n ON p.id_pengguna = n.id_pengguna
JOIN setoran s ON n.id_pengguna = s.id_nasabah
GROUP BY p.id_pengguna, p.nama;

-- Analisis performa dengan EXPLAIN:
EXPLAIN
SELECT p.id_pengguna,       
       p.nama,       
       COUNT(s.id_setoran) AS jumlah_setoran,       
       SUM(s.berat)        AS total_berat,       
       SUM(s.total)        AS total_nilai_rp
FROM pengguna p
JOIN nasabah n ON p.id_pengguna = n.id_pengguna
JOIN setoran s ON n.id_pengguna = s.id_nasabah
GROUP BY p.id_pengguna, p.nama;
