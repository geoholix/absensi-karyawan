import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Seeder {
  static Future<void> seedDummyData() async {
    final firestore = FirebaseFirestore.instance;
    
    // Delete existing dummy attendance to prevent duplicates
    var existingAtt = await firestore.collection('attendance').where('foto_masuk_url', isEqualTo: 'https://via.placeholder.com/150').get();
    for (var doc in existingAtt.docs) {
      await doc.reference.delete();
    }

    // Users
    final users = [
      {
        'uid': 'dummy_001',
        'id_karyawan': '001',
        'nama': 'RATNO',
        'email': 'ratno@dummy.com',
        'bagian': 'CETAK 13',
        'role': 'Karyawan',
        'lokasi_kerja': 'Pramuka',
        'honor_normal': 118000,
        'honor_libur': 177000,
      },
      {
        'uid': 'dummy_002',
        'id_karyawan': '002',
        'nama': 'HELMI',
        'email': 'helmi@dummy.com',
        'bagian': 'CETAK 9',
        'role': 'Karyawan',
        'lokasi_kerja': 'Pramuka',
        'honor_normal': 97000,
        'honor_libur': 145500,
      },
      {
        'uid': 'dummy_003',
        'id_karyawan': '003',
        'nama': 'Pak Bitun',
        'email': 'bitun@dummy.com',
        'bagian': 'Bangunan',
        'role': 'Karyawan',
        'lokasi_kerja': 'Pramuka',
        'honor_normal': 170000,
        'honor_libur': 212500,
      },
      {
        'uid': 'dummy_004',
        'id_karyawan': '004',
        'nama': 'Djunaedi (Juju)',
        'email': 'djunaedi@dummy.com',
        'bagian': 'cetak 15',
        'role': 'Karyawan',
        'lokasi_kerja': 'Pramuka',
        'honor_normal': 112000,
        'honor_libur': 168000,
      },
      {
        'uid': 'dummy_005',
        'id_karyawan': '005',
        'nama': 'Andri',
        'email': 'andri@dummy.com',
        'bagian': 'es bgr/feb20',
        'role': 'Karyawan',
        'lokasi_kerja': 'Bogor',
        'honor_normal': 60000,
        'honor_libur': 75000,
      },
      {
        'uid': 'dummy_006',
        'id_karyawan': '006',
        'nama': 'restu Jae',
        'email': 'restu@dummy.com',
        'bagian': 'bogor/juli 23',
        'role': 'Karyawan',
        'lokasi_kerja': 'Bogor',
        'honor_normal': 40000,
        'honor_libur': 50000,
      },
    ];

    for (var u in users) {
      await firestore.collection('users').doc(u['uid'] as String).set(u);
    }

    // Generate Attendance for the past 6 days + today
    final now = DateTime.now();
    for (int i = 0; i <= 6; i++) {
      final d = now.subtract(Duration(days: i));
      
      // Ratno (001): Masuk 07:24, Pulang 15:55
      await _addAttendance(firestore, 'dummy_001', d, 7, 24, 15, 55, 'Pramuka');
      
      // Helmi (002): Masuk 21:42, Pulang 23:16 (Overtime)
      await _addAttendance(firestore, 'dummy_002', d, 21, 42, 23, 16, 'Pramuka');
      
      // Pak Bitun (003): No attendance (0)

      // Djunaedi (004): Masuk 07:02, Pulang 15:09
      await _addAttendance(firestore, 'dummy_004', d, 7, 2, 15, 9, 'Pramuka');
      
      // Andri (005): Masuk 07:30, Pulang 16:30
      await _addAttendance(firestore, 'dummy_005', d, 7, 30, 16, 30, 'Pagi');
      
      // Restu (006): Masuk 07:30, Pulang 16:30
      await _addAttendance(firestore, 'dummy_006', d, 7, 30, 16, 30, 'Pagi');
    }
  }

  static Future<void> _addAttendance(FirebaseFirestore fs, String uid, DateTime date, int inH, int inM, int outH, int outM, String shift) async {
    final tMasuk = DateTime(date.year, date.month, date.day, inH, inM);
    DateTime tPulang = DateTime(date.year, date.month, date.day, outH, outM);
    if (outH < inH) tPulang = tPulang.add(const Duration(days: 1)); // Overnight

    String tgl = DateFormat('yyyy-MM-dd').format(date);
    
    // Calculate normal / lembur
    double total = tPulang.difference(tMasuk).inMinutes / 60.0;
    double normal = total > 8 ? 8 : total;
    double lembur = total > 8 ? total - 8 : 0;

    await fs.collection('attendance').add({
      'uid': uid,
      'tanggal': tgl,
      'waktu_masuk': Timestamp.fromDate(tMasuk),
      'waktu_pulang': Timestamp.fromDate(tPulang),
      'lokasi_masuk': const GeoPoint(-6.198337, 106.855571),
      'lokasi_pulang': const GeoPoint(-6.198337, 106.855571),
      'foto_masuk_url': 'https://via.placeholder.com/150',
      'foto_pulang_url': 'https://via.placeholder.com/150',
      'shift_aktual': shift,
      'status': 'Selesai',
      'total_jam_normal': normal,
      'total_jam_lembur': lembur,
    });
  }
}
