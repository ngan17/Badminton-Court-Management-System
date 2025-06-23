import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../DAO/bookingservice.dart';
import '../DAO/hoadonservice.dart';

class StatsScreen extends StatefulWidget {
  final String? vaiTro;
  final int? maKhachHang;

  const StatsScreen({super.key, this.vaiTro, this.maKhachHang});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List bookings = [];
  List invoices = [];
  bool isLoading = true;

  FilterOption selectedFilter = FilterOption.all;
  ChartType selectedChartType = ChartType.byDay;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final fetchedBookings = await BookingService.fetchBookings();
      final fetchedInvoices = await Hoadonservice.fetchHoaDon();
      setState(() {
        bookings = fetchedBookings;
        invoices = fetchedInvoices;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Lỗi khi tải dữ liệu: $e');
    }
  }

  double getEstimatedRevenue() {
    double total = 0.0;
    for (var invoice in invoices) {
      final amount = invoice['soTien'] as double? ?? 0.0;
      print('Invoice soTien: $amount'); // Debug
      total += amount;
    }
    print('Estimated Revenue: $total'); // Debug tổng
    return total;
  }

  Map<String, int> getChartDataByType() {
    final Map<String, int> stats = {};
    for (var booking in bookings) {
      final dateStr = booking['ngayDat'] ?? '';
      final timeStr = booking['gioBatDau'] ?? '';
      if (dateStr.isEmpty) continue;

      final date = DateTime.parse(dateStr);
      final hour = timeStr.split(":").first;

      String key;
      switch (selectedChartType) {
        case ChartType.byDay:
          key = DateFormat('yyyy-MM-dd').format(date);
          break;
        case ChartType.byHour:
          key = '$hour:00';
          break;
        case ChartType.byWeek:
          key = 'W${(date.day ~/ 7) + 1}/${date.month}';
          break;
        case ChartType.byMonth:
          key = DateFormat('yyyy-MM').format(date);
          break;
      }

      stats[key] = (stats[key] ?? 0) + 1;
    }
    print('Chart stats: $stats'); // Debug
    return stats;
  }

  Map<String, double> getRevenueByType() {
    final Map<String, double> revenueStats = {};
    for (var invoice in invoices) {
      final maDatSan = invoice['maDatSan'] as int?;
      if (maDatSan == null) continue;

      // Tìm booking tương ứng để lấy ngày và giờ
      final relatedBooking = bookings.firstWhere(
        (b) => b['maDatSan'] == maDatSan,
        orElse: () => null,
      );
      if (relatedBooking == null) continue;

      final dateStr = relatedBooking['ngayDat'] ?? '';
      final timeStr = relatedBooking['gioBatDau'] ?? '';
      if (dateStr.isEmpty) continue;

      final date = DateTime.parse(dateStr);
      final hour = timeStr.split(":").first;
      final revenue = invoice['soTien'] as double? ?? 0.0;

      String key;
      switch (selectedChartType) {
        case ChartType.byDay:
          key = DateFormat('yyyy-MM-dd').format(date);
          break;
        case ChartType.byHour:
          key = '$hour:00';
          break;
        case ChartType.byWeek:
          key = 'W${(date.day ~/ 7) + 1}/${date.month}';
          break;
        case ChartType.byMonth:
          key = DateFormat('yyyy-MM').format(date);
          break;
      }

      revenueStats[key] = (revenueStats[key] ?? 0.0) + revenue;
    }
    print('Revenue stats: $revenueStats'); // Debug
    return revenueStats;
  }

