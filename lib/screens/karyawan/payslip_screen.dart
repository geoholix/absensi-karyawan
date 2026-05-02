import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/payroll_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';

class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthProvider>(context).userModel?.uid;
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Slip Gaji Mingguan')),
      body: StreamBuilder<List<PayrollModel>>(
        stream: attendanceProvider.getPayrollHistory(uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada slip gaji yang diterbitkan.'));
          }

          final payrolls = snapshot.data!;

          return ListView.builder(
            itemCount: payrolls.length,
            itemBuilder: (context, index) {
              final payroll = payrolls[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SLIP GAJI',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('PAID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      Text(
                        'Periode: ${DateFormat('d MMM').format(payroll.periodeAwal)} - ${DateFormat('d MMM yyyy').format(payroll.periodeAkhir)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      _buildRow('Gaji Pokok (${payroll.jumlahHariKerjaNormal} hari)', currencyFormat.format(payroll.gajiPokok)),
                      if (payroll.jumlahHariKerjaLibur > 0)
                        _buildRow('Gaji Hari Libur (${payroll.jumlahHariKerjaLibur} hari)', currencyFormat.format(payroll.gajiLibur)),
                      _buildRow('Lembur (${payroll.totalJamLembur.toStringAsFixed(1)} jam)', currencyFormat.format(payroll.gajiLembur)),
                      if (payroll.adjustment != 0)
                        _buildRow('Penyesuaian (HR)', currencyFormat.format(payroll.adjustment), isAdjustment: true),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL PENERIMAAN', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            currencyFormat.format(payroll.totalPenerimaan),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A237E)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isAdjustment = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(color: isAdjustment ? Colors.red : Colors.black)),
        ],
      ),
    );
  }
}
