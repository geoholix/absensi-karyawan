import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
  final String id;
  final String uid;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String alasan;
  final String status; // Pending, Approved, Rejected
  final DateTime createdAt;

  LeaveModel({
    required this.id,
    required this.uid,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.alasan,
    required this.status,
    required this.createdAt,
  });

  factory LeaveModel.fromMap(Map<String, dynamic> map, String docId) {
    return LeaveModel(
      id: docId,
      uid: map['uid'] ?? '',
      tanggalMulai: (map['tanggal_mulai'] as Timestamp).toDate(),
      tanggalSelesai: (map['tanggal_selesai'] as Timestamp).toDate(),
      alasan: map['alasan'] ?? '',
      status: map['status'] ?? 'Pending',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'tanggal_mulai': Timestamp.fromDate(tanggalMulai),
      'tanggal_selesai': Timestamp.fromDate(tanggalSelesai),
      'alasan': alasan,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
