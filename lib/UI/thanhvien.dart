import 'package:do_an_quan_ly_cau_long/UI/lichsudatsan.dart';
import 'package:flutter/material.dart';
import '../DAO/khachhangservice.dart';
import 'bookingform.dart';
import 'khachhang.dart';

class KhachHangScreen extends StatefulWidget {
  const KhachHangScreen({super.key});

  @override
  State<KhachHangScreen> createState() => _KhachHangScreenState();
}

class _KhachHangScreenState extends State<KhachHangScreen> {
  List khachHangs = [];
  List filteredKhachHangs = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchKhachHangs();
  }

  Future<void> fetchKhachHangs() async {
    setState(() => isLoading = true);
    final data = await Khachhangservice.fetchKhachHangFull();
    setState(() {
      khachHangs = data;
      filteredKhachHangs = data;
      isLoading = false;
    });
  }

  void filterKhachHangs(String query) {
    final filtered =
        khachHangs.where((khach) {
          final ten = khach.tenKhachHang.toLowerCase();
          final sdt = khach.soDienThoai.toLowerCase();
          return ten.contains(query.toLowerCase()) ||
              sdt.contains(query.toLowerCase());
        }).toList();

    setState(() {
      searchQuery = query;
      filteredKhachHangs = filtered;
    });
  }

  void _openLichSuDatSan(KhachHang khach) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => LichSuDatSanScreen(
              maKhachHang: khach.maKhachHang,
              tenKhachHang: khach.tenKhachHang,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Danh sách khách hàng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF42A5F5),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFB3E5FC).withOpacity(0.9),
              const Color(0xFFBBDEFB),
            ],
          ),
        ),
        child:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF42A5F5),
                    strokeWidth: 3,
                  ),
                )
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Tìm theo tên hoặc SĐT',
                            labelStyle: TextStyle(
                              color: const Color(0xFF42A5F5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: const Color(0xFF42A5F5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: const Color(0xFF42A5F5),
                            ),
                            filled: true,
                          ),
                          onChanged: filterKhachHangs,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredKhachHangs.length,
                        itemBuilder: (context, index) {
                          final khach = filteredKhachHangs[index];
                          return Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    const Color(0xFFBBDEFB).withOpacity(0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFB3E5FC),
                                  child: Icon(
                                    Icons.person,
                                    color: const Color(0xFF42A5F5),
                                    size: 28,
                                  ),
                                ),
                                title: Text(
                                  khach.tenKhachHang,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF42A5F5),
                                  ),
                                ),
                                subtitle: Text(
                                  'SĐT: ${khach.soDienThoai}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _openLichSuDatSan(khach),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF42A5F5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    elevation: 6,
                                    shadowColor: const Color(
                                      0xFF42A5F5,
                                    ).withOpacity(0.3),
                                  ),
                                  child: Icon(
                                    Icons.history,
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
                  ],
                ),
      ),
    );
  }
}
