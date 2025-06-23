import 'package:do_an_quan_ly_cau_long/DAO/ipconfigsetting.dart';
import 'package:do_an_quan_ly_cau_long/UI/registerform.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mainscreen.dart';
import 'registerform.dart'; // Import ResgisterScreen for navigation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Ipconfigsetting.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) =>
      MaterialApp(debugShowCheckedModeBanner: false, home: const LoginScreen());
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
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
      duration: const Duration(milliseconds: 1000),
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập tên đăng nhập và mật khẩu"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final deviceToken = await FirebaseMessaging.instance.getToken();
      setState(() => _deviceToken = deviceToken);

      final response = await http.post(
        Uri.parse("${Ipconfigsetting.ip}/api/TaiKhoan/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "tenDangNhap": _usernameController.text.trim(),
          "matKhau": _passwordController.text.trim(),
          "deviceToken": deviceToken,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final token = json["token"];
        final maKhachHang = json["maKhachHang"];
        final tenKhachHang = json["tenKhachHang"]?.toString() ?? "";
        final maNguoiDung = json["maNguoiDung"];
        final vaiTro = json['vaiTro'];
        tenKhach = json["tenKhachHang"];
        setState(() => _apiToken = token);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi đăng nhập: ${response.body}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đăng nhập thất bại: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ResgisterScreen()),
    );
  }

  void _goBack() {
    MainScreen();
    Navigator.of(context).pop();
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
            color: Colors.black.withOpacity(0.6), // Darker overlay for subtlety
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
                backgroundColor: Colors.blueGrey.withOpacity(
                  0.2,
                ), // Softer background
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
                      elevation: 10,
                      shadowColor: Colors.blueGrey.withOpacity(
                        0.3,
                      ), // Softer shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFB3E5FC),
                              Color(0xFF42A5F5),
                            ], // Softer blue gradient
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
                                    colors: [
                                      Colors.white70,
                                      Colors.blueGrey,
                                    ], // Softer gradient
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueGrey.withOpacity(
                                        0.3,
                                      ), // Softer shadow
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Chào Mừng Bạn!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius:
                                          3, // Reduced blur for subtlety
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Đăng nhập để trải nghiệm",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: "Tên đăng nhập",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person,
                                    color: Colors.white70, // Softer icon color
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(
                                    0.1,
                                  ), // Lighter fill
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.white70, // Softer border
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
                                    color: Colors.white70, // Softer icon color
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(
                                    0.1,
                                  ), // Lighter fill
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.white70, // Softer border
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
                                  onPressed: _isLoading ? null : _login,
                                  icon: const Icon(
                                    Icons.login,
                                    color: Colors.white70, // Softer icon color
                                  ),
                                  label: Text(
                                    _isLoading
                                        ? "Đang đăng nhập..."
                                        : "Đăng Nhập",
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
                                    foregroundColor:
                                        Colors.white70, // Softer foreground
                                    side: const BorderSide(
                                      color: Colors.white70, // Softer border
                                      width: 2,
                                    ),
                                    surfaceTintColor: Colors.transparent,
                                  ).copyWith(
                                    overlayColor: WidgetStateProperty.all(
                                      Colors.white.withOpacity(
                                        0.1,
                                      ), // Lighter overlay
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _goToRegister,
                                  icon: const Icon(
                                    Icons.person_add,
                                    color: Colors.white70, // Softer icon color
                                  ),
                                  label: const Text(
                                    "Đăng Ký",
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
                                    foregroundColor:
                                        Colors.white70, // Softer foreground
                                    side: const BorderSide(
                                      color:
                                          Colors.white54, // Even softer border
                                      width: 2,
                                    ),
                                    surfaceTintColor: Colors.transparent,
                                  ).copyWith(
                                    overlayColor: WidgetStateProperty.all(
                                      Colors.white.withOpacity(
                                        0.1,
                                      ), // Lighter overlay
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
