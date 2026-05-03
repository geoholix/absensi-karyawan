import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/hr_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/leave_model.dart';
import '../../../models/user_model.dart';

class LeaveApprovalsTab extends StatelessWidget {
  const LeaveApprovalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HrProvider>(context);
    final users = Provider.of<AdminProvider>(context, listen: false).users;

    // Helper to find user name
    String getUserName(String uid) {
      try {
        return users.firstWhere((u) => u.uid == uid).nama;
      } catch (e) {
        return 'Unknown User';
      }
    }

    return StreamBuilder<List<LeaveModel>>(
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
}
