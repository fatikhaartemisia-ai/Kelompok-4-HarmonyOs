ALTER TABLE nasabah
  ADD COLUMN total_setoran_rp DECIMAL(15,2) NOT NULL DEFAULT 0;

UPDATE nasabah n
JOIN (
  SELECT id_nasabah, SUM(total) AS total
  FROM setoran
  GROUP BY
) x ON x.id_nasabah = n.id_pengguna
SET n.total_setoran_rp = x.total;
