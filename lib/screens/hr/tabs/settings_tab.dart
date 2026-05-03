import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/user_model.dart';
import '../../../models/office_location_model.dart';
import '../../../scripts/seeder.dart';
import '../../admin/manage_locations_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Pramuka', 'Bogor', 'Toko'];

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageLocationsScreen())),
                icon: const Icon(Icons.location_city),
                label: const Text('Lokasi Kantor'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white),
              ),
              // Seeder is a destructive dev tool — only available in debug builds.
              if (kDebugMode)
                ElevatedButton.icon(
                  onPressed: () async {
                    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
                    await Seeder.seedDummyData();
                    if (!context.mounted) return;
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dummy data dimuat!')));
                  },
                  icon: const Icon(Icons.dataset),
                  label: const Text('Load Data'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white),
                ),
            ],
          ),
        ),
        const Divider(color: Colors.grey),
        
        // Filter Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Text('Filter Lokasi: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: _filters.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedFilter = val);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: adminProvider.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Tidak ada pengguna terdaftar.'));
              }

              // Apply Filter
              final users = snapshot.data!.where((u) {
                if (_selectedFilter == 'Semua') return true;
                return u.lokasiKerja.toLowerCase().contains(_selectedFilter.toLowerCase());
              }).toList();

              if (users.isEmpty) {
                return const Center(child: Text('Tidak ada pengguna di lokasi ini.'));
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE91E63),
                        child: Text(user.nama.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(user.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${user.role} - ${user.lokasiKerja} (${user.bagian})'),
                      trailing: const Icon(Icons.edit, color: Colors.white70),
                      onTap: () => _showEditUserDialog(context, user),
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

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.nama);
    final idController = TextEditingController(text: user.idKaryawan);
    final bagianController = TextEditingController(text: user.bagian);
    final honorNormalController = TextEditingController(text: user.honorNormal.toString());
    final honorLiburController = TextEditingController(text: user.honorLibur.toString());
    String selectedRole = (user.role == 'Admin') ? 'HR' : user.role;
    String selectedLokasi = user.lokasiKerja;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Karyawan: ${user.email}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
                    TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID Karyawan')),
                    TextField(controller: bagianController, decoration: const InputDecoration(labelText: 'Bagian')),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: ['HR', 'Karyawan'].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedRole = val!),
                    ),
                    StreamBuilder<List<OfficeLocationModel>>(
                      stream: Provider.of<AdminProvider>(context, listen: false).getOfficeLocationsStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final locations = snapshot.data!;
                        if (!locations.any((l) => l.id == selectedLokasi)) {
                          locations.add(OfficeLocationModel(id: selectedLokasi, name: selectedLokasi, latitude: 0, longitude: 0, requireGeofencing: false, radius: 0, hasShifts: false));
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedLokasi,
                          decoration: const InputDecoration(labelText: 'Lokasi Kerja'),
                          items: locations.map((lok) => DropdownMenuItem(value: lok.id, child: Text(lok.name))).toList(),
                          onChanged: (val) => setState(() => selectedLokasi = val!),
                        );
                      }
                    ),
                    TextField(controller: honorNormalController, decoration: const InputDecoration(labelText: 'Honor Normal (Harian)'), keyboardType: TextInputType.number),
                    TextField(controller: honorLiburController, decoration: const InputDecoration(labelText: 'Honor Libur (Harian)'), keyboardType: TextInputType.number),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    final updatedUser = UserModel(
                      uid: user.uid,
                      idKaryawan: idController.text,
                      nama: nameController.text,
                      email: user.email,
                      bagian: bagianController.text,
                      role: selectedRole,
                      lokasiKerja: selectedLokasi,
                      honorNormal: double.tryParse(honorNormalController.text) ?? 0.0,
                      honorLibur: double.tryParse(honorLiburController.text) ?? 0.0,
                      createdAt: user.createdAt,
                    );
                    Provider.of<AdminProvider>(context, listen: false).updateUser(updatedUser);
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
