import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';

class HrProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AttendanceModel>> getDailyAttendanceStream(DateTime date) {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _firestore
        .collection('attendance')
        .where('tanggal', isEqualTo: dateStr)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AttendanceModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> updateAttendance(AttendanceModel attendance) async {
    try {
      await _firestore
          .collection('attendance')
          .doc(attendance.idAbsen)
          .update(attendance.toMap());
    } catch (e) {
      print('Error updating attendance: $e');
      rethrow;
    }
  }
}
