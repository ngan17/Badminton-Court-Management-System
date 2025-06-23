import 'dart:convert';
import 'package:do_an_quan_ly_cau_long/DAO/ipconfigsetting.dart';
import 'package:http/http.dart' as http;
import 'ipconfigsetting.dart';

class ChiTietGiaiDauService {
  static String get apiUrl =>
      'http://${Ipconfigsetting.ip}/api/ChiTietGiaiDaus';

  static Future<List> fetchChiTiet(int maGiaiDau) async {
    final response = await http.get(Uri.parse('$apiUrl?maGiaiDau=$maGiaiDau'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi tải chi tiết giải đấu');
    }
  }
}
