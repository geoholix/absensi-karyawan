import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../models/payroll_model.dart';
import '../models/leave_model.dart';

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

  // --- Leave Management ---
  Stream<List<LeaveModel>> getLeavesStream() {
    return _firestore
        .collection('leaves')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LeaveModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> updateLeaveStatus(String id, String status) async {
    try {
      await _firestore.collection('leaves').doc(id).update({'status': status});
    } catch (e) {
      print('Error updating leave: $e');
      rethrow;
    }
  }

  // --- Analytics & Reporting ---
  Future<List<AttendanceModel>> getAttendanceByDateRange(DateTime start, DateTime end, {String? uid}) async {
    String startStr = DateFormat('yyyy-MM-dd').format(start);
    String endStr = DateFormat('yyyy-MM-dd').format(end);

    Query query = _firestore
        .collection('attendance')
        .where('tanggal', isGreaterThanOrEqualTo: startStr)
        .where('tanggal', isLessThanOrEqualTo: endStr);
    
    if (uid != null) {
      query = query.where('uid', isEqualTo: uid);
    }

    var snapshot = await query.get();
    return snapshot.docs.map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
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

  Future<void> generatePayroll({
    required DateTime start,
    required DateTime end,
    required List<UserModel> allUsers,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      for (var user in allUsers) {
        // Fetch attendance for this user in period
        String startStr = DateFormat('yyyy-MM-dd').format(start);
        String endStr = DateFormat('yyyy-MM-dd').format(end);

        var snapshot = await _firestore
            .collection('attendance')
            .where('uid', isEqualTo: user.uid)
            .where('tanggal', isGreaterThanOrEqualTo: startStr)
            .where('tanggal', isLessThanOrEqualTo: endStr)
            .get();

        List<AttendanceModel> records = snapshot.docs.map((doc) => AttendanceModel.fromMap(doc.data(), doc.id)).toList();

        int normalDays = 0;
        int liburDays = 0;
        double totalLemburHours = 0;

        for (var record in records) {
          // Simplified: check if date is weekend for 'libur' or we could have a holiday list
          // For now, let's assume Sunday is Libur
          DateTime date = DateTime.parse(record.tanggal);
          if (date.weekday == DateTime.sunday) {
            liburDays++;
          } else {
            normalDays++;
          }
          totalLemburHours += record.totalJamLembur;
        }

        double gajiPokok = normalDays * user.honorNormal;
        double gajiLibur = liburDays * user.honorLibur;
        
        // Lembur rate: assume 1/8 of normal daily rate per hour
        double lemburRate = user.honorNormal / 8;
        double gajiLembur = totalLemburHours * lemburRate;

        PayrollModel payroll = PayrollModel(
          uid: user.uid,
          periodeAwal: start,
          periodeAkhir: end,
          jumlahHariKerjaNormal: normalDays,
          jumlahHariKerjaLibur: liburDays,
          totalJamLembur: totalLemburHours,
          gajiPokok: gajiPokok,
          gajiLibur: gajiLibur,
          gajiLembur: gajiLembur,
          adjustment: 0,
          totalPenerimaan: gajiPokok + gajiLibur + gajiLembur,
          status: 'Pending',
        );

        await _firestore.collection('payroll').add(payroll.toMap());
      }
    } catch (e) {
      print('Error generating payroll: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<PayrollModel>> getAllPayrollsStream() {
    return _firestore
        .collection('payroll')
        .orderBy('periode_akhir', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PayrollModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> updatePayrollAdjustment(String id, double adjustment) async {
    try {
      // Fetch the payroll to recalculate total
      DocumentSnapshot doc = await _firestore.collection('payroll').doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double gajiPokok = (data['gaji_pokok'] ?? 0).toDouble();
        double gajiLibur = (data['gaji_libur'] ?? 0).toDouble();
        double gajiLembur = (data['gaji_lembur'] ?? 0).toDouble();
        
        double total = gajiPokok + gajiLibur + gajiLembur + adjustment;
        
        await _firestore.collection('payroll').doc(id).update({
          'adjustment': adjustment,
          'total_penerimaan': total,
        });
      }
    } catch (e) {
      print('Error updating adjustment: $e');
      rethrow;
    }
  }

  Future<void> updatePayrollStatus(String id, String status) async {
    try {
      await _firestore.collection('payroll').doc(id).update({'status': status});
    } catch (e) {
      print('Error updating payroll status: $e');
      rethrow;
    }
  }

  Future<void> manualAddAttendance(AttendanceModel attendance) async {
    try {
      await _firestore.collection('attendance').add(attendance.toMap());
    } catch (e) {
      print('Error adding manual attendance: $e');
      rethrow;
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
}
