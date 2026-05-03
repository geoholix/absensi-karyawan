import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/office_location_model.dart';

class ManageLocationsScreen extends StatelessWidget {
  const ManageLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Lokasi Kantor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditLocationDialog(context, null),
          ),
        ],
      ),
      body: StreamBuilder<List<OfficeLocationModel>>(
        stream: adminProvider.getOfficeLocationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada lokasi kantor yang dikonfigurasi.'));
          }

          final locations = snapshot.data!;

          return ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final loc = locations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(loc.name),
                  subtitle: Text(
                    'Lat: ${loc.latitude}, Lng: ${loc.longitude}\n'
                    'Geofence: ${loc.requireGeofencing ? 'Aktif (${loc.radius}m)' : 'Nonaktif'} | '
                    'Pilih Shift: ${loc.hasShifts ? 'Ya' : 'Tidak'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditLocationDialog(context, loc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, loc.id),
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

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Lokasi'),
        content: const Text('Apakah Anda yakin ingin menghapus lokasi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<AdminProvider>(context, listen: false).deleteOfficeLocation(id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, OfficeLocationModel? location) {
    final idController = TextEditingController(text: location?.id ?? '');
    final nameController = TextEditingController(text: location?.name ?? '');
    final latController = TextEditingController(text: location?.latitude.toString() ?? '');
    final lngController = TextEditingController(text: location?.longitude.toString() ?? '');
    final radiusController = TextEditingController(text: location?.radius.toString() ?? '50');
    
    bool requireGeofencing = location?.requireGeofencing ?? true;
    bool hasShifts = location?.hasShifts ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(location == null ? 'Tambah Lokasi Baru' : 'Edit Lokasi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (location == null)
                      TextField(
                        controller: idController,
                        decoration: const InputDecoration(labelText: 'ID Lokasi (Unik, misal: Pramuka)'),
                      ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Tampilan (misal: Kantor Pramuka)'),
                    ),
                    TextField(
                      controller: latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    ),
                    TextField(
                      controller: lngController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    ),
                    SwitchListTile(
                      title: const Text('Wajib Geofencing?'),
                      value: requireGeofencing,
                      onChanged: (val) => setState(() => requireGeofencing = val),
                    ),
                    if (requireGeofencing)
                      TextField(
                        controller: radiusController,
                        decoration: const InputDecoration(labelText: 'Radius Maksimal (Meter)'),
                        keyboardType: TextInputType.number,
                      ),
                    SwitchListTile(
                      title: const Text('Karyawan Pilih Shift?'),
                      subtitle: const Text('Pilih Ya untuk shift Pagi/Malam'),
                      value: hasShifts,
                      onChanged: (val) => setState(() => hasShifts = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    final newLocation = OfficeLocationModel(
                      id: location?.id ?? idController.text.trim(),
                      name: nameController.text.trim(),
                      latitude: double.tryParse(latController.text) ?? 0.0,
                      longitude: double.tryParse(lngController.text) ?? 0.0,
                      requireGeofencing: requireGeofencing,
                      radius: int.tryParse(radiusController.text) ?? 50,
                      hasShifts: hasShifts,
                    );

                    if (location == null) {
                      Provider.of<AdminProvider>(context, listen: false).addOfficeLocation(newLocation);
                    } else {
                      Provider.of<AdminProvider>(context, listen: false).updateOfficeLocation(newLocation);
                    }

                    Navigator.pop(context);
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
}
