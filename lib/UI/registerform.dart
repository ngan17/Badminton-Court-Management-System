import 'package:do_an_quan_ly_cau_long/DAO/ipconfigsetting.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'mainscreen.dart';
import 'loginform.dart'; // Import LoginScreen for navigation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Ipconfigsetting.init(); // Khởi tạo IP
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ResgisterScreen(),
    );
  }
}

class ResgisterScreen extends StatefulWidget {
  const ResgisterScreen({super.key});

  @override
  _ResgisterScreenState createState() => _ResgisterScreenState();
}

class _ResgisterScreenState extends State<ResgisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController(); // Tên khách hàng
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();

  String? tenKhach = "";
  String? _deviceToken;
  String? _apiToken;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _repasswordController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Hàm xác thực form
  String? _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      return "Vui lòng nhập tên khách hàng";
    }
    if (_usernameController.text.trim().isEmpty) {
      return "Vui lòng nhập tên đăng nhập";
    }
    if (_passwordController.text.trim().isEmpty) {
      return "Vui lòng nhập mật khẩu";
    }
    if (_passwordController.text.trim() != _repasswordController.text.trim()) {
      return "Mật khẩu nhập lại không khớp";
    }
    if (_phoneNumberController.text.trim().isEmpty) {
      return "Vui lòng nhập số điện thoại";
    }
    if (_emailController.text.trim().isEmpty ||
        !RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text.trim())) {
      return "Vui lòng nhập email hợp lệ";
    }
    return null;
  }

  // Hàm kiểm tra kết nối mạng
  Future<bool> _checkNetwork() async {
    try {
      final response = await http
          .get(Uri.parse("${Ipconfigsetting.ip}/api/TaiKhoan"))
          .timeout(const Duration(seconds: 5));
      print("🔍 [DEBUG] Network check response: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      print("🔍 [DEBUG] Lỗi kiểm tra kết nối mạng: $e");
      return false;
    }
  }

  Future<void> _register() async {
    final validationError = _validateForm();
    if (validationError != null) {
      print("🔍 [DEBUG] Lỗi xác thực form: $validationError");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final isNetworkAvailable = await _checkNetwork();
    if (!isNetworkAvailable) {
      print("🔍 [DEBUG] Không có kết nối tới server ${Ipconfigsetting.ip}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Không thể kết nối tới server"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final deviceToken = await FirebaseMessaging.instance.getToken();
      setState(() => _deviceToken = deviceToken);
      print("🔍 [DEBUG] Device Token: $deviceToken");

      final registerBody = {
        "tenDangNhap": _usernameController.text.trim(),
        "matKhau": _passwordController.text.trim(),
        "tenKhachHang": _nameController.text.trim(),
        "soDienThoai": _phoneNumberController.text.trim(),
        "email": _emailController.text.trim(),
        "deviceToken": deviceToken,
      };
      print("[DEBUG] Request Body: ${jsonEncode(registerBody)}");

      final response = await http.post(
        Uri.parse("${Ipconfigsetting.ip}/api/TaiKhoan/register"),
        headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode(registerBody),
      );

      print("[DEBUG] Response Status: ${response.statusCode}");
      print("[DEBUG] Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final maNguoiDung = jsonResponse["maNguoiDung"] ?? 0;
        final maKhachHang = jsonResponse["maKhachHang"] ?? 0;
        final token = jsonResponse["token"] ?? "";
        final vaiTro = jsonResponse["vaiTro"] ?? "";
        final tenKhachHang = jsonResponse["tenKhachHang"] ?? "";

        setState(() => _apiToken = token);

        print("[DEBUG] Đăng ký thành công. Điều hướng tới MainScreen");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => MainScreen(
                  isLoggedIn: true,
                  maKhachHang: maKhachHang,
                  tenKhachHang: tenKhachHang,
                  maNguoiDung: maNguoiDung,
                  vaiTro: vaiTro,
                ),
          ),
        );
      } else {
        final errorMessage =
            response.body.isEmpty
                ? "Không thể kết nối đến endpoint"
                : response.body;
        print(
          "[DEBUG] Lỗi API: Status ${response.statusCode}, Body: $errorMessage",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi đăng ký: $errorMessage"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print("[DEBUG] Lỗi ngoại lệ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đăng ký thất bại: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      print("[DEBUG] Hoàn tất quá trình đăng ký");
    }
  }

  void _goBack() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  void _goToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'Assets/panelLogin.jpg',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.4),
            colorBlendMode: BlendMode.darken,
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _goBack,
              tooltip: 'Quay lại',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.3),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Card(
                      elevation: 20,
                      shadowColor: Colors.blueAccent.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [Colors.white, Colors.blueAccent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: const Icon(
                                  Icons.person_add,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Đăng Ký Tài Khoản',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Điền thông tin để tạo tài khoản mới",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: "Tên khách hàng",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: "Tên đăng nhập",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: "Mật khẩu",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _repasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: "Nhập lại mật khẩu",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _phoneNumberController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: "Số điện thoại",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.phone,
                                    color: Colors.white,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email,
                                    color: Colors.white,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _register,
                                  icon: const Icon(
                                    Icons.person_add,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _isLoading ? "Đang đăng ký..." : "Đăng Ký",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    surfaceTintColor: Colors.transparent,
                                  ).copyWith(
                                    overlayColor: WidgetStateProperty.all(
                                      Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _goToLogin,
                                  icon: const Icon(
                                    Icons.login,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Đăng Nhập",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white70,
                                      width: 2,
                                    ),
                                    surfaceTintColor: Colors.transparent,
                                  ).copyWith(
                                    overlayColor: WidgetStateProperty.all(
                                      Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
