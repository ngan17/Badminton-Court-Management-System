import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ipconfigsetting.dart';

class Hoadonservice {
  static Future<List> fetchHoaDon() async {
    final url = Uri.parse('${Ipconfigsetting.ip}/api/HoaDons'); // Kiểm tra URL
    final response = await http.get(url);
    print(response.body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception('Lỗi tải danh sách hóa đơn: ${response.body}');
    }
  }
}
