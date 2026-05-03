import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/hr_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/attendance_model.dart';
import '../../../models/user_model.dart';

class EmployeeReportTab extends StatefulWidget {
  const EmployeeReportTab({super.key});

  @override
  State<EmployeeReportTab> createState() => _EmployeeReportTabState();
}

class _EmployeeReportTabState extends State<EmployeeReportTab> {
  UserModel? _selectedUser;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<AttendanceModel> _records = [];
  bool _isLoading = false;

  void _fetchData() async {
    if (_selectedUser == null) return;
    setState(() => _isLoading = true);
    try {
      final records = await Provider.of<HrProvider>(context, listen: false)
          .getAttendanceByDateRange(_startDate, _endDate, uid: _selectedUser!.uid);
      setState(() => _records = records);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = Provider.of<AdminProvider>(context).users;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<UserModel>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  labelText: 'Pilih Karyawan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                items: users.map((u) => DropdownMenuItem(value: u, child: Text(u.nama))).toList(),
                onChanged: (val) {
                  setState(() => _selectedUser = val);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('dd MMM yyyy').format(_endDate)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedUser == null ? null : _fetchData,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
                  child: const Text('Cari Data'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty
                  ? const Center(child: Text('Data tidak ditemukan.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(record.tanggal)),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E63), fontSize: 16),
                                ),
                                const Divider(color: Colors.grey),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoColumn('Masuk', record.waktuMasuk, record.fotoMasukUrl),
                                    _buildInfoColumn('Pulang', record.waktuPulang, record.fotoPulangUrl),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text('Total Jam Normal: ${record.totalJamNormal.toStringAsFixed(1)} jam'),
                                Text('Total Jam Lembur: ${record.totalJamLembur.toStringAsFixed(1)} jam'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(String label, DateTime? time, String? photoUrl) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(time != null ? DateFormat('HH:mm').format(time) : '--:--'),
        const SizedBox(height: 5),
        if (photoUrl != null && photoUrl.isNotEmpty)
          GestureDetector(
            onTap: () => _showFullImage(photoUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
              ),
            ),
          )
        else
          const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      ],
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Image.network(url, fit: BoxFit.contain),
      ),
    );
  }
}