  Map<int, int> getBookingCountByCourt() {
    final Map<int, int> stats = {};
    for (var booking in bookings) {
      final courtId = booking['maSan'] as int? ?? 0;
      if (courtId > 0) {
        stats[courtId] = (stats[courtId] ?? 0) + 1;
      }
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final chartStats = getChartDataByType();
    final revenueStats = getRevenueByType();
    final statsByCourt = getBookingCountByCourt();
    final totalBookings = bookings.length;
    final estimatedRevenue = getEstimatedRevenue();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thống kê lịch đặt sân',
          style: TextStyle(color: Color.fromARGB(255, 235, 240, 245)),
        ),
        backgroundColor: Color(0xFF1976D2),
        actions: [
          PopupMenuButton<FilterOption>(
            onSelected: (value) {
              setState(() => selectedFilter = value);
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(
                    value: FilterOption.today,
                    child: Text('Hôm nay'),
                  ),
                  PopupMenuItem(
                    value: FilterOption.thisWeek,
                    child: Text('Tuần này'),
                  ),
                  PopupMenuItem(value: FilterOption.all, child: Text('Tất cả')),
                ],
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard('Tổng số đặt sân', '$totalBookings'),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'Doanh thu ước tính (${_getLabelForChartType()})',
                        '${_formatCurrency(double.parse(_getTotalRevenueByChartType(revenueStats)))} VNĐ',
                      ),

                      const SizedBox(height: 12),
                      DropdownButton<ChartType>(
                        value: selectedChartType,
                        onChanged:
                            (value) =>
                                setState(() => selectedChartType = value!),
                        items: const [
                          DropdownMenuItem(
                            value: ChartType.byDay,
                            child: Text("Theo ngày"),
                          ),
                          DropdownMenuItem(
                            value: ChartType.byHour,
                            child: Text("Theo giờ"),
                          ),
                          DropdownMenuItem(
                            value: ChartType.byWeek,
                            child: Text("Theo tuần"),
                          ),
                          DropdownMenuItem(
                            value: ChartType.byMonth,
                            child: Text("Theo tháng"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Số lượt đặt sân:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: screenHeight * 0.25,
                        child: _buildBarChart(chartStats, Colors.blue),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Doanh thu theo thời gian:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: screenHeight * 0.25,
                        child: _buildBarChartDouble(
                          revenueStats,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Thống kê theo sân:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: screenHeight * 0.25,
                        child: _buildBarChartCourt(statsByCourt),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> stats, Color color) {
    final labels = stats.keys.toList();
    final data = stats.values.toList();
    final maxVal = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          itemBuilder: (context, index) {
            final barHeight = (data[index] / maxVal) * (chartHeight - 30);
            return Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: barHeight,
                    width: 40,
                    color: color,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBarChartDouble(Map<String, double> stats, Color color) {
    final labels = stats.keys.toList();
    final data = stats.values.toList();
    final maxVal = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          itemBuilder: (context, index) {
            final barHeight =
                data[index] /
                maxVal *
                (chartHeight - 50); // Giảm để chừa chỗ cho Text

            return Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height:
                        barHeight.isNaN || barHeight.isInfinite ? 0 : barHeight,
                    width: 40,
                    color: color,
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${data[index].toStringAsFixed(0)} VNĐ',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBarChartCourt(Map<int, int> stats) {
    final labels = stats.keys.toList();
    final data = stats.values.toList();
    final maxVal = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          itemBuilder: (context, index) {
            final barHeight = (data[index] / maxVal) * (chartHeight - 30);
            return Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: barHeight,
                    width: 40,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sân ${labels[index]}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getLabelForChartType() {
    switch (selectedChartType) {
      case ChartType.byDay:
        return 'theo ngày';
      case ChartType.byHour:
        return 'theo giờ';
      case ChartType.byWeek:
        return 'theo tuần';
      case ChartType.byMonth:
        return 'theo tháng';
      default:
        return '';
    }
  }

  String _getTotalRevenueByChartType(Map<String, double> revenueStats) {
    double total = revenueStats.values.fold(0.0, (sum, value) => sum + value);
    return total.toStringAsFixed(0);
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.decimalPattern('vi_VN');
    return formatter.format(value);
  }
}

enum FilterOption { today, thisWeek, all }

enum ChartType { byDay, byHour, byWeek, byMonth }
