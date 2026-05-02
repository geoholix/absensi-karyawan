import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollModel {
  final String? idPayroll;
  final String uid;
  final DateTime periodeAwal;
  final DateTime periodeAkhir;
  final int jumlahHariKerjaNormal;
  final int jumlahHariKerjaLibur;
  final double totalJamLembur;
  final double gajiPokok;
  final double gajiLibur;
  final double gajiLembur;
  final double adjustment;
  final double totalPenerimaan;

  PayrollModel({
    this.idPayroll,
    required this.uid,
    required this.periodeAwal,
    required this.periodeAkhir,
    required this.jumlahHariKerjaNormal,
    required this.jumlahHariKerjaLibur,
    required this.totalJamLembur,
    required this.gajiPokok,
    required this.gajiLibur,
    required this.gajiLembur,
    required this.adjustment,
    required this.totalPenerimaan,
  });

  factory PayrollModel.fromMap(Map<String, dynamic> map, String id) {
    return PayrollModel(
      idPayroll: id,
      uid: map['uid'] ?? '',
      periodeAwal: (map['periode_awal'] as Timestamp).toDate(),
      periodeAkhir: (map['periode_akhir'] as Timestamp).toDate(),
      jumlahHariKerjaNormal: map['jumlah_hari_kerja_normal'] ?? 0,
      jumlahHariKerjaLibur: map['jumlah_hari_kerja_libur'] ?? 0,
      totalJamLembur: (map['total_jam_lembur'] ?? 0).toDouble(),
      gajiPokok: (map['gaji_pokok'] ?? 0).toDouble(),
      gajiLibur: (map['gaji_libur'] ?? 0).toDouble(),
      gajiLembur: (map['gaji_lembur'] ?? 0).toDouble(),
      adjustment: (map['adjustment'] ?? 0).toDouble(),
      totalPenerimaan: (map['total_penerimaan'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'periode_awal': Timestamp.fromDate(periodeAwal),
      'periode_akhir': Timestamp.fromDate(periodeAkhir),
      'jumlah_hari_kerja_normal': jumlahHariKerjaNormal,
      'jumlah_hari_kerja_libur': jumlahHariKerjaLibur,
      'total_jam_lembur': totalJamLembur,
      'gaji_pokok': gajiPokok,
      'gaji_libur': gajiLibur,
      'gaji_lembur': gajiLembur,
      'adjustment': adjustment,
      'total_penerimaan': totalPenerimaan,
    };
  }
}
