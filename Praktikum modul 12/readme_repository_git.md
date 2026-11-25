# Praktikum Basis Data - Modul 12 (CockroachDB NewSQL)

**Topik:** Pemrosesan Query, Query Cost, dan Kontrol Akses pada DBMS Target (NewSQL: CockroachDB)  
**DBMS Target:** CockroachDB (NewSQL)  
**Proyek PjBL:** Aplikasi Bank Sampah Organik & Penjualan Kompos Digital Berbasis Kemitraan RT/RW untuk Mendukung Ekonomi Sirkular (SDG 12)

**Identitas Kelompok:**
1) Nama: Fakhriyatul Muzakkina (264311015)
2) Nama: Nashwa Nadia L. (264311023)
3) Nama: Fatikha Artemisia (264311016) 


---

## 📁 Struktur Repositori

```text
praktikum_modul12/
├── scripts/
│   ├── 01_migrasi_data_latihan.sql    # Migrasi data latihan transportasi (routes & trips)
│   ├── 02_query_transportasi.sql      # Baseline query, Rencana 1 vs Rencana 2, Index, & EXPLAIN
│   ├── 03_pengujian_dcl.sql           # DCL transport_db (CREATE USER, GRANT, REVOKE, & Least Privilege)
│   └── 04_rancangan_migrasi_pjbl.sql   # Rancangan NewSQL PjBL Bank Sampah (KF-11, View, & Roles)
├── dokumentasi/
│   ├── analisis_query_cost.pdf        # Analisis estimasi query cost & execution plan
│   └── laporan_modul12.pdf            # Laporan utama praktikum Modul 12
├── diagram/
│   └── query_tree.png                 # Diagram Query Tree aljabar relasional
└── README.md                          # Dokumentasi proyek repositori Git
```

---

## 🚀 Panduan Jalankan Cluster Lokal (CockroachDB)

1. **Inisialisasi Single-Node Cluster (Local Mode):**
   ```cmd
   cockroach.exe start-single-node --insecure --listen-addr=localhost:26257 --http-addr=localhost:8080
   ```
2. **Koneksi DBeaver:**
   - Provider / Driver: **PostgreSQL** atau **CockroachDB**
   - Host: `localhost` | Port: `26257` | Database: `defaultdb` | User: `root` | Password: *(Kosongkan)*
3. **Eksekusi Script:**
   Jalankan file SQL secara berurutan mulai dari `01_migrasi_data_latihan.sql` hingga `04_rancangan_migrasi_pjbl.sql`.

---

## 🛡️ Keamanan & Kredensial
- Seluruh kredensial dan password pada script bersifat *placeholder* (`GANTI_DENGAN_PASSWORD_KUAT`).
- Tidak ada password atau sertifikat SSL asli yang diunggah ke repositori Git publik.