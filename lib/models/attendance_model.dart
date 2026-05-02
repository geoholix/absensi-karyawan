import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String? idAbsen;
  final String uid;
  final String tanggal; // YYYY-MM-DD
  final DateTime? waktuMasuk;
  final GeoPoint? lokasiMasuk;
  final String? fotoMasukUrl;
  final DateTime? waktuPulang;
  final GeoPoint? lokasiPulang;
  final String? fotoPulangUrl;
  final String shiftAktual; // Pagi, Malam, Pramuka
  final double totalJamNormal;
  final double totalJamLembur;
  final String status; // Selesai, Revisi HR, dll.

  AttendanceModel({
    this.idAbsen,
    required this.uid,
    required this.tanggal,
    this.waktuMasuk,
    this.lokasiMasuk,
    this.fotoMasukUrl,
    this.waktuPulang,
    this.lokasiPulang,
    this.fotoPulangUrl,
    required this.shiftAktual,
    this.totalJamNormal = 0,
    this.totalJamLembur = 0,
    this.status = 'Menunggu',
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      idAbsen: id,
      uid: map['uid'] ?? '',
      tanggal: map['tanggal'] ?? '',
      waktuMasuk: (map['waktu_masuk'] as Timestamp?)?.toDate(),
      lokasiMasuk: map['lokasi_masuk'] as GeoPoint?,
      fotoMasukUrl: map['foto_masuk_url'],
      waktuPulang: (map['waktu_pulang'] as Timestamp?)?.toDate(),
      lokasiPulang: map['lokasi_pulang'] as GeoPoint?,
      fotoPulangUrl: map['foto_pulang_url'],
      shiftAktual: map['shift_aktual'] ?? '',
      totalJamNormal: (map['total_jam_normal'] ?? 0).toDouble(),
      totalJamLembur: (map['total_jam_lembur'] ?? 0).toDouble(),
      status: map['status'] ?? 'Menunggu',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'tanggal': tanggal,
      'waktu_masuk': waktuMasuk != null ? Timestamp.fromDate(waktuMasuk!) : null,
      'lokasi_masuk': lokasiMasuk,
      'foto_masuk_url': fotoMasukUrl,
      'waktu_pulang': waktuPulang != null ? Timestamp.fromDate(waktuPulang!) : null,
      'lokasi_pulang': lokasiPulang,
      'foto_pulang_url': fotoPulangUrl,
      'shift_aktual': shiftAktual,
      'total_jam_normal': totalJamNormal,
      'total_jam_lembur': totalJamLembur,
      'status': status,
    };
  }
}
