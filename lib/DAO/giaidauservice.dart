import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ipconfigsetting.dart';

class GiaiDauService {
  static Future<List> fetchGiaiDau() async {
    final url = Uri.parse('${Ipconfigsetting.ip}/api/GiaiDaus'); // Kiểm tra URL
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception('Lỗi tải danh sách giải đấu: ${response.body}');
    }
  }

  static Future<void> insertGiaiDau({
    required String tenGiai,
    required DateTime ngayBatDau,
    required DateTime ngayKetThuc,
    required String diaDiem,
    String? moTa,
    double? giaiThuong,
    String? trangThai,
  }) async {
    final url = Uri.parse('${Ipconfigsetting.ip}/api/GiaiDaus');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenGiai': tenGiai,
        'ngayBatDau': ngayBatDau.toIso8601String().split('T').first,
        'ngayKetThuc': ngayKetThuc.toIso8601String().split('T').first,
        'diaDiem': diaDiem,
        'moTa': moTa,
        'giaiThuong': giaiThuong,
        'trangThai': trangThai ?? 'Sắp diễn ra',
      }),
    );

    if (response.statusCode == 201) {
      return;
    } else {
      throw Exception('Lỗi khi thêm giải đấu: ${response.body}');
    }
  }
}
