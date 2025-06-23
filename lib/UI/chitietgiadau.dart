import 'package:flutter/material.dart';
import 'package:do_an_quan_ly_cau_long/DAO/chitietgiaidauservice.dart';
import 'package:intl/intl.dart';

class GiaiDauDetailScreen extends StatelessWidget {
  final Map<String, dynamic> giaiDau;

  const GiaiDauDetailScreen({super.key, required this.giaiDau});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          giaiDau['tenGiai'],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2), // Xanh dương đậm
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF64B5F6), Colors.white], // Xanh nhạt đến trắng
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiết giải đấu',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0), // Nổi bật
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.sports_tennis,
                    color: const Color(0xFF1976D2), // Xanh dương đậm
                    size: 30,
                  ),
                  title: const Text(
                    'Tên giải:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ), // Nổi bật
                  ),
                  subtitle: Text(
                    giaiDau['tenGiai'] ?? 'Chưa có thông tin',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 3, 3, 2),
                    ), // Vàng nhạt
                  ),
                ),
                Divider(color: Color.fromARGB(255, 28, 26, 23)),
                ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: const Color(0xFF1976D2), // Xanh dương đậm
                    size: 30,
                  ),
                  title: const Text(
                    'Ngày bắt đầu:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 28, 26, 23),
                    ), // Nổi bật
                  ),
                  subtitle: Text(
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(DateTime.parse(giaiDau['ngayBatDau'])),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 7, 6, 5),
                    ), // Vàng nhạt
                  ),
                ),
                Divider(color: Color.fromARGB(255, 28, 26, 23)),
                ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: const Color(0xFF1976D2), // Xanh dương đậm
                    size: 30,
                  ),
                  title: const Text(
                    'Ngày kết thúc:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 28, 26, 23),
                    ), // Nổi bật
                  ),
                  subtitle: Text(
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(DateTime.parse(giaiDau['ngayKetThuc'])),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ), // Vàng nhạt
                  ),
                ),
                Divider(color: Color.fromARGB(255, 28, 26, 23)),
                ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: const Color(0xFF1976D2), // Xanh dương đậm
                    size: 30,
                  ),
                  title: const Text(
                    'Địa điểm:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 28, 26, 23),
                    ), // Nổi bật
                  ),
                  subtitle: Text(
                    giaiDau['diaDiem'] ?? 'Chưa có thông tin',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ), // Vàng nhạt
                  ),
                ),
                Divider(color: Color.fromARGB(255, 28, 26, 23)),
                ListTile(
                  leading: Icon(
                    Icons.description,
                    color: const Color(0xFF1976D2), // Xanh dương đậm
                    size: 30,
                  ),
                  title: const Text(
                    'Mô tả:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 28, 26, 23),
                    ), // Nổi bật
                  ),
                  subtitle: Text(
                    giaiDau['moTa'] ?? 'Chưa có thông tin',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 28, 26, 23),
                    ), // Vàng nhạt
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
