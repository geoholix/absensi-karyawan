import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../providers/hr_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/attendance_model.dart';
import '../../../models/leave_model.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6)); // Past 7 days including today
  DateTime _endDate = DateTime.now();
  
  bool _isLoading = true;
  List<AttendanceModel> _attendanceData = [];
  int _totalLeaves = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAnalyticsData();
    });
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);
    final hrProvider = Provider.of<HrProvider>(context, listen: false);
    
    try {
      _attendanceData = await hrProvider.getAttendanceByDateRange(_startDate, _endDate);
      // For leaves, we could do a real query, but for simplicity, we count from stream
      // We will handle leaves count below if needed
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildSummaryCards(context),
            const SizedBox(height: 30),
            const Text('Grafik Jam Kerja (Per Hari)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildWorkingHoursChart(),
            const SizedBox(height: 30),
            const Text('Estimasi Payroll Minggu Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildEstimatedPayrollCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
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
              if (picked != null) {
                setState(() => _startDate = picked);
                _fetchAnalyticsData();
              }
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(DateFormat('dd MMM yyyy').format(_startDate)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white),
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('s/d')),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: _startDate,
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _endDate = picked);
                _fetchAnalyticsData();
              }
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(DateFormat('dd MMM yyyy').format(_endDate)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    // Unique workers in the period
    final activeWorkers = _attendanceData.map((e) => e.uid).toSet().length;

    return Row(
      children: [
        Expanded(
          child: Card(
            color: const Color(0xFFE91E63),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 30),
                  const SizedBox(height: 10),
                  const Text('Pekerja Aktif', style: TextStyle(color: Colors.white70)),
                  Text('$activeWorkers Orang', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Card(
            color: Colors.orange,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.event_busy, color: Colors.white, size: 30),
                  const SizedBox(height: 10),
                  const Text('Sedang Cuti', style: TextStyle(color: Colors.white70)),
                  StreamBuilder<List<LeaveModel>>(
                    stream: Provider.of<HrProvider>(context).getLeavesStream(),
                    builder: (context, snapshot) {
                      int approvedLeavesToday = 0;
                      if (snapshot.hasData) {
                        final now = DateTime.now();
                        approvedLeavesToday = snapshot.data!.where((l) {
                          return l.status == 'Approved' &&
                                 now.isAfter(l.tanggalMulai.subtract(const Duration(days: 1))) &&
                                 now.isBefore(l.tanggalSelesai.add(const Duration(days: 1)));
                        }).length;
                      }
                      return Text('$approvedLeavesToday Orang', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHoursChart() {
    if (_attendanceData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Data tidak cukup untuk grafik')),
      );
    }

    // Aggregate by date
    Map<String, double> aggregatedData = {};
    for (var record in _attendanceData) {
      aggregatedData[record.tanggal] = (aggregatedData[record.tanggal] ?? 0) + record.totalJamNormal + record.totalJamLembur;
    }

    // Sort dates
    final sortedKeys = aggregatedData.keys.toList()..sort();
    
    List<BarChartGroupData> barGroups = [];
    int i = 0;
    for (var date in sortedKeys) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: aggregatedData[date]!,
              color: const Color(0xFFE91E63),
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        )
      );
      i++;
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (aggregatedData.values.reduce((a, b) => a > b ? a : b) + 10).ceilToDouble(),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                    DateTime dt = DateTime.parse(sortedKeys[value.toInt()]);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat('dd/MM').format(dt), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.white70));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildEstimatedPayrollCard(BuildContext context) {
    final users = Provider.of<AdminProvider>(context, listen: false).users;
    
    // Simple estimation: Sum of (Total Jam Normal / 8 * Honor Normal) + (Total Jam Lembur * (Honor Normal/8))
    // We do this per user based on _attendanceData which respects the selected date range.
    double estimatedTotal = 0;

    for (var u in users) {
      final userRecords = _attendanceData.where((r) => r.uid == u.uid);
      
      double userTotalJamNormal = 0;
      double userTotalJamLembur = 0;
      int liburDays = 0; // Simplified
      
      for (var r in userRecords) {
        userTotalJamNormal += r.totalJamNormal;
        userTotalJamLembur += r.totalJamLembur;
        // In real logic, determine if the record date is a holiday/weekend
      }

      // Convert hours to days roughly for normal honor, assume 8 hrs = 1 day
      double normalDays = userTotalJamNormal / 8;
      double normalPay = normalDays * u.honorNormal;
      double lemburPay = userTotalJamLembur * (u.honorNormal / 8);

      estimatedTotal += (normalPay + lemburPay);
    }

    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      color: const Color(0xFF1A237E), // Contrast color
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, size: 40, color: Colors.white),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Proyeksi Periode (${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)})', 
                  style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Text(formatCurrency.format(estimatedTotal), 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
