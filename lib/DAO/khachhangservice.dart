import '../UI/khachhang.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ipconfigsetting.dart';

class Khachhangservice {
  static String get baseUrl => '${Ipconfigsetting.ip}/api/KhachHangs';

  static Future<List<KhachHang>> fetchKhachHangs(int maKhachHang) async {
    final url = Uri.parse('$baseUrl/$maKhachHang');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData is List) {
        return (jsonData)
            .map((e) => KhachHang.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (jsonData is Map) {
        return [KhachHang.fromJson(jsonData as Map<String, dynamic>)];
      } else {
        return [];
      }
    } else {
      throw Exception(
        'Lỗi tải danh sách khách hàng: ${response.statusCode} - ${response.body}',
      );
    }
  }

  static Future<List<KhachHang>> fetchKhachHangFull() async {
    final fullUrl = Uri.parse(baseUrl);
    final response = await http.get(fullUrl);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData is List) {
        return (jsonData)
            .map((e) => KhachHang.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (jsonData is Map) {
        return [KhachHang.fromJson(jsonData as Map<String, dynamic>)];
      } else {
        return [];
      }
    } else {
      throw Exception(
        'Lỗi tải danh sách khách hàng: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
