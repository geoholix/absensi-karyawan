import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'payroll_screen.dart';

import 'tabs/analytics_tab.dart';
import 'tabs/daily_attendance_tab.dart';
import 'tabs/employee_report_tab.dart';
import 'tabs/leave_approvals_tab.dart';
import 'tabs/settings_tab.dart';

class HrDashboard extends StatefulWidget {
  const HrDashboard({super.key});

  @override
  State<HrDashboard> createState() => _HrDashboardState();
}

class _HrDashboardState extends State<HrDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const AnalyticsTab(),
    const DailyAttendanceTab(),
    const EmployeeReportTab(),
    const LeaveApprovalsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR - Monitoring Absensi', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.payments),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollScreen())),
            tooltip: 'Kelola Payroll',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFE91E63),
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Analitik'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Harian'),
          BottomNavigationBarItem(icon: Icon(Icons.person_search), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.event_available), label: 'Cuti'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}

