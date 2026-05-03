import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../providers/hr_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/attendance_model.dart';
import '../../../models/leave_model.dart';
import '../../../models/user_model.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();
  
  bool _isLoading = true;
  List<AttendanceModel> _attendanceData = [];
  List<UserModel> _users = [];
  
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
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    try {
      _attendanceData = await hrProvider.getAttendanceByDateRange(_startDate, _endDate);
      // Get all users for mapping locations
      _users = await adminProvider.getUsersStream().first;
    } catch (e) {
      debugPrint('Analytics fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper to get location color
  Color _getLocationColor(String location) {
    if (location.toLowerCase().contains('pramuka')) return const Color(0xFFE91E63);
    if (location.toLowerCase().contains('bogor')) return const Color(0xFFFF9800);
    if (location.toLowerCase().contains('toko')) return const Color(0xFF2196F3);
    return Colors.green; // Default
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
            const Text('Grafik Jam Kerja Harian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildLegend(),
            const SizedBox(height: 10),
            _buildWorkingHoursChart(),
            const SizedBox(height: 30),
            const Text('Estimasi Payroll Periode Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildEstimatedPayrollCard(),
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
    final activeWorkersByLocation = <String, int>{};
    int totalActive = 0;

    final uniqueUids = _attendanceData.map((e) => e.uid).toSet();
    for (var uid in uniqueUids) {
      String loc = 'Lainnya';
      try {
        loc = _users.firstWhere((u) => u.uid == uid).lokasiKerja;
      } catch (_) {}
      
      activeWorkersByLocation[loc] = (activeWorkersByLocation[loc] ?? 0) + 1;
      totalActive++;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                color: const Color(0xFF1A237E),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Icon(Icons.people, color: Colors.white, size: 30),
                      const SizedBox(height: 5),
                      const Text('Total Pekerja', style: TextStyle(color: Colors.white70)),
                      Text('$totalActive Orang', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                color: Colors.orange,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy, color: Colors.white, size: 30),
                      const SizedBox(height: 5),
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
                          return Text('$approvedLeavesToday Orang', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Breakdown Location Cards
        Row(
          children: activeWorkersByLocation.keys.map((loc) {
            return Expanded(
              child: Card(
                color: _getLocationColor(loc).withOpacity(0.8),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(loc, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text('${activeWorkersByLocation[loc]} org', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Pramuka', _getLocationColor('pramuka')),
        const SizedBox(width: 10),
        _legendItem('Bogor', _getLocationColor('bogor')),
        const SizedBox(width: 10),
        _legendItem('Toko', _getLocationColor('toko')),
      ],
    );
  }

  Widget _legendItem(String name, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(name, style: const TextStyle(fontSize: 12)),
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

    // Aggregate by date and then by location
    // Map<Date, Map<Location, Hours>>
    Map<String, Map<String, double>> aggregatedData = {};
    
    for (var record in _attendanceData) {
      String loc = 'Lainnya';
      try { loc = _users.firstWhere((u) => u.uid == record.uid).lokasiKerja; } catch (_) {}
      
      aggregatedData[record.tanggal] ??= {};
      aggregatedData[record.tanggal]![loc] = (aggregatedData[record.tanggal]![loc] ?? 0) + record.totalJamNormal + record.totalJamLembur;
    }

    final sortedKeys = aggregatedData.keys.toList()..sort();
    
    List<BarChartGroupData> barGroups = [];
    int i = 0;
    double maxY = 0;

    for (var date in sortedKeys) {
      final dailyData = aggregatedData[date]!;
      List<BarChartRodStackItem> stackItems = [];
      
      double currentY = 0;
      // We explicitly order Pramuka, Bogor, Toko if they exist
      final locations = ['Pramuka', 'Bogor', 'Toko', 'Lainnya'];
      
      for (var loc in locations) {
        if (dailyData.containsKey(loc)) {
          final val = dailyData[loc]!;
          stackItems.add(BarChartRodStackItem(currentY, currentY + val, _getLocationColor(loc)));
          currentY += val;
        }
      }

      // Fallback for any other locations
      for (var loc in dailyData.keys) {
        if (!locations.contains(loc)) {
          final val = dailyData[loc]!;
          stackItems.add(BarChartRodStackItem(currentY, currentY + val, _getLocationColor(loc)));
          currentY += val;
        }
      }

      if (currentY > maxY) maxY = currentY;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: currentY,
              width: 20,
              borderRadius: BorderRadius.circular(2),
              rodStackItems: stackItems,
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
          maxY: (maxY + 10).ceilToDouble(),
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

  Widget _buildEstimatedPayrollCard() {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    double totalAll = 0;
    Map<String, double> totalByLocation = {};

    for (var u in _users) {
      final userRecords = _attendanceData.where((r) => r.uid == u.uid);
      
      double userTotalJamNormal = 0;
      double userTotalJamLembur = 0;
      
      for (var r in userRecords) {
        userTotalJamNormal += r.totalJamNormal;
        userTotalJamLembur += r.totalJamLembur;
      }

      double normalDays = userTotalJamNormal / 8;
      double normalPay = normalDays * u.honorNormal;
      double lemburPay = userTotalJamLembur * (u.honorNormal / 8);

      double userTotalPay = normalPay + lemburPay;
      
      totalAll += userTotalPay;
      totalByLocation[u.lokasiKerja] = (totalByLocation[u.lokasiKerja] ?? 0) + userTotalPay;
    }

    return Card(
      color: const Color(0xFF1A237E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Proyeksi:', style: TextStyle(color: Colors.white70)),
            Text(formatCurrency.format(totalAll), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white30, height: 30),
            const Text('Rincian per Lokasi:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...totalByLocation.keys.map((loc) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 10, height: 10, color: _getLocationColor(loc)),
                        const SizedBox(width: 8),
                        Text(loc, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    Text(formatCurrency.format(totalByLocation[loc]), style: const TextStyle(color: Colors.white)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
