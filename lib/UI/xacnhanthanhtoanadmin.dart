import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../DAO/ipconfigsetting.dart';

class ConfirmHoaDonScreen extends StatefulWidget {
  const ConfirmHoaDonScreen({super.key});

  @override
  State<ConfirmHoaDonScreen> createState() => _ConfirmHoaDonScreenState();
}

class _ConfirmHoaDonScreenState extends State<ConfirmHoaDonScreen> {
  List hoaDons = [];
  Map<int, int> datSanToKhach = {}; // maDatSan -> maKhachHang
  Map<int, String> khachHangNames = {}; // maKhachHang -> tenKhachHang
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([fetchHoaDons(), fetchDatSans(), fetchKhachHangs()]);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchHoaDons() async {
    final response = await http.get(
      Uri.parse('${Ipconfigsetting.ip}/api/HoaDons'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      hoaDons = data.where((hd) => hd['trangThai'] == 'Chờ xác nhận').toList();
    }
  }

  Future<void> fetchDatSans() async {
    final response = await http.get(
      Uri.parse('${Ipconfigsetting.ip}/api/DatSans'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      for (var ds in data) {
        datSanToKhach[ds['maDatSan']] = ds['maKhachHang'];
      }
    }
  }

  Future<void> fetchKhachHangs() async {
    final response = await http.get(
      Uri.parse('${Ipconfigsetting.ip}/api/KhachHangs'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      for (var kh in data) {
        khachHangNames[kh['maKhachHang']] = kh['tenKhachHang'];
      }
    }
  }

  Future<void> confirmHoaDon(int id) async {
    final getResponse = await http.get(
      Uri.parse('${Ipconfigsetting.ip}/api/HoaDons/$id'),
    );

    if (getResponse.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không lấy được dữ liệu hóa đơn'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final hoaDon = jsonDecode(getResponse.body);
    hoaDon['trangThai'] = 'Đã thanh toán';

    final putResponse = await http.put(
      Uri.parse('${Ipconfigsetting.ip}/api/HoaDons/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(hoaDon),
    );

    if (putResponse.statusCode == 200 || putResponse.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Xác nhận hóa đơn thành công!'),
          backgroundColor: const Color(
            0xFF1976D2,
          ), // Thay xanh lá bằng xanh dương
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      await fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xác nhận: ${putResponse.statusCode}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String getTenKhachHang(int? maDatSan) {
    final maKhachHang = datSanToKhach[maDatSan ?? -1];
    return khachHangNames[maKhachHang] ?? 'KH #$maKhachHang';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xác nhận hóa đơn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(
          0xFF1976D2,
        ), // Thay xanh lá bằng xanh dương
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() => fetchData()),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF64B5F6).withOpacity(0.9),
              Colors.white,
            ], // Thay xanh lá nhạt bằng xanh dương nhạt
          ),
        ),
        child:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: const Color(
                      0xFF1976D2,
                    ), // Thay xanh lá bằng xanh dương
                    strokeWidth: 3,
                  ),
                )
                : hoaDons.isEmpty
                ? Center(
                  child: Text(
                    'Không có hóa đơn chờ xác nhận',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: hoaDons.length,
                  itemBuilder: (context, index) {
                    final hd = hoaDons[index];
                    final tenKH = getTenKhachHang(hd['maDatSan']);

                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              const Color(0xFF64B5F6).withOpacity(
                                0.3,
                              ), // Thay xanh lá nhạt bằng xanh dương nhạt
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFFBBDEFB,
                            ), // Thay xanh lá nhạt bằng xanh dương rất nhạt
                            child: Icon(
                              Icons.receipt,
                              color: const Color(
                                0xFF1976D2,
                              ), // Thay xanh lá bằng xanh dương
                              size: 28,
                            ),
                          ),
                          title: Text(
                            'HĐ #${hd['maHoaDon']} - $tenKH',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(
                                0xFF1565C0,
                              ), // Xanh dương đậm hơn cho tiêu đề
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Ngày thanh toán: ${hd['thoiGianThanhToan'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                'Số tiền: ${hd['soTien'] ?? 0} VNĐ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                'Phương thức: ${hd['phuongThucThanhToan'] ?? '---'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => confirmHoaDon(hd['maHoaDon']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF1976D2,
                              ), // Thay xanh lá bằng xanh dương
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              elevation: 6,
                              shadowColor: const Color(
                                0xFF1565C0,
                              ).withOpacity(0.3), // Shadow xanh dương đậm
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
