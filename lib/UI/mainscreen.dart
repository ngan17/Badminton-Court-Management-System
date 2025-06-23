import 'package:do_an_quan_ly_cau_long/UI/admincboload.dart';
import 'package:do_an_quan_ly_cau_long/UI/chitietgiaidauscreen.dart';
import 'package:flutter/material.dart';
import 'package:do_an_quan_ly_cau_long/DAO/giaidauservice.dart';
import 'package:do_an_quan_ly_cau_long/UI/giaidau.dart';
import 'package:do_an_quan_ly_cau_long/UI/homepage.dart';
import 'package:do_an_quan_ly_cau_long/UI/bookingform.dart';
import 'package:do_an_quan_ly_cau_long/UI/caidat.dart';
import 'package:do_an_quan_ly_cau_long/UI/thongke.dart';
import 'package:url_launcher/url_launcher.dart';
import 'thanhvien.dart';
import 'xacnhanthanhtoanadmin.dart';

class MainScreen extends StatefulWidget {
  final bool isLoggedIn;
  final int? maKhachHang;
  final String? tenKhachHang;
  final int? maNguoiDung;
  final String? vaiTro;

  const MainScreen({
    super.key,
    this.isLoggedIn = false,
    this.maKhachHang,
    this.tenKhachHang,
    this.maNguoiDung,
    this.vaiTro,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late bool isLoggedIn;
  late int? maKhachHang;
  late String tenKhachHang;
  late int? maNguoiDung;
  late String? vaiTro;

  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.isLoggedIn;
    maKhachHang = widget.maKhachHang;
    tenKhachHang = widget.tenKhachHang ?? "";
    maNguoiDung = widget.maNguoiDung;
    vaiTro = widget.vaiTro;
    print("MainScreen vaiTro: $vaiTro");
  }

  void _showChatBot(BuildContext context) {
    showDialog(context: context, builder: (context) => const ChatBotDialog());
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = vaiTro == 'Quản trị' || vaiTro == 'Nhân viên';

    final List<Widget> pages = [
      HomePage(
        isLoggedIn: isLoggedIn,
        maKhachHang: maKhachHang,
        tenKhachHang: tenKhachHang,
        maNguoiDung: maNguoiDung,
        vaiTro: vaiTro,
      ),
      if (isAdmin) ConfirmHoaDonScreen(),
      if (isAdmin)
        VisualBookingScreenForAdmin(maNguoiDung: maNguoiDung, vaiTro: vaiTro)
      else
        VisualBookingScreen(
          maKhachHang: maKhachHang,
          tenKhachHang: tenKhachHang,
          maNguoiDung: maNguoiDung,
          vaiTro: vaiTro,
        ),
      if (isAdmin) KhachHangScreen(),
      GiaidauScreen(vaiTro: vaiTro),
      if (isAdmin) StatsScreen(vaiTro: vaiTro, maKhachHang: maKhachHang),

      SettingsPage(maKhachHang: maKhachHang, vaiTro: vaiTro),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.payment),
          label: 'Hóa đơn',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'Đặt sân',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Thành viên',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.sports),
        label: 'Trận đấu',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Thống kê',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Cài đặt',
      ),
    ];

    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: pages[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        selectedItemColor: const Color(0xFF42A5F5), // Softer blue
        unselectedItemColor: Colors.blueGrey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChatBot(context),
        backgroundColor: const Color(0xFF42A5F5), // Softer blue
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}

class ChatBotDialog extends StatefulWidget {
  const ChatBotDialog({super.key});

  @override
  _ChatBotDialogState createState() => _ChatBotDialogState();
}

class _ChatBotDialogState extends State<ChatBotDialog> {
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

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

  void _handleOption(String option) {
    setState(() {
      // Add user message (question)
      _messages.add({
        'type': 'user',
        'content':
            option == 'address'
                ? 'Xem địa chỉ của câu lạc bộ'
                : option == 'phone'
                ? 'Gọi điện liên hệ hỗ trợ'
                : option == 'booking'
                ? 'Hỏi về cách đặt sân cầu lông'
                : 'Hỏi về giá đặt sân',
      });

      // Add bot response
      if (option == 'address') {
        _messages.add({
          'type': 'bot',
          'content': 'Địa chỉ: 632 Đường Trường Chinh, Quận Tân Bình, 72109',
        });
      } else if (option == 'phone') {
        _messages.add({
          'type': 'bot',
          'content': 'Số điện thoại: +84 916 222 738',
        });
        _makePhoneCall('+84916222738');
      } else if (option == 'booking') {
        _messages.add({
          'type': 'bot',
          'content': 'Để đặt sân, vui lòng vào mục "Đặt sân" trong ứng dụng!',
        });
      } else if (option == 'pricing') {
        _messages.add({
          'type': 'bot',
          'widget': Table(
            border: TableBorder.all(
              color: Colors.blueGrey[300]!,
              width: 1,
              style: BorderStyle.solid,
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFFBBDEFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                children: [
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      'Giờ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      'T7-CN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      'T2-T6',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                decoration: const BoxDecoration(color: Colors.white),
                children: [
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '18:00-05:00',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '110,000 ',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '100,000 ',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blue[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                children: [
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '05:00-10:00',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '80,000 ',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '70,000 ',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              TableRow(
                decoration: const BoxDecoration(color: Colors.white),
                children: [
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '10:00-18:00',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '140,000 ',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '100,000 ',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
          ),
        });
      }

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hỗ trợ nhanh',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF42A5F5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // Chat messages
                    ..._messages.map(
                      (message) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Align(
                          alignment:
                              message['type'] == 'user'
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    message['type'] == 'user'
                                        ? [Colors.blue[100]!, Colors.blue[200]!]
                                        : [Colors.blue[50]!, Colors.blue[100]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blueGrey[300]!,
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueGrey.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child:
                                message['widget'] ??
                                Text(
                                  message['content'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Options (chips)
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ActionChip(
                            label: const Text(
                              'Xem địa chỉ của câu lạc bộ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => _handleOption('address'),
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF42A5F5)),
                            ),
                            labelStyle: const TextStyle(color: Colors.black87),
                            elevation: 2,
                            shadowColor: Colors.blue[100],
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ActionChip(
                            label: const Text(
                              'Gọi điện liên hệ hỗ trợ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => _handleOption('phone'),
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF42A5F5)),
                            ),
                            labelStyle: const TextStyle(color: Colors.black87),
                            elevation: 2,
                            shadowColor: Colors.blue[100],
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ActionChip(
                            label: const Text(
                              'Hỏi về cách đặt sân cầu lông',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => _handleOption('booking'),
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF42A5F5)),
                            ),
                            labelStyle: const TextStyle(color: Colors.black87),
                            elevation: 2,
                            shadowColor: Colors.blue[100],
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ActionChip(
                            label: const Text(
                              'Hỏi về giá đặt sân',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => _handleOption('pricing'),
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF42A5F5)),
                            ),
                            labelStyle: const TextStyle(color: Colors.black87),
                            elevation: 2,
                            shadowColor: Colors.blue[100],
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(color: Color(0xFF42A5F5), fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String title;

  const PlaceholderWidget(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      body: Center(
        child: Text(
          'Đang phát triển $title...',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
