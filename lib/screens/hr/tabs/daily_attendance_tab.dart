import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../models/attendance_model.dart';
import '../../../providers/hr_provider.dart';
import '../../../providers/admin_provider.dart';

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

              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: record.status == 'Selesai' ? Colors.green : Colors.orange,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(getUserName(record.uid), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Masuk: ${record.waktuMasuk != null ? DateFormat('HH:mm').format(record.waktuMasuk!) : '-'} | '
                        'Pulang: ${record.waktuPulang != null ? DateFormat('HH:mm').format(record.waktuPulang!) : '-'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.map, color: Colors.blue),
                        onPressed: () => _showSingleLocationMap(context, record),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showGlobalMap(BuildContext context, HrProvider hrProvider) async {
    // Fetch data for the selected date to display on a single map
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final records = await hrProvider.getAttendanceByDateRange(_selectedDate, _selectedDate);
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

  void _showSingleLocationMap(BuildContext context, AttendanceModel record) {
    showDialog(
      context: context,
      builder: (context) {
        List<Marker> markers = [];
        ll.LatLng? center;

        if (record.lokasiMasuk != null) {
          center = ll.LatLng(record.lokasiMasuk!.latitude, record.lokasiMasuk!.longitude);
          markers.add(
            Marker(
              point: center,
              width: 40,
              height: 40,
              child: const Icon(Icons.location_on, color: Colors.green, size: 40),
            ),
          );
        }

        return AlertDialog(
          title: const Text('Lokasi Presensi'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: center == null
                ? const Center(child: Text('Data lokasi tidak tersedia.'))
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 15,
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
  }
}
