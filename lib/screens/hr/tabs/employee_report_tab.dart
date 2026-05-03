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
  final TextEditingController _userSearchController = TextEditingController();
  
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = Provider.of<AdminProvider>(context).users;
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    double totalJamNormal = 0;
    double totalJamLembur = 0;
    
    for (var r in _records) {
      totalJamNormal += r.totalJamNormal;
      totalJamLembur += r.totalJamLembur;
    }

    double estimasiSalary = 0;
    if (_selectedUser != null) {
      double normalPay = (totalJamNormal / 8) * _selectedUser!.honorNormal;
      double lemburPay = totalJamLembur * (_selectedUser!.honorNormal / 8);
      estimasiSalary = normalPay + lemburPay;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Autocomplete<UserModel>(
                  displayStringForOption: (UserModel option) => option.nama,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<UserModel>.empty();
                    }
                    return users.where((UserModel option) {
                      return option.nama.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (UserModel selection) {
                    setState(() => _selectedUser = selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        labelText: 'Cari Nama Karyawan',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    );
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
                                  Text('Total Jam Normal: ${record.totalJamNormal.toStringAsFixed(1)} jam', style: const TextStyle(color: Colors.white70)),
                                  Text('Total Jam Lembur: ${record.totalJamLembur.toStringAsFixed(1)} jam', style: const TextStyle(color: Colors.white70)),
                                  Text('Shift: ${record.shiftAktual}', style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Total Salary Estimation
          if (_records.isNotEmpty && _selectedUser != null)
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF1A237E),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimasi Salary:', style: TextStyle(color: Colors.white70)),
                      Text(formatCurrency.format(estimasiSalary), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Normal: ${totalJamNormal.toStringAsFixed(1)} Jam', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Lembur: ${totalJamLembur.toStringAsFixed(1)} Jam', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedUser == null ? null : () => _showManualEntryDialog(context, Provider.of<HrProvider>(context, listen: false)),
        backgroundColor: _selectedUser == null ? Colors.grey : const Color(0xFFE91E63),
        tooltip: 'Input Manual Absen',
        child: const Icon(Icons.add),
      ),
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

  void _showManualEntryDialog(BuildContext context, HrProvider hrProvider) {
    TimeOfDay? masukTime;
    TimeOfDay? pulangTime;
    DateTime tgl = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Input Absen Manual: ${_selectedUser!.nama}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Tanggal'),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(tgl)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tgl,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => tgl = picked);
                      },
                    ),
                    ListTile(
                      title: const Text('Waktu Masuk'),
                      subtitle: Text(masukTime?.format(context) ?? 'Belum diset'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setState(() => masukTime = picked);
                      },
                    ),
                    ListTile(
                      title: const Text('Waktu Pulang'),
                      subtitle: Text(pulangTime?.format(context) ?? 'Belum diset'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setState(() => pulangTime = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    if (masukTime == null || pulangTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi waktu.')));
                      return;
                    }

                    DateTime masukDt = DateTime(tgl.year, tgl.month, tgl.day, masukTime!.hour, masukTime!.minute);
                    DateTime pulangDt = DateTime(tgl.year, tgl.month, tgl.day, pulangTime!.hour, pulangTime!.minute);
                    
                    double totalHours = pulangDt.difference(masukDt).inMinutes / 60.0;
                    double jamNormal = totalHours > 8 ? 8 : totalHours;
                    double jamLembur = totalHours > 8 ? totalHours - 8 : 0;

                    final record = AttendanceModel(
                      idAbsen: '',
                      uid: _selectedUser!.uid,
                      tanggal: DateFormat('yyyy-MM-dd').format(tgl),
                      waktuMasuk: masukDt,
                      waktuPulang: pulangDt,
                      shiftAktual: 'Manual HR',
                      totalJamNormal: jamNormal,
                      totalJamLembur: jamLembur,
                      status: 'Selesai',
                    );

                    hrProvider.manualAddAttendance(record);
                    Navigator.pop(context);
                    _fetchData(); // Refresh list
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Absensi berhasil disimpan.')));
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
