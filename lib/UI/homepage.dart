import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../DAO/bookingservice.dart';
import 'loginform.dart';
import 'registerform.dart';

class HomePage extends StatefulWidget {
  final bool isLoggedIn;
  final int? maKhachHang;
  final String? tenKhachHang;
  final int? maNguoiDung;
  final String? vaiTro;

  const HomePage({
    super.key,
    this.isLoggedIn = false,
    this.maKhachHang,
    this.tenKhachHang,
    this.maNguoiDung,
    this.vaiTro,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

enum FilterOption { today, thisWeek, all }

class _HomePageState extends State<HomePage> {
  final today = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now());
  List bookings = [];
  List filteredBookings = [];
  String tenkhach = "Admin";
  int? makhachhang;
  String? vaiTro;
  bool get isLoggedIn => widget.isLoggedIn;
  FilterOption selectedFilter = FilterOption.today;

  @override
  void initState() {
    super.initState();
    tenkhach = widget.tenKhachHang ?? "";
    makhachhang = widget.maKhachHang;
    vaiTro = widget.vaiTro;
    print("HomePage vaiTro: $vaiTro");
    loadBookings();
  }

  Future<void> loadBookings() async {
    if (!mounted) return;
    final isAdmin = vaiTro == "Quản trị" || vaiTro == "Nhân viên";
    final data =
        isAdmin
            ? await BookingService.fetchBookings()
            : await BookingService.fetchBookingsByCustomer(makhachhang);
    setState(() {
      bookings = data;
      filteredBookings = _filterBookings(data);
    });
  }

  List _filterBookings(List bookings) {
    if ((widget.vaiTro == 'Quản trị' || widget.vaiTro == 'Nhân viên')) {
      final now = DateTime.now();
      switch (selectedFilter) {
        case FilterOption.today:
          return bookings.where((item) {
            final bookingDate = DateTime.parse(item['ngayDat']);
            return bookingDate.year == now.year &&
                bookingDate.month == now.month &&
                bookingDate.day == now.day;
          }).toList();
        case FilterOption.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(Duration(days: 6));
          return bookings.where((item) {
            final bookingDate = DateTime.parse(item['ngayDat']);
            return bookingDate.isAfter(
                  startOfWeek.subtract(Duration(days: 1)),
                ) &&
                bookingDate.isBefore(endOfWeek.add(Duration(days: 1)));
          }).toList();
        case FilterOption.all:
          return List.from(bookings);
      }
    } else {
      return bookings.where((item) {
        if (item['maKhachHang'] != makhachhang) return false;
        final dateStr = item['ngayDat'];
        if (dateStr == null) return false;
        final bookingDate = DateTime.parse(dateStr);
        final now = DateTime.now();
        switch (selectedFilter) {
          case FilterOption.today:
            return bookingDate.year == now.year &&
                bookingDate.month == now.month &&
                bookingDate.day == now.day;
          case FilterOption.thisWeek:
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final endOfWeek = startOfWeek.add(Duration(days: 6));
            return bookingDate.isAfter(
                  startOfWeek.subtract(Duration(days: 1)),
                ) &&
                bookingDate.isBefore(endOfWeek.add(Duration(days: 1)));
          case FilterOption.all:
            return true;
        }
      }).toList();
    }
    return [];
  }

  int getTotalBookings() {
    return filteredBookings.length;
  }

  int getTotalCourtsBusy() {
    int busyCount = 0;
    for (int courtId = 1; courtId <= 4; courtId++) {
      if (isCourtBusy(courtId, bookings)) {
        busyCount++;
      }
    }
    return busyCount;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = vaiTro == "Quản trị" || vaiTro == "Nhân viên";
    filteredBookings = _filterBookings(bookings);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: screenHeight * 0.20,
            backgroundColor: const Color(0xFF42A5F5),
            automaticallyImplyLeading: false, // Loại bỏ nút quay lại
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("Assets/panel9.jpg"),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color.fromARGB(255, 255, 255, 255),
                      const Color(0xFFBBDEFB),
                    ],
                  ),
                ),
                padding: EdgeInsets.only(
                  left: screenWidth * 0.04,
                  right: screenWidth * 0.04,
                  top: screenHeight * 0.08,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      today,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      children: [
                        if (!isLoggedIn) ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  19,
                                  59,
                                  78,
                                ),
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  229,
                                  232,
                                  236,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.015,
                                ),
                              ),
                              child: Text(
                                'Đăng nhập',
                                style: TextStyle(fontSize: screenWidth * 0.04),
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ResgisterScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  0,
                                  0,
                                  0,
                                ),
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 72, 87, 100),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.015,
                                ),
                              ),
                              child: Text(
                                'Đăng ký',
                                style: TextStyle(fontSize: screenWidth * 0.04),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: screenWidth * 0.05,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: Text(
                                    'Xin chào, $tenkhach',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                        ],
                        Expanded(
                          child: Image.asset(
                            "Assets/NGLO.png",
                            width: screenWidth * 0.25,
                            height: screenHeight * 0.08,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái các sân:',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF42A5F5),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.015),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          final courtId = index + 1;
                          final busy = isCourtBusy(courtId, bookings);
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.015,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color:
                                      busy
                                          ? Colors.red.shade400
                                          : Colors.blue.shade400,
                                  size: screenWidth * 0.025,
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  'Sân $courtId',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  busy ? 'Bận' : 'Trống',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.025,
                                    color:
                                        busy
                                            ? Colors.red.shade600
                                            : Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  if (isLoggedIn) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAdmin
                              ? '📋 Tất cả lịch đặt sân:'
                              : '📋 Lịch đặt sân của bạn:',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF42A5F5),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB3E5FC),
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.05,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButton<FilterOption>(
                            value: selectedFilter,
                            dropdownColor: Colors.white,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: const Color(0xFF42A5F5),
                              size: screenWidth * 0.05,
                            ),
                            underline: SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: FilterOption.today,
                                child: Text(
                                  'Hôm nay',
                                  style: TextStyle(color: Color(0xFF42A5F5)),
                                ),
                              ),
                              DropdownMenuItem(
                                value: FilterOption.thisWeek,
                                child: Text(
                                  'Tuần này',
                                  style: TextStyle(color: Color(0xFF42A5F5)),
                                ),
                              ),
                              DropdownMenuItem(
                                value: FilterOption.all,
                                child: Text(
                                  'Tất cả',
                                  style: TextStyle(color: Color(0xFF42A5F5)),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedFilter = value;
                                  filteredBookings = _filterBookings(bookings);
                                });
                              }
                            },
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: const Color(0xFF42A5F5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Tổng đặt sân',
                            getTotalBookings().toString(),
                            const Color(0xFF42A5F5),
                          ),
                          _buildStatCard(
                            'Sân bận',
                            getTotalCourtsBusy().toString(),
                            Colors.red.shade600,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                  if (!isLoggedIn) ...[
                    SizedBox(height: screenHeight * 0.02),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        child: Image.asset(
                          'Assets/sport_banner.jpg',
                          width: screenWidth * 0.9,
                          height: screenHeight * 0.5,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      '🏸 Đặt sân dễ dàng - Trải nghiệm tuyệt vời!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF42A5F5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Hệ thống hỗ trợ đặt sân cầu lông trực tuyến nhanh chóng và thuận tiện.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ] else ...[
                    ...filteredBookings.map((item) {
                      final gio = item['gioBatDau'] ?? '00:00:00';
                      final ten = item['tenKhachHang'] ?? 'Ẩn danh';
                      final duration = item['thoiLuong'] ?? 0;
                      final date = item['ngayDat'] ?? '';
                      final courtName = item['maSan'] ?? '';

                      // Kiểm tra thời gian đặt sân
                      final now = DateTime.now();
                      final startDateTime = DateTime.parse('$date $gio');
                      final isPast = now.isAfter(startDateTime);

                      return BookingItem(
                        time: gio,
                        name: ten,
                        duration: '$duration giờ',
                        date: date,
                        courtName: courtName,
                        isPast: isPast, // Truyền trạng thái thời gian
                        onCancel:
                            isPast
                                ? null
                                : () async {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              screenWidth * 0.03,
                                            ),
                                          ),
                                          title: Text('Xác nhận'),
                                          content: Text(
                                            'Bạn có chắc muốn hủy đặt sân này không?',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.04,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.grey,
                                              ),
                                              child: Text(
                                                'Không',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: Text(
                                                'Hủy đặt',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await BookingService.cancelBooking(
                                        item['maDatSan'],
                                      );
                                      await loadBookings();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Đã hủy đặt sân thành công',
                                          ),
                                          backgroundColor: const Color(
                                            0xFF42A5F5,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              screenWidth * 0.03,
                                            ),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Hủy không thành công: $e',
                                          ),
                                          backgroundColor: Colors.red.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              screenWidth * 0.03,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                      );
                    }),
                  ],
                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(
          MediaQuery.of(context).size.width * 0.03,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.035,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Text(
            value,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.05,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class BookingItem extends StatelessWidget {
  final String time, name, duration, date;
  final int courtName;
  final bool isPast; // Thêm thuộc tính kiểm tra thời gian
  final VoidCallback? onCancel;

  const BookingItem({
    super.key,
    required this.time,
    required this.name,
    required this.duration,
    required this.date,
    required this.courtName,
    required this.isPast,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
    final formattedTime = time.substring(0, 5);
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        side: BorderSide(color: const Color(0xFFB3E5FC), width: 1),
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFBBDEFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_tennis,
                color: Colors.white,
                size: screenWidth * 0.07,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏰ $formattedTime • $formattedDate',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF42A5F5),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    '👤 $name',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '📍 Sân: $courtName',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '⏳ $duration',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: isPast ? Colors.grey : Colors.red.shade600,
                size: screenWidth * 0.05,
              ),
              onPressed:
                  isPast ? null : onCancel, // Vô hiệu hóa nếu đã qua thời gian
            ),
          ],
        ),
      ),
    );
  }
}

bool isCourtBusy(int courtId, List bookings) {
  final now = DateTime.now();
  for (var booking in bookings) {
    final bookedCourt = booking['maSan'];
    if (bookedCourt != courtId) continue;

    final dateStr = booking['ngayDat'] ?? '';
    final timeStr = booking['gioBatDau'] ?? '00:00:00';
    final duration = booking['thoiLuong'] ?? 0;

    final startDateTime = DateTime.parse('$dateStr $timeStr');
    final endDateTime = startDateTime.add(Duration(hours: duration));
    if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
      return true;
    }
  }
  return false;
}
