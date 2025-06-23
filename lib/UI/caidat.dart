import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../DAO/caidatservice.dart';
import 'loginform.dart';
import 'registerform.dart';
import 'doimatkhau.dart';
import 'thongtin.dart';

class SettingsPage extends StatefulWidget {
  final int? maKhachHang;
  final String? vaiTro;

  const SettingsPage({super.key, this.maKhachHang, this.vaiTro});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  File? _selectedImage;
  bool _isPickingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarPath = prefs.getString(
      'avatarPath_${widget.maKhachHang ?? 'default'}',
    );
    if (avatarPath != null && await File(avatarPath).exists()) {
      setState(() {
        _selectedImage = File(avatarPath);
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final directory = await getTemporaryDirectory();
        final fileName =
            'avatar_${widget.maKhachHang ?? 'default'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${directory.path}/$fileName';
        final file = await File(pickedFile.path).copy(filePath);

        setState(() => _selectedImage = file);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'avatarPath_${widget.maKhachHang ?? 'default'}',
          filePath,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi chọn ảnh: $e')));
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('maKhachHang');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể gọi $phoneNumber')));
    }
  }

  Widget _buildAvatarAndName(String name) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF42A5F5), width: 2),
                image: DecorationImage(
                  image:
                      _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : const AssetImage('Assets/boy.png') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isPickingImage ? null : _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        _isPickingImage
                            ? Colors.blueGrey
                            : const Color(0xFF42A5F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCommonSettingsList() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.camera_alt, color: Color(0xFF42A5F5)),
          title: const Text('Đổi ảnh đại diện'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _isPickingImage ? null : _pickImage,
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: Color(0xFF42A5F5)),
          title: const Text('Thông tin'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => InfoScreen(maKhachHang: widget.maKhachHang),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock, color: Color(0xFF42A5F5)),
          title: const Text('Mật khẩu'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        ChangePasswordScreen(maKhachHang: widget.maKhachHang),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today, color: Color(0xFF42A5F5)),
          title: const Text('Danh sách lịch đặt'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.contact_phone, color: Color(0xFF42A5F5)),
          title: const Text('Liên hệ'),
          subtitle: const Text(
            '632 Đường Trường Chinh, Quận Tân Bình, 72109\n+84 916 222 738',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF42A5F5)),
            onPressed: () => _makePhoneCall('+84916222738'),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.language, color: Color(0xFF42A5F5)),
          title: const Text('Ngôn ngữ - Tiếng Việt'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Color(0xFF42A5F5)),
          title: const Text('Đăng xuất'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Widget _buildAdminOrStaffUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAvatarAndName("ADMIN"),
          const SizedBox(height: 24),
          _buildCommonSettingsList(),
        ],
      ),
    );
  }

  Widget _buildUserUI(String tenKhachHang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAvatarAndName(tenKhachHang),
          const SizedBox(height: 24),
          _buildCommonSettingsList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.maKhachHang == null &&
        widget.vaiTro != "Quản trị" &&
        widget.vaiTro != "Nhân viên") {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Cài đặt tài khoản"),
          backgroundColor: const Color(0xFF42A5F5),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAvatarAndName("Khách"),
              const SizedBox(height: 16),
              const Text(
                'Cầu lông Pro',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tạo tài khoản để nâng cao trải nghiệm của bạn',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                child: const Text("Đăng nhập"),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ResgisterScreen()),
                  );
                },
                child: const Text("Đăng ký"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("👤 Cài đặt tài khoản"),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      body:
          (widget.vaiTro == "Quản trị" || widget.vaiTro == "Nhân viên")
              ? _buildAdminOrStaffUI()
              : FutureBuilder(
                future: Caidatservice.fetchKhachHangs(widget.maKhachHang ?? 0),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('❌ Lỗi: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('❌ Không tìm thấy thông tin khách hàng!'),
                    );
                  }
                  final kh = snapshot.data![0];
                  return _buildUserUI(kh.tenKhachHang ?? "Người dùng");
                },
              ),
    );
  }
}
