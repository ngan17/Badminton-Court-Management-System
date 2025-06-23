import 'dart:convert';
import 'package:do_an_quan_ly_cau_long/DAO/hoadonservice.dart';
import 'package:do_an_quan_ly_cau_long/DAO/ipconfigsetting.dart';
import 'package:http/http.dart' as http;
import 'hoadonservice.dart';

class BookingService {
  static Future<List> fetchBookings() async {
    final url = Uri.parse('${Ipconfigsetting.ip}/api/DatSans');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List; // Ép kiểu rõ ràng
    } else {
      print('Lỗi tải danh sách booking: ${response.body}'); // Debug lỗi
      throw Exception(
        'Lỗi tải danh sách booking (Status: ${response.statusCode})',
      );
    }
  }

  static Future<List> fetchBookingsByCustomer(int? maKhachHang) async {
    if (maKhachHang == null) return [];
    final allBookings = await fetchBookings();
    return allBookings.where((b) => b['maKhachHang'] == maKhachHang).toList();
  }

  static Future<void> cancelBooking(int maDatSan) async {
    // 1. Xóa đặt sân
    final bookingUrl = Uri.parse('${Ipconfigsetting.ip}/api/DatSans/$maDatSan');
    final bookingResponse = await http.delete(bookingUrl);

    if (bookingResponse.statusCode != 200 &&
        bookingResponse.statusCode != 204) {
      throw Exception(
        'Không thể hủy đặt sân (Status: ${bookingResponse.statusCode})',
      );
    }

    // 2. Tìm và xóa hóa đơn tương ứng
    final hoaDonList = await Hoadonservice.fetchHoaDon();
    final hoaDon = hoaDonList.firstWhere(
      (hd) => hd['maDatSan'] == maDatSan,
      orElse: () => null,
    );

    if (hoaDon != null) {
      final maHoaDon = hoaDon['maHoaDon'];
      final hoaDonUrl = Uri.parse('${Ipconfigsetting.ip}/api/HoaDon/$maHoaDon');
      final hoaDonResponse = await http.delete(hoaDonUrl);
      print(hoaDonResponse.statusCode);
      if (hoaDonResponse.statusCode != 200 &&
          hoaDonResponse.statusCode != 204) {
        print('Không thể xóa hóa đơn (Status: ${hoaDonResponse.statusCode})');
      }
    }
  }

  static Future<void> insertBooking({
    required int maKhachHang, // Mã khách hàng do admin chọn
    required DateTime thoiGianBatDau,
    required DateTime thoiGianKetThuc,
    required String sanThiDau,
    String? ghiChu,
  }) async {
    final url = Uri.parse('${Ipconfigsetting.ip}/api/DatSans');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'maKhachHang': maKhachHang,
        'thoiGianBatDau': thoiGianBatDau.toIso8601String(),
        'thoiGianKetThuc': thoiGianKetThuc.toIso8601String(),
        'sanThiDau': sanThiDau,
        'ghiChu': ghiChu,
      }),
    );

    if (response.statusCode == 201) {
      return;
    } else {
      throw Exception('Lỗi khi đặt sân: ${response.body}');
    }
  }
}
