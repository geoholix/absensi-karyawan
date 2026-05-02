import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class KaryawanDashboard extends StatelessWidget {
  const KaryawanDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Karyawan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Selamat Datang, ${user?.nama ?? 'User'}'),
            const SizedBox(height: 20),
            const Text('Fitur Absensi akan segera hadir!'),
          ],
        ),
      ),
    );
  }
}
