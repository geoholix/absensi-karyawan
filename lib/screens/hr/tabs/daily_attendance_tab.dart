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
    final users = Provider.of<AdminProvider>(context, listen: false).users;

    String getUserName(String uid) {
      try {
        return users.firstWhere((u) => u.uid == uid).nama;
      } catch (e) {
        return uid.substring(0, 8);
      }
    }

    return Column(
      children: [
        // Date Selector & Map Button
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Tidak ada data absensi untuk tanggal ini.'));
              }

              final records = snapshot.data!;

              return Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowColor: MaterialStateProperty.all(const Color(0xFF1A237E)),
                          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          dataRowColor: MaterialStateProperty.all(const Color(0xFF1E1E1E)),
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
                          rows: records.map((record) {
                            return DataRow(
                              cells: [
                                DataCell(Text(getUserName(record.uid), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataCell(
                                  InkWell(
                                    onTap: () => _showDetailDialog(context, 'Masuk', record.waktuMasuk, record.fotoMasukUrl, record.lokasiMasuk),
                                    child: Row(
                                      children: [
                                        Text(record.waktuMasuk != null ? DateFormat('HH:mm').format(record.waktuMasuk!) : '-', style: const TextStyle(color: Colors.white70)),
                                        if (record.waktuMasuk != null) const Icon(Icons.touch_app, size: 14, color: Colors.blueAccent),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  InkWell(
                                    onTap: () => _showDetailDialog(context, 'Pulang', record.waktuPulang, record.fotoPulangUrl, record.lokasiPulang),
                                    child: Row(
                                      children: [
                                        Text(record.waktuPulang != null ? DateFormat('HH:mm').format(record.waktuPulang!) : '-', style: const TextStyle(color: Colors.white70)),
                                        if (record.waktuPulang != null) const Icon(Icons.touch_app, size: 14, color: Colors.blueAccent),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(Text(record.shiftAktual, style: const TextStyle(color: Colors.white70))),
                                DataCell(Text(record.lemburMasuk > 0 ? '${record.lemburMasuk.toStringAsFixed(1)} Jam' : '-', style: const TextStyle(color: Colors.white70))),
                                DataCell(Text(record.lemburPulang > 0 ? '${record.lemburPulang.toStringAsFixed(1)} Jam' : (record.totalJamLembur > 0 ? '${record.totalJamLembur.toStringAsFixed(1)} Jam' : '-'), style: const TextStyle(color: Colors.white70))),
                                DataCell(Text(record.keterangan ?? '-', style: const TextStyle(color: Colors.white70))),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () => _showEditDialog(context, record, hrProvider),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: () => _showManualEntryDialog(context, hrProvider, users),
                      backgroundColor: const Color(0xFFE91E63),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetailDialog(BuildContext context, String type, DateTime? time, String? photoUrl, GeoPoint? location) {
    if (time == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detail $type (${DateFormat('HH:mm').format(time)})'),
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

  void _showEditDialog(BuildContext context, AttendanceModel record, HrProvider hrProvider) {
    TimeOfDay? masukTime = record.waktuMasuk != null ? TimeOfDay.fromDateTime(record.waktuMasuk!) : null;
    TimeOfDay? pulangTime = record.waktuPulang != null ? TimeOfDay.fromDateTime(record.waktuPulang!) : null;
    
    final shiftController = TextEditingController(text: record.shiftAktual);
    final lemburMasukController = TextEditingController(text: record.lemburMasuk.toString());
    final lemburPulangController = TextEditingController(text: record.lemburPulang > 0 ? record.lemburPulang.toString() : record.totalJamLembur.toString());
    final keteranganController = TextEditingController(text: record.keterangan ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Data Absen'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Waktu Masuk'),
                      subtitle: Text(masukTime?.format(context) ?? '-'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: masukTime ?? TimeOfDay.now());
                        if (picked != null) setState(() => masukTime = picked);
                      },
                    ),
                    ListTile(
                      title: const Text('Waktu Pulang'),
                      subtitle: Text(pulangTime?.format(context) ?? '-'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: pulangTime ?? TimeOfDay.now());
                        if (picked != null) setState(() => pulangTime = picked);
                      },
                    ),
                    TextField(controller: shiftController, decoration: const InputDecoration(labelText: 'Shift Aktual')),
                    TextField(controller: lemburMasukController, decoration: const InputDecoration(labelText: 'Lembur Masuk (Jam)'), keyboardType: TextInputType.number),
                    TextField(controller: lemburPulangController, decoration: const InputDecoration(labelText: 'Lembur Pulang (Jam)'), keyboardType: TextInputType.number),
                    TextField(controller: keteranganController, decoration: const InputDecoration(labelText: 'Keterangan'), maxLines: 2),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    DateTime? newMasuk = masukTime != null ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, masukTime!.hour, masukTime!.minute) : null;
                    DateTime? newPulang = pulangTime != null ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, pulangTime!.hour, pulangTime!.minute) : null;
                    
                    double lMasuk = double.tryParse(lemburMasukController.text) ?? 0;
                    double lPulang = double.tryParse(lemburPulangController.text) ?? 0;

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
                      shiftAktual: shiftController.text,
                      totalJamNormal: record.totalJamNormal,
                      totalJamLembur: lMasuk + lPulang,
                      lemburMasuk: lMasuk,
                      lemburPulang: lPulang,
                      status: record.status,
                      keterangan: keteranganController.text,
                    );

                    hrProvider.updateAttendance(updatedRecord);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil diperbarui.')));
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

  void _showManualEntryDialog(BuildContext context, HrProvider hrProvider, List<UserModel> users) {
    UserModel? selectedUser;
    TimeOfDay? masukTime;
    TimeOfDay? pulangTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Input Absen Manual'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<UserModel>(
                      decoration: const InputDecoration(labelText: 'Pilih Karyawan'),
                      items: users.map((u) => DropdownMenuItem(value: u, child: Text(u.nama))).toList(),
                      onChanged: (val) => setState(() => selectedUser = val),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: const Text('Waktu Masuk'),
                      subtitle: Text(masukTime?.format(context) ?? 'Belum diset'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setState(() => masukTime = picked);
                      },
                    ),
                    ListTile(
                      title: const Text('Waktu Pulang'),
                      subtitle: Text(pulangTime?.format(context) ?? 'Belum diset'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setState(() => pulangTime = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedUser == null || masukTime == null || pulangTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua data.')));
                      return;
                    }

                    DateTime masukDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, masukTime!.hour, masukTime!.minute);
                    DateTime pulangDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, pulangTime!.hour, pulangTime!.minute);
                    
                    double totalHours = pulangDt.difference(masukDt).inMinutes / 60.0;
                    double jamNormal = totalHours > 8 ? 8 : totalHours;
                    double jamLembur = totalHours > 8 ? totalHours - 8 : 0;

                    final record = AttendanceModel(
                      idAbsen: '',
                      uid: selectedUser!.uid,
                      tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
                      waktuMasuk: masukDt,
                      waktuPulang: pulangDt,
                      shiftAktual: 'Manual HR',
                      totalJamNormal: jamNormal,
                      totalJamLembur: jamLembur,
                      lemburMasuk: 0,
                      lemburPulang: jamLembur,
                      status: 'Selesai',
                    );

                    hrProvider.manualAddAttendance(record);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Absensi manual berhasil disimpan.')));
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
      Navigator.pop(context);

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
                        initialCenter: center!,
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
