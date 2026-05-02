# Product Overview: Aplikasi Absensi Karyawan

Aplikasi absensi karyawan modern berbasis mobile (Android) dan Web yang didesain interaktif dan simpel untuk mempermudah pencatatan kehadiran serta perhitungan gaji secara real-time.

## 🎯 Tujuan Utama
Memfasilitasi karyawan untuk melakukan presensi dengan akurat (menggunakan foto selfie & GPS) serta membantu tim HR dalam memonitoring jam kerja, memverifikasi lembur, dan mengotomatisasi perhitungan gaji (payroll) mingguan.

## 👥 Pengguna & Role (Akses)
Aplikasi ini mendukung 3 role utama dengan batasan akses masing-masing:
1. **Administrator**
   - Mengatur dan menetapkan role pengguna (Admin/HR/Karyawan).
2. **HR (Human Resources)**
   - Melihat dan memonitor daftar absensi harian karyawan.
   - Melakukan revisi/koreksi data absensi jika diperlukan.
   - Melakukan penyesuaian (adjustment) gaji dan menerbitkan payroll.
3. **Karyawan**
   - Melakukan absen Masuk dan absen Pulang.
   - Melakukan absen Lembur (Masuk & Pulang).
   - Melihat riwayat presensi harian dan Slip Gaji mingguan.

## ✨ Fitur Utama
- **Google OAuth Login**: Autentikasi yang cepat dan aman menggunakan akun Google.
- **Smart Attendance**: Absen menggunakan kamera (foto selfie di lingkungan kantor) dan *Geolocation* untuk merekam kordinat waktu nyata.
- **Overtime Tracking**: Sesi khusus bagi karyawan yang ingin mengambil lembur (Masuk Lembur & Pulang Lembur).
- **Automated Payroll System**: Rekapitulasi honor normal, honor hari libur, total jam kerja, keterlambatan, dan lembur secara otomatis berdasarkan data absensi aktual.

## 🛠 Tech Stack
- **Framework**: Flutter (untuk Web & Android APK)
- **Backend Services**: Firebase
  - *Firebase Authentication* (Google Sign-In)
  - *Cloud Firestore* (Penyimpanan data User, Absensi, dan Payroll)
  - *Firebase Storage* (Penyimpanan gambar foto selfie absensi)
- **Device API**: Kamera (Image Picker/Camera) & GPS (Geolocator)
