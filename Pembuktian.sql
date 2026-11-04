SELECT p.id_pengguna, p.nama, n.saldo, AS total_setoran_rp
FROM pengguna p
JOIN nasabah n ON p.id_pengguna = n.id_pengguna
ORDER BY n.saldo DESC;
