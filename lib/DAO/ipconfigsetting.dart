import 'package:network_info_plus/network_info_plus.dart';

class Ipconfigsetting {
  static String ip = "";

  static Future<void> init() async {
    final info = NetworkInfo();
    String? wifiIP = await info.getWifiIP();

    if (wifiIP != null) {
      ip = "http://172.16.95.159:3000";
      print(" IP nội bộ đã cấu hình: $ip");
    } else {
      print("Không lấy được IP.");
    }
  }
}
