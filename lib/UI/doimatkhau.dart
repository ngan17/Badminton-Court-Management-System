import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../DAO/caidatservice.dart';
import '../DAO/ipconfigsetting.dart';

class ChangePasswordScreen extends StatefulWidget {
  final int? maKhachHang;

  const ChangePasswordScreen({super.key, this.maKhachHang});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int? _maNguoiDung;

  @override
  void initState() {
    super.initState();
    if (widget.maKhachHang == null) {
      _errorMessage = "Vui lòng đăng nhập để đổi mật khẩu!";
    } else {
      _fetchMaNguoiDung();
    }
    print("ChangePasswordScreen data: maKhachHang=${widget.maKhachHang}");
  }

  Future<void> _fetchMaNguoiDung() async {
    try {
      final khachHangs = await Caidatservice.fetchKhachHangs(
        widget.maKhachHang!,
      );
      if (khachHangs.isNotEmpty) {
        setState(() {
          _maNguoiDung = khachHangs[0].maNguoiDung;
        });
      } else {
        setState(() {
          _errorMessage = "Không tìm thấy thông tin khách hàng!";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi khi lấy thông tin: $e";
      });
    }
  }

  Future<void> _changePassword() async {
    if (_maNguoiDung == null) {
      setState(() {
        _errorMessage = "Không thể xác định người dùng!";
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Mật khẩu mới và xác nhận không khớp!";
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Ipconfigsetting.ip}/api/TaiKhoan/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'MaNguoiDung': _maNguoiDung,
          'OldPassword': _oldPasswordController.text,
          'NewPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: Color(0xFF1976D2), // Xanh dương đậm
          ),
        );
        Navigator.pop(context);
      } else {
        final error =
            jsonDecode(response.body)['message'] ?? 'Đổi mật khẩu thất bại!';
        setState(() {
          _errorMessage = error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2), // Xanh dương đậm
        elevation: 4,
      ),
      body: SingleChildScrollView(
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
                    const Text(
                      'Đổi mật khẩu:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Text màu đen nhạt
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _oldPasswordController,
                      style: const TextStyle(
                        color: Colors.black87,
                      ), // Text nhập liệu màu đen
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu cũ',
                        labelStyle: TextStyle(
                          color: Colors.black87,
                        ), // Label màu đen
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Color(0xFF1976D2),
                        ), // Xanh dương đậm
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      style: const TextStyle(
                        color: Colors.black87,
                      ), // Text nhập liệu màu đen
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới',
                        labelStyle: TextStyle(
                          color: Colors.black87,
                        ), // Label màu đen
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Color(0xFF1976D2),
                        ), // Xanh dương đậm
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      style: const TextStyle(
                        color: Colors.black87,
                      ), // Text nhập liệu màu đen
                      decoration: const InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        labelStyle: TextStyle(
                          color: Colors.black87,
                        ), // Label màu đen
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Color(0xFF1976D2),
                        ), // Xanh dương đậm
                      ),
                      obscureText: true,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                        ), // Giữ đỏ cho lỗi
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  _isLoading || _maNguoiDung == null ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2), // Xanh dương đậm
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Xác nhận đổi mật khẩu',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
