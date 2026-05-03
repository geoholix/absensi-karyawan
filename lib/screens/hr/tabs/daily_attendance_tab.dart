import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/attendance_model.dart';
import '../../../providers/hr_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/formatters.dart';

class DailyAttendanceTab extends StatefulWidget {
  const DailyAttendanceTab({super.key});

  @override
  State<DailyAttendanceTab> createState() => _DailyAttendanceTabState();
}

class _DailyAttendanceTabState extends State<DailyAttendanceTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HrProvider>(context);
    final users = Provider.of<AdminProvider>(context).users;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
              ),
              ElevatedButton.icon(
                onPressed: () => _showGlobalMap(context, hrProvider),
                icon: const Icon(Icons.map),
                label: const Text('Peta Global'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AttendanceModel>>(
            stream: hrProvider.getDailyAttendanceStream(_selectedDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (users.isEmpty) {
                return const Center(child: Text('Belum ada karyawan terdaftar di Pengaturan.'));
              }

              final records = snapshot.data ?? const <AttendanceModel>[];
              final byUid = <String, AttendanceModel>{
                for (final r in records) r.uid: r,
              };

              return SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFF1A237E)),
                      headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      dataRowColor: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
                      columns: const [
                        DataColumn(label: Text('Nama Karyawan')),
                        DataColumn(label: Text('Masuk')),
                        DataColumn(label: Text('Pulang')),
                        DataColumn(label: Text('Shift')),
                        DataColumn(label: Text('Lembur Masuk')),
                        DataColumn(label: Text('Lembur Pulang')),
                        DataColumn(label: Text('Keterangan')),
                        DataColumn(label: Text('Aksi')),
                      ],
                      rows: users.map((user) {
                        final record = byUid[user.uid];
                        return DataRow(
                          cells: [
                            DataCell(Text(user.nama, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataCell(_timeCell(
                              context,
                              label: 'Masuk',
                              time: record?.waktuMasuk,
                              photoUrl: record?.fotoMasukUrl,
                              location: record?.lokasiMasuk,
                            )),
                            DataCell(_timeCell(
                              context,
                              label: 'Pulang',
                              time: record?.waktuPulang,
                              photoUrl: record?.fotoPulangUrl,
                              location: record?.lokasiPulang,
                            )),
                            DataCell(Text(record?.shiftAktual.isNotEmpty == true ? record!.shiftAktual : '-', style: const TextStyle(color: Colors.white70))),
                            DataCell(_lemburCell(
                              context,
                              label: 'Lembur Masuk',
                              hours: record?.lemburMasuk,
                              photoUrl: record?.fotoMasukUrl,
                              location: record?.lokasiMasuk,
                            )),
                            DataCell(_lemburCell(
                              context,
                              label: 'Lembur Pulang',
                              hours: (record?.lemburPulang ?? 0) > 0 ? record!.lemburPulang : record?.totalJamLembur,
                              photoUrl: record?.fotoPulangUrl,
                              location: record?.lokasiPulang,
                            )),
                            DataCell(Text(record?.keterangan?.isNotEmpty == true ? record!.keterangan! : '-', style: const TextStyle(color: Colors.white70))),
                            DataCell(
                              IconButton(
                                icon: Icon(record == null ? Icons.add_circle : Icons.edit, color: record == null ? Colors.greenAccent : Colors.orange),
                                tooltip: record == null ? 'Tambah absen' : 'Edit absen',
                                onPressed: () => _showEditDialog(context, user, record, hrProvider),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _timeCell(
    BuildContext context, {
    required String label,
    required DateTime? time,
    required String? photoUrl,
    required GeoPoint? location,
  }) {
    if (time == null) {
      return const Text('-', style: TextStyle(color: Colors.white38));
    }
    final formatted = DateFormat('HH:mm').format(time);
    return InkWell(
      onTap: () => _showDetailDialog(context, title: '$label ($formatted)', photoUrl: photoUrl, location: location),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatted, style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 4),
          const Icon(Icons.touch_app, size: 14, color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _lemburCell(
    BuildContext context, {
    required String label,
    required double? hours,
    required String? photoUrl,
    required GeoPoint? location,
  }) {
    if (hours == null || hours <= 0) {
      return const Text('-', style: TextStyle(color: Colors.white38));
    }
    final formatted = '${hours.toStringAsFixed(1)} Jam';
    return InkWell(
      onTap: () => _showDetailDialog(context, title: '$label ($formatted)', photoUrl: photoUrl, location: location),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatted, style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 4),
          const Icon(Icons.touch_app, size: 14, color: Colors.blueAccent),
        ],
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context, {
    required String title,
    required String? photoUrl,
    required GeoPoint? location,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detail $title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (photoUrl != null && photoUrl.isNotEmpty) ...[
                  const Text('Foto:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Image.network(
                    photoUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 100),
                  ),
                  const SizedBox(height: 15),
                ],
                const Text('Lokasi:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: location == null
                      ? const Center(child: Text('Data GPS tidak tersedia'))
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: ll.LatLng(location.latitude, location.longitude),
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.geoholix.absensi_karyawan',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: ll.LatLng(location.latitude, location.longitude),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ],
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    UserModel user,
    AttendanceModel? record,
    HrProvider hrProvider,
  ) {
    TimeOfDay? masukTime = record?.waktuMasuk != null ? TimeOfDay.fromDateTime(record!.waktuMasuk!) : null;
    TimeOfDay? pulangTime = record?.waktuPulang != null ? TimeOfDay.fromDateTime(record!.waktuPulang!) : null;

    final normalController = TextEditingController(
      text: (record?.totalJamNormal ?? 0).toStringAsFixed(1),
    );
    final lemburController = TextEditingController(
      text: (record?.totalJamLembur ?? 0).toStringAsFixed(1),
    );

    void recompute() {
      if (masukTime == null || pulangTime == null) return;
      final masukDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, masukTime!.hour, masukTime!.minute);
      var pulangDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, pulangTime!.hour, pulangTime!.minute);
      if (!pulangDt.isAfter(masukDt)) {
        pulangDt = pulangDt.add(const Duration(days: 1));
      }
      final totalHours = pulangDt.difference(masukDt).inMinutes / 60.0;
      final normal = totalHours > 8 ? 8.0 : totalHours;
      final lembur = totalHours > 8 ? totalHours - 8 : 0.0;
      normalController.text = normal.toStringAsFixed(1);
      lemburController.text = lembur.toStringAsFixed(1);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(record == null ? 'Tambah Absen: ${user.nama}' : 'Edit Absen: ${user.nama}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Waktu Masuk'),
                      subtitle: Text(masukTime?.format(ctx) ?? 'Belum diset'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: masukTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            masukTime = picked;
                            recompute();
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Waktu Pulang'),
                      subtitle: Text(pulangTime?.format(ctx) ?? 'Belum diset'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: pulangTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            pulangTime = picked;
                            recompute();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: normalController,
                      decoration: const InputDecoration(
                        labelText: 'Total Waktu Kerja Normal (Jam)',
                        helperText: 'Otomatis terhitung dari waktu masuk & pulang',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: lemburController,
                      decoration: const InputDecoration(
                        labelText: 'Total Waktu Lembur (Jam)',
                        helperText: 'Otomatis terhitung dari waktu masuk & pulang',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    if (masukTime == null || pulangTime == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Lengkapi waktu masuk dan pulang.')),
                      );
                      return;
                    }
                    final masukDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, masukTime!.hour, masukTime!.minute);
                    var pulangDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, pulangTime!.hour, pulangTime!.minute);
                    if (!pulangDt.isAfter(masukDt)) {
                      pulangDt = pulangDt.add(const Duration(days: 1));
                    }

                    final normal = double.tryParse(normalController.text) ?? 0;
                    final lembur = double.tryParse(lemburController.text) ?? 0;

                    final updated = AttendanceModel(
                      idAbsen: record?.idAbsen,
                      uid: user.uid,
                      tanggal: Formatters.isoDateKey(_selectedDate),
                      waktuMasuk: masukDt,
                      lokasiMasuk: record?.lokasiMasuk,
                      fotoMasukUrl: record?.fotoMasukUrl,
                      waktuPulang: pulangDt,
                      lokasiPulang: record?.lokasiPulang,
                      fotoPulangUrl: record?.fotoPulangUrl,
                      shiftAktual: record?.shiftAktual.isNotEmpty == true ? record!.shiftAktual : Shifts.manualHr,
                      totalJamNormal: normal,
                      totalJamLembur: lembur,
                      lemburMasuk: record?.lemburMasuk ?? 0,
                      lemburPulang: record?.lemburPulang ?? 0,
                      status: AttendanceStatus.selesai,
                      keterangan: record?.keterangan,
                    );

                    try {
                      if (record == null) {
                        await hrProvider.manualAddAttendance(updated);
                      } else {
                        await hrProvider.updateAttendance(updated);
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Data berhasil disimpan.')),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGlobalMap(BuildContext context, HrProvider hrProvider) async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final records = await hrProvider.getAttendanceByDateRange(_selectedDate, _selectedDate);
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada marker untuk tanggal ini.')));
        return;
      }

      List<Marker> markers = [];
      ll.LatLng? center;

      final users = Provider.of<AdminProvider>(context, listen: false).users;

      for (var record in records) {
        String name = 'Unknown';
        try { name = users.firstWhere((u) => u.uid == record.uid).nama; } catch (_) {}

        if (record.lokasiMasuk != null) {
          center ??= ll.LatLng(record.lokasiMasuk!.latitude, record.lokasiMasuk!.longitude);
          markers.add(
            Marker(
              point: ll.LatLng(record.lokasiMasuk!.latitude, record.lokasiMasuk!.longitude),
              width: 100,
              height: 40,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    color: Colors.white,
                    child: Text(name, style: const TextStyle(fontSize: 10, color: Colors.black)),
                  ),
                  const Icon(Icons.location_on, color: Colors.green, size: 20),
                ],
              ),
            ),
          );
        }
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Peta Kehadiran Global (${DateFormat('dd MMM').format(_selectedDate)})'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: center == null
                  ? const Center(child: Text('Data GPS tidak tersedia.'))
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 12,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.geoholix.absensi_karyawan',
                        ),
                        MarkerLayer(markers: markers),
                      ],
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
