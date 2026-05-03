import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/hr_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../models/leave_model.dart';
import '../../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveApprovalsTab extends StatelessWidget {
  const LeaveApprovalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HrProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final users = Provider.of<AdminProvider>(context).users;

    // Helper to find user name
    String getUserName(String uid) {
      try {
        return users.firstWhere((u) => u.uid == uid).nama;
      } catch (e) {
        return 'Unknown User';
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<LeaveModel>>(
        stream: hrProvider.getLeavesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada pengajuan cuti.'));
          }

          final leaves = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              final name = getUserName(leave.uid);
              final tglMulai = DateFormat('dd MMM yyyy').format(leave.tanggalMulai);
              final tglSelesai = DateFormat('dd MMM yyyy').format(leave.tanggalSelesai);
              final isPending = leave.status == 'Pending';

              return Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: leave.status == 'Approved' ? Colors.green : (leave.status == 'Rejected' ? Colors.red : Colors.orange),
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text('$name - $tglMulai s/d $tglSelesai', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text('Alasan: ${leave.alasan}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 5),
                      Text('Status: ${leave.status}', style: TextStyle(fontWeight: FontWeight.bold, color: leave.status == 'Approved' ? Colors.green : Colors.white)),
                    ],
                  ),
                  trailing: isPending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _updateStatus(context, leave.id, 'Approved'),
                              tooltip: 'Approve',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _updateStatus(context, leave.id, 'Rejected'),
                              tooltip: 'Reject',
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showManualLeaveDialog(context, attendanceProvider, hrProvider, users),
        backgroundColor: const Color(0xFFE91E63),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _updateStatus(BuildContext context, String id, String status) async {
    try {
      await Provider.of<HrProvider>(context, listen: false).updateLeaveStatus(id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cuti di-$status')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showManualLeaveDialog(BuildContext context, AttendanceProvider attendanceProvider, HrProvider hrProvider, List<UserModel> users) {
    UserModel? selectedUser;
    DateTime? startDate;
    DateTime? endDate;
    final alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Input Cuti Manual'),
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
                      title: const Text('Tanggal Mulai'),
                      subtitle: Text(startDate != null ? DateFormat('dd MMM yyyy').format(startDate!) : 'Belum diset'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => startDate = picked);
                      },
                    ),
                    ListTile(
                      title: const Text('Tanggal Selesai'),
                      subtitle: Text(endDate != null ? DateFormat('dd MMM yyyy').format(endDate!) : 'Belum diset'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime(2023),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => endDate = picked);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: alasanController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Alasan Cuti (Cth: Manual HR)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedUser == null || startDate == null || endDate == null || alasanController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua data.')));
                      return;
                    }

                    try {
                      // Submit as Approved using Firestore directly
                      await FirebaseFirestore.instance.collection('leaves').add({
                        'uid': selectedUser!.uid,
                        'tanggal_mulai': Timestamp.fromDate(startDate!),
                        'tanggal_selesai': Timestamp.fromDate(endDate!),
                        'alasan': alasanController.text,
                        'status': 'Approved',
                        'created_at': FieldValue.serverTimestamp(),
                      });
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuti otomatis disetujui!')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
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
