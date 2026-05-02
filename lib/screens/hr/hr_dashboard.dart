import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../providers/hr_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';

class HrDashboard extends StatefulWidget {
  const HrDashboard({super.key});

  @override
  State<HrDashboard> createState() => _HrDashboardState();
}

class _HrDashboardState extends State<HrDashboard> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HrProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HR - Monitoring Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Pilih Tanggal'),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<AttendanceModel>>(
              stream: hrProvider.getDailyAttendanceStream(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada data absensi untuk tanggal ini.'));
                }

                final records = snapshot.data!;

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: record.status == 'Selesai' ? Colors.green : Colors.orange,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text('UID: ${record.uid.substring(0, 8)}...'), // Should resolve to name
                        subtitle: Text(
                          'Masuk: ${record.waktuMasuk != null ? DateFormat('HH:mm').format(record.waktuMasuk!) : '-'} | '
                          'Pulang: ${record.waktuPulang != null ? DateFormat('HH:mm').format(record.waktuPulang!) : '-'}',
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _showEditAttendanceDialog(context, record),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAttendanceDialog(BuildContext context, AttendanceModel record) {
    // Basic editing for Masuk and Pulang times
    TimeOfDay? masukTime = record.waktuMasuk != null ? TimeOfDay.fromDateTime(record.waktuMasuk!) : null;
    TimeOfDay? pulangTime = record.waktuPulang != null ? TimeOfDay.fromDateTime(record.waktuPulang!) : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Revisi Absensi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Waktu Masuk'),
                    subtitle: Text(masukTime?.format(context) ?? 'Belum Absen'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: masukTime ?? TimeOfDay.now());
                      if (picked != null) setState(() => masukTime = picked);
                    },
                  ),
                  ListTile(
                    title: const Text('Waktu Pulang'),
                    subtitle: Text(pulangTime?.format(context) ?? 'Belum Absen'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: pulangTime ?? TimeOfDay.now());
                      if (picked != null) setState(() => pulangTime = picked);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    // Update the record (simplified update)
                    DateTime? newMasuk = record.waktuMasuk;
                    if (masukTime != null) {
                      newMasuk = DateTime(
                        record.waktuMasuk?.year ?? _selectedDate.year,
                        record.waktuMasuk?.month ?? _selectedDate.month,
                        record.waktuMasuk?.day ?? _selectedDate.day,
                        masukTime!.hour,
                        masukTime!.minute,
                      );
                    }

                    DateTime? newPulang = record.waktuPulang;
                    if (pulangTime != null) {
                      newPulang = DateTime(
                        record.waktuPulang?.year ?? _selectedDate.year,
                        record.waktuPulang?.month ?? _selectedDate.month,
                        record.waktuPulang?.day ?? _selectedDate.day,
                        pulangTime!.hour,
                        pulangTime!.minute,
                      );
                    }

                    final updatedRecord = AttendanceModel(
                      idAbsen: record.idAbsen,
                      uid: record.uid,
                      tanggal: record.tanggal,
                      waktuMasuk: newMasuk,
                      lokasiMasuk: record.lokasiMasuk,
                      fotoMasukUrl: record.fotoMasukUrl,
                      waktuPulang: newPulang,
                      lokasiPulang: record.lokasiPulang,
                      fotoPulangUrl: record.fotoPulangUrl,
                      shiftAktual: record.shiftAktual,
                      totalJamNormal: record.totalJamNormal, // HR should probably trigger recalculate or manual
                      totalJamLembur: record.totalJamLembur,
                      status: 'Revisi HR',
                    );

                    Provider.of<HrProvider>(context, listen: false).updateAttendance(updatedRecord);
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
