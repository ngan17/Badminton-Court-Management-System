import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:do_an_quan_ly_cau_long/DAO/ipconfigsetting.dart';

class PaymentInfoScreen extends StatefulWidget {
  final int maKhachHang;
  final int maSan;
  final String ngayDat;
  final String gioBatDau;
  final int? thoiLuong;
  final int? maDatSan;
  final double tongtien;

  const PaymentInfoScreen({
    super.key,
    required this.maKhachHang,
    required this.maSan,
    required this.maDatSan,
    required this.ngayDat,
    required this.gioBatDau,
    required this.thoiLuong,
    required this.tongtien,
  });

  @override
  State<PaymentInfoScreen> createState() => _PaymentInfoScreenState();
}

class _PaymentInfoScreenState extends State<PaymentInfoScreen> {
  String? _phuongThucThanhToan;
  String _trangThai = "Chờ xác nhận";
  String _tenKhachHang = "Đang tải...";
  String _soDienThoai = "Đang tải...";

  @override
  void initState() {
    super.initState();
    _fetchKhachHangInfo();
    _validateBookingTime(); // Kiểm tra thời gian đặt sân
  }

  Future<void> _fetchKhachHangInfo() async {
    try {
      final url = Uri.parse(
        '${Ipconfigsetting.ip}/api/KhachHangs/${widget.maKhachHang}',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tenKhachHang = data['tenKhachHang'] ?? "Không rõ";
          _soDienThoai = data['soDienThoai'] ?? "Không rõ";
        });
      } else {
        setState(() {
          _tenKhachHang = "Không tìm thấy tên";
          _soDienThoai = "Không tìm thấy SĐT";
        });
      }
    } catch (e) {
      setState(() {
        _tenKhachHang = "Lỗi tải tên";
        _soDienThoai = "Lỗi tải SĐT";
      });
      print('❗ Lỗi fetchKhachHangInfo: $e');
    }
  }

  void _validateBookingTime() {
    final dateTimeStr = '${widget.ngayDat} ${widget.gioBatDau}';
    final bookingTime = DateFormat('yyyy-MM-dd HH:mm').parse(dateTimeStr);
    final now = DateTime.now(); // 11:23 AM +07, 14/06/2025

    if (bookingTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Thời gian đặt sân không thể trước thời điểm hiện tại!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      // Có thể tự động quay lại nếu cần
      // Navigator.pop(context);
    }
  }

  Future<void> createHoaDon() async {
    // Kiểm tra thời gian một lần nữa trước khi gửi
    final dateTimeStr = '${widget.ngayDat} ${widget.gioBatDau}';
    final bookingTime = DateFormat('yyyy-MM-dd HH:mm').parse(dateTimeStr);
    final now = DateTime.now();
    if (bookingTime.isBefore(now)) {
      throw Exception("Thời gian đặt sân không hợp lệ!");
    }

    final bookingData = {
      "maKhachHang": widget.maKhachHang,
      "maSan": widget.maSan,
      "ngayDat": widget.ngayDat,
      "gioBatDau": widget.gioBatDau,
      "thoiLuong": widget.thoiLuong,
      "trangThai": _trangThai,
    };

    final url = Uri.parse('${Ipconfigsetting.ip}/api/DatSans');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bookingData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      final maDatSan = jsonResponse['maDatSan'] as int?;

      if (maDatSan == null) {
        throw Exception('Không nhận được mã đặt sân từ server');
      }

      final hoaDonData = {
        "maKhachHang": widget.maKhachHang,
        "maDatSan": maDatSan,
        "thoiGianThanhToan": DateTime.now().toIso8601String(),
        "soTien": widget.tongtien,
        "trangThai": _trangThai,
        "phuongThucThanhToan": _phuongThucThanhToan ?? 'Không xác định',
      };

      final hoaDonUrl = Uri.parse('${Ipconfigsetting.ip}/api/HoaDons');
      final hoaDonResponse = await http.post(
        hoaDonUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(hoaDonData),
      );

      if (hoaDonResponse.statusCode != 201) {
        throw Exception(
          'Lỗi tạo hóa đơn: ${hoaDonResponse.statusCode} - ${hoaDonResponse.body}',
        );
      }
    } else {
      throw Exception('Lỗi đặt sân: ${response.statusCode} - ${response.body}');
    }
  }

  Widget buildGradientHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF64B5F6),
          ], // Gradient xanh đậm đến xanh nhạt
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildGradientHeader(title),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  children
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: e,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Hiển thị thông báo khi nhấn Back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quá trình đặt sân đã bị hủy!'),
            backgroundColor: Colors.orange,
          ),
        );
        return true; // Cho phép quay lại
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thông tin thanh toán'),
          backgroundColor: const Color(0xFF1976D2), // Thay màu xanh đậm
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              buildSectionCard(
                title: 'Thông tin đặt sân',
                children: [
                  Text('Mã đặt sân: ${widget.maDatSan ?? "Chưa có"}'),
                  Text('Sân: Sân ${widget.maSan}'),
                  Text('Ngày: ${widget.ngayDat}'),
                  Text('Giờ bắt đầu: ${widget.gioBatDau}'),
                  Text('Thời lượng: ${widget.thoiLuong} giờ'),
                ],
              ),
              buildSectionCard(
                title: 'Thông tin khách hàng',
                children: [
                  Text('Mã khách hàng: ${widget.maKhachHang}'),
                  Text('Tên khách hàng: $_tenKhachHang'),
                  Text('Số điện thoại: $_soDienThoai'),
                ],
              ),
              buildSectionCard(
                title: 'Thông tin thanh toán',
                children: [
                  DropdownButtonFormField<String>(
                    value: _phuongThucThanhToan,
                    hint: const Text('Chọn phương thức thanh toán'),
                    items:
                        ['Thẻ tín dụng', 'Chuyển khoản', 'Tiền mặt']
                            .map(
                              (method) => DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _phuongThucThanhToan = value;
                        _trangThai =
                            value == 'Tiền mặt'
                                ? 'Đã thanh toán'
                                : 'Chờ xác nhận';
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  Text('Trạng thái: $_trangThai'),
                  Text('Tổng tiền: ${widget.tongtien.toStringAsFixed(0)} VNĐ'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _phuongThucThanhToan == null
                          ? null
                          : () async {
                            try {
                              await createHoaDon();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✅ Đặt sân và thanh toán thành công!',
                                  ),
                                  backgroundColor: Color(0xFF1976D2),
                                ),
                              );
                              Navigator.pop(context); // Quay lại màn hình trước
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Lỗi: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF1976D2,
                    ), // Thay màu xanh đậm
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận thanh toán',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
