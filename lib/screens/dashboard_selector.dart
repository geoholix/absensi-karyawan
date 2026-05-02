import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'karyawan/karyawan_dashboard.dart';
import 'admin/admin_dashboard.dart';

class DashboardSelector extends StatelessWidget {
  const DashboardSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.userModel == null) {
      return const LoginScreen();
    }

    // Role-based routing
    switch (authProvider.userModel!.role) {
      case 'Admin':
        return const AdminDashboard();
      case 'HR':
        return const Scaffold(body: Center(child: Text('HR Dashboard (Coming Soon)')));
      case 'Karyawan':
      default:
        return const KaryawanDashboard();
    }
  }
}
