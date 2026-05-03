import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/office_location_model.dart';
import '../../scripts/seeder.dart';
import 'manage_locations_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Kelola Pengguna'),
        actions: [
          // Seeder is a destructive dev tool — only available in debug builds.
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.dataset),
              onPressed: () async {
                showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
                await Seeder.seedDummyData();
                if (!context.mounted) return;
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dummy data berhasil dimuat!')));
              },
              tooltip: 'Load Dummy Data (debug only)',
            ),
          IconButton(
            icon: const Icon(Icons.location_city),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageLocationsScreen())),
            tooltip: 'Kelola Lokasi Kantor',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: adminProvider.getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada pengguna terdaftar.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.nama.substring(0, 1).toUpperCase()),
                ),
                title: Text(user.nama),
                subtitle: Text('${user.role} - ${user.lokasiKerja} (${user.bagian})'),
                trailing: const Icon(Icons.edit),
                onTap: () => _showEditUserDialog(context, user),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.nama);
    final idController = TextEditingController(text: user.idKaryawan);
    final bagianController = TextEditingController(text: user.bagian);
    final honorNormalController = TextEditingController(text: user.honorNormal.toString());
    final honorLiburController = TextEditingController(text: user.honorLibur.toString());
    String selectedRole = user.role;
    String selectedLokasi = user.lokasiKerja;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Pengguna: ${user.email}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    ),
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(labelText: 'ID Karyawan'),
                    ),
                    TextField(
                      controller: bagianController,
                      decoration: const InputDecoration(labelText: 'Bagian'),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: ['Admin', 'HR', 'Karyawan'].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedRole = val!),
                    ),
                    StreamBuilder<List<OfficeLocationModel>>(
                      stream: Provider.of<AdminProvider>(context, listen: false).getOfficeLocationsStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final locations = snapshot.data!;
                        // Add current location if it's missing from DB to prevent Dropdown crash
                        if (!locations.any((l) => l.id == selectedLokasi)) {
                          locations.add(OfficeLocationModel(
                              id: selectedLokasi, name: selectedLokasi, 
                              latitude: 0, longitude: 0, requireGeofencing: false, radius: 0, hasShifts: false));
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedLokasi,
                          decoration: const InputDecoration(labelText: 'Lokasi Kerja'),
                          items: locations.map((lok) {
                            return DropdownMenuItem(value: lok.id, child: Text(lok.name));
                          }).toList(),
                          onChanged: (val) => setState(() => selectedLokasi = val!),
                        );
                      }
                    ),
                    TextField(
                      controller: honorNormalController,
                      decoration: const InputDecoration(labelText: 'Honor Normal (Harian)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: honorLiburController,
                      decoration: const InputDecoration(labelText: 'Honor Libur (Harian)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
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
