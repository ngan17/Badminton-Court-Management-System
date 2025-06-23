import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../DAO/caidatservice.dart';
import '../DAO/ipconfigsetting.dart';

class InfoScreen extends StatefulWidget {
  final int? maKhachHang;

  const InfoScreen({super.key, this.maKhachHang});

  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  String _tenKhachHang = "Đang tải...";
  String _soDienThoai = "Đang tải...";
  String _email = "Đang tải...";
  int? _maNguoiDung = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isEditing = false;

  final _tenController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.maKhachHang == null) {
      _errorMessage = "Vui lòng đăng nhập để xem thông tin!";
    } else {
      _fetchKhachHangInfo();
    }
    print("InfoScreen data: maKhachHang=${widget.maKhachHang}");
  }

  Future<void> _fetchKhachHangInfo() async {
    if (widget.maKhachHang == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Ipconfigsetting.ip}/api/KhachHangs/${widget.maKhachHang}'),
      );
      print(
        "Fetch response: ${response.statusCode} - ${response.body}",
      ); // Debug
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _tenKhachHang = data['tenKhachHang'] ?? "Không rõ";
          _soDienThoai = data['soDienThoai'] ?? "Không rõ";
          _email = data['email'] ?? "Không rõ";
          _maNguoiDung = data['maNguoiDung'] as int? ?? 0;
          _tenController.text = _tenKhachHang;
          _phoneController.text = _soDienThoai;
          _emailController.text = _email;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              "Không thể tải thông tin: ${response.statusCode} - ${response.body}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _updateKhachHangInfo() async {
    if (widget.maKhachHang == null) return;

    // Kiểm tra dữ liệu hợp lệ
    if (_tenController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty) {
      setState(() {
        _errorMessage = "Vui lòng điền đầy đủ thông tin!";
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('${Ipconfigsetting.ip}/api/KhachHangs/${widget.maKhachHang}'),
        headers: {
          'Content-Type': 'application/json',
          // Thêm header xác thực nếu cần
          // 'Authorization': 'Bearer your_token_here',
        },
        body: jsonEncode({
          'maKhachHang': widget.maKhachHang,
          'tenKhachHang': _tenController.text,
          'soDienThoai': _phoneController.text,
          'email': _emailController.text,
          'maNguoiDung': _maNguoiDung,
        }),
      );

      print(
        "Request body: ${jsonEncode({'maKhachHang': widget.maKhachHang, 'tenKhachHang': _tenController.text, 'soDienThoai': _phoneController.text, 'email': _emailController.text, 'maNguoiDung': _maNguoiDung})}",
      ); // Debug dữ liệu gửi

      print(
        "Update response: ${response.statusCode} - ${response.body}",
      ); // Debug phản hồi
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Chấp nhận cả 204
        setState(() {
          _tenKhachHang = _tenController.text;
          _soDienThoai = _phoneController.text;
          _email = _emailController.text;
          _isEditing = false;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công!')),
        );
      } else if (response.body.isNotEmpty) {
        try {
          final errorData = jsonDecode(response.body);
          setState(() {
            _errorMessage =
                "Cập nhật thất bại: ${response.statusCode} - ${errorData['message'] ?? 'Lỗi không xác định'}";
          });
        } catch (e) {
          setState(() {
            _errorMessage =
                "Lỗi phân tích phản hồi: $e - Raw response: ${response.body}";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Phản hồi từ server rỗng: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin tài khoản'),
        backgroundColor: Color(0xFF1976D2),
        actions: [
          if (!_isEditing && widget.maKhachHang != null)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin tài khoản:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Mã khách hàng: ${widget.maKhachHang}',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _tenController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: 'Tên khách hàng',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _phoneController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: 'Số điện thoại',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing)
                      ElevatedButton(
                        onPressed:
                            _isLoading || widget.maKhachHang == null
                                ? null
                                : _updateKhachHangInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1976D2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Lưu thay đổi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                      )
                    else
                      ElevatedButton(
                        onPressed:
                            widget.maKhachHang == null
                                ? null
                                : () {
                                  Navigator.pop(
                                    context,
                                  ); // Quay lại SettingsPage
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1976D2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Quay lại',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
