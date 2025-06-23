import 'package:flutter/material.dart';

class KhachHang {
  final int maKhachHang;
  final String tenKhachHang;
  final String soDienThoai;
  final String email;
  final int maNguoiDung;

  KhachHang({
    required this.maKhachHang,
    required this.tenKhachHang,
    required this.soDienThoai,
    required this.email,
    required this.maNguoiDung,
  });

  factory KhachHang.fromJson(Map<String, dynamic> json) {
    return KhachHang(
      maKhachHang: json['maKhachHang'],
      tenKhachHang: json['tenKhachHang'],
      soDienThoai: json['soDienThoai'],
      email: json['email'],
      maNguoiDung: json['maNguoiDung'],
    );
  }
}

class KhachHangList extends StatefulWidget {
  const KhachHangList({super.key});

  @override
  _KhachHangListState createState() => _KhachHangListState();
}

class _KhachHangListState extends State<KhachHangList> {
  final List<KhachHang> _khachHangs = [
    KhachHang(
      maKhachHang: 1,
      tenKhachHang: "Nguyen Van A",
      soDienThoai: "0901234567",
      email: "nguyenvana@example.com",
      maNguoiDung: 101,
    ),
    KhachHang(
      maKhachHang: 2,
      tenKhachHang: "Tran Thi B",
      soDienThoai: "0912345678",
      email: "tranthib@example.com",
      maNguoiDung: 102,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Danh sách khách hàng'),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _khachHangs.length,
        itemBuilder: (context, index) {
          final khachHang = _khachHangs[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blueGrey[300]!),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB3E5FC), Color(0xFFBBDEFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFF42A5F5),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        khachHang.tenKhachHang,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mã KH: ${khachHang.maKhachHang}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  Text(
                    'SĐT: ${khachHang.soDienThoai}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  Text(
                    'Email: ${khachHang.email}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  Text(
                    'Mã ND: ${khachHang.maNguoiDung}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
