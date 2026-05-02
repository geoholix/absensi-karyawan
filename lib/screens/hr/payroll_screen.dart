import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/payroll_model.dart';
import '../../providers/hr_provider.dart';
import '../../providers/admin_provider.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final hrProvider = Provider.of<HrProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Payroll')),
      body: Column(
        children: [
          // Period Selector
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[200],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pilih Periode Mingguan:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text('${DateFormat('d MMM').format(_startDate)} - ${DateFormat('d MMM yyyy').format(_endDate)}'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                          });
                        }
                      },
                      child: const Text('Ubah Periode'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hrProvider.isLoading
                        ? null
                        : () async {
                            // Get all users first
                            // For simplicity, we assume they are already fetched or we fetch them here
                            // In real app, we might want a stream or fetch them once
                            // We use adminProvider's stream or a method.
                            // Let's assume we can get them from a Future.
                            // Here we use a shortcut for demonstration.
                            final users = await adminProvider.getUsersStream().first;
                            await hrProvider.generatePayroll(
                              start: _startDate,
                              end: _endDate,
                              allUsers: users,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Payroll berhasil di-generate!')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                    child: hrProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('GENERATE PAYROLL UNTUK SEMUA'),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Daftar Payroll Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          Expanded(
            child: StreamBuilder<List<PayrollModel>>(
              // For HR, we might want to see all payrolls
              stream: hrProvider.getAllPayrollsStream(), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Belum ada data payroll.'));
                }

                final payrolls = snapshot.data!;

                return ListView.builder(
                  itemCount: payrolls.length,
                  itemBuilder: (context, index) {
                    final payroll = payrolls[index];
                    return ListTile(
                      title: Text('UID: ${payroll.uid.substring(0, 8)}...'),
                      subtitle: Text('${DateFormat('d MMM').format(payroll.periodeAwal)} - ${DateFormat('d MMM').format(payroll.periodeAkhir)}'),
                      trailing: Text(currencyFormat.format(payroll.totalPenerimaan), style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => _showAdjustmentDialog(context, payroll),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog(BuildContext context, PayrollModel payroll) {
    final adjustmentController = TextEditingController(text: payroll.adjustment.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Input Adjustment Gaji'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Karyawan: ${payroll.uid}'),
              const SizedBox(height: 10),
              TextField(
                controller: adjustmentController,
                decoration: const InputDecoration(labelText: 'Adjustment (Rp)', hintText: 'Misal: -50000 atau 50000'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Provider.of<HrProvider>(context, listen: false)
                    .updatePayrollAdjustment(payroll.idPayroll!, double.tryParse(adjustmentController.text) ?? 0.0);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
