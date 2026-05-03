import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _alasanController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Cuti'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Tanggal Cuti:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_startDate != null ? DateFormat('dd MMM yyyy').format(_startDate!) : 'Mulai'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : 'Selesai'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Alasan Cuti:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _alasanController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Masukkan alasan cuti (misal: Sakit, Acara Keluarga, dll)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: attendanceProvider.isLoading ? null : _submitLeave,
                child: attendanceProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ajukan Cuti', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitLeave() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih tanggal mulai dan selesai.')));
      return;
    }
    if (_alasanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan cuti tidak boleh kosong.')));
      return;
    }

    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) return;

    try {
      await Provider.of<AttendanceProvider>(context, listen: false)
          .submitLeave(uid, _startDate!, _endDate!, _alasanController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuti berhasil diajukan.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
