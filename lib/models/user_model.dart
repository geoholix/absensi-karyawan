import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String idKaryawan;
  final String nama;
  final String email;
  final String bagian;
  final String role; // Admin, HR, Karyawan
  final String lokasiKerja; // Pramuka, Non-Pramuka
  final double honorNormal;
  final double honorLibur;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.idKaryawan,
    required this.nama,
    required this.email,
    required this.bagian,
    required this.role,
    required this.lokasiKerja,
    required this.honorNormal,
    required this.honorLibur,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      idKaryawan: map['id_karyawan'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      bagian: map['bagian'] ?? '',
      role: map['role'] ?? 'Karyawan',
      lokasiKerja: map['lokasi_kerja'] ?? 'Pramuka',
      honorNormal: (map['honor_normal'] ?? 0).toDouble(),
      honorLibur: (map['honor_libur'] ?? 0).toDouble(),
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'id_karyawan': idKaryawan,
      'nama': nama,
      'email': email,
      'bagian': bagian,
      'role': role,
      'lokasi_kerja': lokasiKerja,
      'honor_normal': honorNormal,
      'honor_libur': honorLibur,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
