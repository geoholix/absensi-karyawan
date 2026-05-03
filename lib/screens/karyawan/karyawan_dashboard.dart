import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/user_model.dart';
import 'attendance_history_screen.dart';
import 'payslip_screen.dart';

class KaryawanDashboard extends StatefulWidget {
  const KaryawanDashboard({super.key});

  @override
  State<KaryawanDashboard> createState() => _KaryawanDashboardState();
}

class _KaryawanDashboardState extends State<KaryawanDashboard> {
  late Timer _timer;
  String _currentTime = '';
  String? _selectedShift;

  @override
  void initState() {
    super.initState();
    _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
        });
      }
    });

    // Fetch initial status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
      if (uid != null) {
        final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
        attProvider.fetchTodayAttendance(uid);
        
        final userModel = Provider.of<AuthProvider>(context, listen: false).userModel;
        if (userModel != null) {
          attProvider.fetchOfficeLocation(userModel.lokasiKerja);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final today = attendanceProvider.todayAttendance;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 40),
            const SizedBox(width: 10),
            const Text('Presensi Karyawan', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE91E63),
                  child: Text(
                    user?.nama.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${user?.nama ?? 'User'}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('${user?.bagian ?? '-'} | ${user?.lokasiKerja ?? '-'}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Digital Clock Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE91E63), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(color: Color(0xFFE91E63), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Attendance Status Card
            const Text(
              'Status Presensi Hari Ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildStatusCard(
                  'Masuk',
                  today?.waktuMasuk != null ? DateFormat('HH:mm').format(today!.waktuMasuk!) : '--:--',
                  Icons.login,
                  Colors.green,
                ),
                const SizedBox(width: 15),
                _buildStatusCard(
                  'Pulang',
                  today?.waktuPulang != null ? DateFormat('HH:mm').format(today!.waktuPulang!) : '--:--',
                  Icons.logout,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Navigation Cards
            const Text(
              'Layanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildMenuCard(
                  context,
                  'Riwayat',
                  Icons.history,
                  Colors.blue,
                  const AttendanceHistoryScreen(),
                ),
                const SizedBox(width: 15),
                _buildMenuCard(
                  context,
                  'Slip Gaji',
                  Icons.receipt_long,
                  Colors.purple,
                  const PayslipScreen(),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Action Section
            if (attendanceProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (today == null)
              _buildCheckInAction(user, attendanceProvider)
            else if (today.waktuPulang == null)
              _buildCheckOutAction(user)
            else
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 60),
                    SizedBox(height: 10),
                    Text(
                      'Anda sudah menyelesaikan absensi hari ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String time, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(
              time,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, Widget screen) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInAction(UserModel? user, AttendanceProvider provider) {
    bool hasShifts = provider.officeLocation?.hasShifts ?? false;

    return Column(
      children: [
        if (hasShifts) ...[
          const Text('Pilih Shift Kerja Anda:'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedShift,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
            items: ['Pagi', 'Malam'].map((s) {
              return DropdownMenuItem(value: s, child: Text('Shift $s'));
            }).toList(),
            onChanged: (val) => setState(() => _selectedShift = val),
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: (hasShifts && _selectedShift == null)
                ? null
                : () async {
                    try {
                      await Provider.of<AttendanceProvider>(context, listen: false)
                          .checkIn(user!, _selectedShift ?? 'Pagi');
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('ABSEN MASUK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckOutAction(UserModel? user) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () async {
          try {
            await Provider.of<AttendanceProvider>(context, listen: false).checkOut(user!);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text('ABSEN PULANG', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
