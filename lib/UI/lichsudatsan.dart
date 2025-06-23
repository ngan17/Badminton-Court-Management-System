import 'package:flutter/material.dart';
import '../DAO/bookingservice.dart';

class LichSuDatSanScreen extends StatefulWidget {
  final int maKhachHang;
  final String tenKhachHang;

  const LichSuDatSanScreen({
    super.key,
    required this.maKhachHang,
    required this.tenKhachHang,
  });

  @override
  State<LichSuDatSanScreen> createState() => _LichSuDatSanScreenState();
}

class _LichSuDatSanScreenState extends State<LichSuDatSanScreen> {
  List bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLichSu();
  }

  Future<void> fetchLichSu() async {
    setState(() => isLoading = true);
    final data = await BookingService.fetchBookingsByCustomer(
      widget.maKhachHang,
    );
    setState(() {
      bookings = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử đặt sân: ${widget.tenKhachHang}'),
        backgroundColor: Colors.green[700],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : bookings.isEmpty
              ? const Center(child: Text('Chưa có lịch sử đặt sân.'))
              : ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.sports_tennis,
                      color: Colors.green,
                    ),
                    title: Text('Ngày: ${booking['ngayDat'] ?? ''}'),
                    subtitle: Text(
                      'Giờ: ${booking['gioBatDau'] ?? ''} - Sân: ${booking['maSan'] ?? ''}',
                    ),
                    trailing: Text('${booking['thoiLuong']}h'),
                  );
                },
              ),
    );
  }
}
