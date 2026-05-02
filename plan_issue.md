# Deskripsi Tujuan

Membuat aplikasi absensi karyawan berbasis Flutter yang dapat berjalan di platform Android dan Web. Aplikasi ini menggunakan Firebase sebagai backend dan memiliki 3 role pengguna utama:
1. **Administrator**: Mengatur role pengguna dan penempatan karyawan.
2. **HR**: Melihat rekap absen, merevisi data absen, dan melakukan penyesuaian (adjustment) gaji.
3. **Karyawan**: Melakukan absensi (Masuk & Pulang) untuk jam kerja normal maupun lembur dengan menggunakan foto selfie berlatar belakang kantor dan pencatatan lokasi GPS, serta melihat slip gaji mingguan.

---

## Ketentuan & Aturan Bisnis
1. **Geofencing**: Dihilangkan. Keabsahan absen dibuktikan melalui foto selfie dengan background lingkungan kantor dan koordinat GPS.
2. **Perhitungan Gaji**: 
   - **Honor Normal**: Merupakan upah harian di hari kerja normal.
   - **Honor Libur**: Gaji karyawan yang bekerja di hari libur nasional (ditambah ekstra sesuai ketentuan, *Sistem dibuat fleksibel agar HR bisa menyesuaikan nilai penambahan ini*).
3. **Aturan Waktu Kerja (Normal)**:
   - **Karyawan Pramuka**: Jam kerja 07:00 - 16:00.
   - **Karyawan Non-Pramuka**: Memiliki 2 shift kerja (Karyawan bebas memilih shift saat akan absen):
     - *Shift Pagi*: 07:30 - 16:30
     - *Shift Malam*: 19:30 - 04:30
   - **Lembur**: Waktu kerja yang dilakukan di luar dari jam kerja normal sesuai lokasi/shift karyawan tersebut.

---

## Proposed Architecture & Tech Stack

- **Frontend**: Flutter (Android APK dan Web).
- **State Management**: Provider.
- **Backend as a Service (BaaS)**: Firebase (Auth, Firestore, Storage).
- **Device API**: `image_picker` / `camera` untuk selfie, `geolocator` untuk mencatat titik koordinat saat absen.

---

## Database Schema (Firestore)

### 1. Collection: `users`
Menyimpan data profil, role, penempatan lokasi, dan shift.
- `uid` (String) - Document ID dari Firebase Auth
- `id_karyawan` (String)
- `nama` (String)
- `email` (String)
- `bagian` (String)
- `role` (String) - "Admin", "HR", atau "Karyawan"
- `lokasi_kerja` (String) - "Pramuka" atau "Non-Pramuka"
- `honor_normal` (Number) - Gaji Harian
- `honor_libur` (Number) - Gaji Harian Hari Libur
- `created_at` (Timestamp)

### 2. Collection: `attendance`
Menyimpan rekam jejak absensi harian.
- `id_absen` (String)
- `uid` (String)
- `tanggal` (String) - Format YYYY-MM-DD
- `waktu_masuk` (Timestamp)
- `lokasi_masuk` (GeoPoint)
- `foto_masuk_url` (String)
- `waktu_pulang` (Timestamp)
- `lokasi_pulang` (GeoPoint)
- `foto_pulang_url` (String)
- `shift_aktual` (String) - Shift yang dipilih pada hari tersebut (Pagi/Malam/Pramuka)
- `total_jam_normal` (Number) - Dihitung otomatis berdasarkan selisih waktu masuk-pulang yang masuk dalam range jam kerja
- `total_jam_lembur` (Number) - Dihitung otomatis dari waktu kerja di luar range jam kerja
- `status` (String) - "Selesai", "Revisi HR", dll.

### 3. Collection: `payroll`
Menyimpan rekap gaji mingguan.
- `id_payroll` (String)
- `uid` (String)
- `periode_awal` (Timestamp)
- `periode_akhir` (Timestamp)
- `jumlah_hari_kerja_normal` (Number)
- `jumlah_hari_kerja_libur` (Number)
- `total_jam_lembur` (Number)
- `gaji_pokok` (Number) - (Jumlah hari * Honor Normal)
- `gaji_libur` (Number) - (Jumlah hari libur * Honor Libur)
- `gaji_lembur` (Number) - Berdasarkan total jam lembur
- `adjustment` (Number) - Penyesuaian (potongan/tambahan) dari HR
- `total_penerimaan` (Number)

---

## Proposed Changes (Phase Breakdown)

### Phase 1: Setup Lingkungan & Autentikasi
1. Inisialisasi project Flutter.
2. Menghubungkan aplikasi ke Project Firebase.
3. Setup Google OAuth dan Routing Role.

### Phase 2: Administrator Feature
1. UI Manajemen Pengguna: Admin dapat menambahkan/mengubah role, lokasi kerja (Pramuka/Non-Pramuka), dan rate honor harian.

### Phase 3: Karyawan Feature (Absensi Core)
1. **Dashboard**: Menampilkan pilihan shift bagi karyawan Non-Pramuka sebelum absen.
2. **Absensi Flow**:
   - Mengambil foto selfie (tanpa validasi Geofencing, murni foto dan record koordinat).
   - Validasi: Apakah jam saat ini terhitung Normal atau Lembur berdasarkan jadwal kerja:
     - *Pramuka*: Normal di luar 07:00 - 16:00 dihitung lembur.
     - *Non-Pramuka (Pagi)*: Normal di luar 07:30 - 16:30 dihitung lembur.
     - *Non-Pramuka (Malam)*: Normal di luar 19:30 - 04:30 dihitung lembur.

### Phase 4: HR Feature (Monitoring & Revisi)
1. Dashboard rekap kehadiran harian.
2. Fitur Revisi Absen: HR dapat mengoreksi jam masuk/pulang.

### Phase 5: HR Feature (Payroll Calculation)
1. Generate perhitungan Payroll mingguan secara otomatis berdasarkan rate harian (`honor_normal`) dan komponen lembur.
2. Fitur Adjustment (Penyesuaian).
