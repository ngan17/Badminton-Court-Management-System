import 'package:flutter/material.dart';

class ChiTietGiaiDauScreen extends StatelessWidget {
  final Map giaiDau;

  const ChiTietGiaiDauScreen({Key? key, required this.giaiDau})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List chiTietList = giaiDau['chiTietGiaiDaus'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết giải đấu'),
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://azb.vn/media/2022/images/2022/poster%20c%E1%BA%A7u%20l%C3%B4ng-01-01.jpg',
            ),
            fit: BoxFit.fitWidth,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                giaiDau['tenGiai'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Divider(thickness: 1.5),
              SizedBox(height: 12),
              Text(
                '🗓 Thời gian: ${giaiDau['ngayBatDau']} → ${giaiDau['ngayKetThuc']}',
              ),
              Text(
                '📍 Địa điểm: ${giaiDau['diaDiem'] ?? 'Không rõ'}',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '🎯 Trạng thái: ${giaiDau['trangThai'] ?? 'Chưa rõ'}',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '🏆 Giải thưởng: ${giaiDau['giaiThuong'] ?? 0} VNĐ',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                '📘 Mô tả:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                giaiDau['moTa'] ?? 'Không có mô tả.',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                '👥 Các đội tham gia:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 50),
              if (chiTietList.isEmpty)
                Text('Chưa có đội nào tham gia.')
              else
                Column(
                  children:
                      chiTietList.map((item) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text('${item['maDoi']}'),
                            ),
                            title: Text('Mã đội: ${item['maDoi']}'),
                            subtitle: Text(
                              'Vòng: ${item['vongDau']}\nKết quả: ${item['ketQua']}',
                            ),
                          ),
                        );
                      }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
