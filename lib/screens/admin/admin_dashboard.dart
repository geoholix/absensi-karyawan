import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Kelola Pengguna'),
        actions: [
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
                subtitle: Text('${user.role} - ${user.lokasi_kerja} (${user.bagian})'),
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
                    DropdownButtonFormField<String>(
                      value: selectedLokasi,
                      decoration: const InputDecoration(labelText: 'Lokasi Kerja'),
                      items: ['Pramuka', 'Non-Pramuka'].map((lok) {
                        return DropdownMenuItem(value: lok, child: Text(lok));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedLokasi = val!),
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
