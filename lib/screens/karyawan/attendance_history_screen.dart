import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthProvider>(context).userModel?.uid;
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Presensi')),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: attendanceProvider.getAttendanceHistory(uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada riwayat presensi.'));
          }

          final history = snapshot.data!;

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final record = history[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  title: Text(
                    DateFormat('EEEE, d MMM yyyy').format(DateTime.parse(record.tanggal)),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shift: ${record.shiftAktual}'),
                      Text(
                        'Masuk: ${record.waktuMasuk != null ? DateFormat('HH:mm').format(record.waktuMasuk!) : '-'} | '
                        'Pulang: ${record.waktuPulang != null ? DateFormat('HH:mm').format(record.waktuPulang!) : '-'}',
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${record.totalJamNormal.toStringAsFixed(1)} Jam',
                        style: const TextStyle(color: Colors.green),
                      ),
                      if (record.totalJamLembur > 0)
                        Text(
                          '+${record.totalJamLembur.toStringAsFixed(1)} Lembur',
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
