import 'package:do_an_quan_ly_cau_long/DAO/ipconfigsetting.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class VisualBookingScreenForAdmin extends StatefulWidget {
  final int? maNguoiDung; // Mã admin
  final String? vaiTro; // Vai trò (ví dụ: "admin")

  const VisualBookingScreenForAdmin({super.key, this.maNguoiDung, this.vaiTro});

  @override
  State<VisualBookingScreenForAdmin> createState() =>
      _VisualBookingScreenForAdminState();
}

class _VisualBookingScreenForAdminState
    extends State<VisualBookingScreenForAdmin> {
  String? selectedCourt;
  String? selectedHour;
  DateTime selectedDate = DateTime.now();
  double selectedDuration = 1;
  List<CourtSlot> courtSlots = [];
  int? _selectedKhachHangId; // Mã khách hàng do admin chọn
  List<dynamic> _khachHangs = []; // Danh sách khách hàng
  bool _isBookingConfirmed = false; // Trạng thái xác nhận đặt sân

  final List<String> hours = List.generate(
    24,
    (i) => '${i.toString().padLeft(2, '0')}:00',
  );

  final List<Map<String, dynamic>> courts = [
    {'maSan': 1, 'tenSan': 'Sân 1'},
    {'maSan': 2, 'tenSan': 'Sân 2'},
    {'maSan': 3, 'tenSan': 'Sân 3'},
    {'maSan': 4, 'tenSan': 'Sân 4'},
  ];

  int? get maNguoiDung => widget.maNguoiDung;
  String? get vaiTro => widget.vaiTro;

  @override
  void initState() {
    super.initState();
    fetchSlots();
    _loadKhachHangs();
  }

  double calculateBookingCost(
    DateTime ngayDat,
    String gioBatDau,
    int thoiLuong,
  ) {
    final hour = int.parse(gioBatDau.split(':')[0]);
    final dayOfWeek = ngayDat.weekday;
    final isWeekend =
        dayOfWeek == 6 ||
        dayOfWeek == 7; // Hôm nay là Thứ Bảy, isWeekend = true

    double pricePerHour;
    if (hour >= 18 || hour < 5) {
      pricePerHour = isWeekend ? 110000.0 : 100000.0; // 110,000 VNĐ cho T7-CN
    } else if (hour >= 5 && hour < 10) {
      pricePerHour = isWeekend ? 80000.0 : 70000.0; // 80,000 VNĐ cho T7-CN
    } else {
      pricePerHour = isWeekend ? 140000.0 : 100000.0; // 140,000 VNĐ cho T7-CN
    }

    return pricePerHour * thoiLuong;
  }

  Future<void> _loadKhachHangs() async {
    try {
      final url = Uri.parse('${Ipconfigsetting.ip}/api/KhachHangs');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _khachHangs = jsonDecode(response.body) as List;
        });
      } else {
        print('❗ Lỗi tải danh sách khách hàng: ${response.statusCode}');
      }
    } catch (e) {
      print('❗ Lỗi loadKhachHangs: $e');
    }
  }

  Future<void> fetchSlots() async {
    final url = Uri.parse(
      '${Ipconfigsetting.ip}/api/DatSans?date=${DateFormat('yyyy-MM-dd').format(selectedDate)}',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        List<CourtSlot> tempSlots = [];

        for (var court in courts) {
          final courtId = court['maSan'];
          final courtName = court['tenSan'];

          List<Slot> slots = [];

          for (int h = 0; h < 24; h++) {
            final timeStr = '${h.toString().padLeft(2, '0')}:00';
            String status = 'available';

            for (var booking in data) {
              if (booking['maSan'] == courtId &&
                  booking['ngayDat'] ==
                      DateFormat('yyyy-MM-dd').format(selectedDate) &&
                  booking['gioBatDau'] != null) {
                final startHour = int.parse(
                  booking['gioBatDau'].toString().split(":")[0],
                );
                final duration = booking['thoiLuong'] as int? ?? 1;
                final endHour = startHour + duration - 1;

                if (h >= startHour && h <= endHour) {
                  status = 'locked';
                  break;
                }
              }
            }

            slots.add(Slot(time: timeStr, status: status));
          }

          tempSlots.add(CourtSlot(court: courtName, slots: slots));
        }

        setState(() => courtSlots = tempSlots);
      } else {
        print('❗ Lỗi khi load dữ liệu: ${res.statusCode}');
      }
    } catch (e) {
      print('❗ Lỗi fetchSlots: $e');
    }
  }

  Color getColor(String status, bool isSelected) {
    if (isSelected)
      return const Color(0xFF42A5F5); // Xanh dương trung cho slot chọn
    if (status == 'locked') return Colors.grey;
    return Colors.white;
  }

  Future<void> _bookSlot() async {
    if (selectedCourt == null || selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn sân và giờ!")),
      );
      return;
    }

    int? selectedMaKhachHang;
    await showDialog(
      context: context,
      barrierDismissible: false, // Ngăn người dùng nhấn ngoài để đóng
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            // Hủy quá trình khi nhấn Back trong dialog
            _isBookingConfirmed = false;
            return true; // Cho phép đóng dialog
          },
          child: StatefulBuilder(
            builder: (BuildContext dialogContext, StateSetter setDialogState) {
              return AlertDialog(
                title: const Text('Chọn khách hàng'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<int>(
                        hint: const Text('Chọn khách hàng'),
                        value: _selectedKhachHangId,
                        items:
                            _khachHangs.isNotEmpty
                                ? _khachHangs.map((khachHang) {
                                  return DropdownMenuItem<int>(
                                    value: khachHang['maKhachHang'],
                                    child: Text(
                                      '${khachHang['tenKhachHang']} (SĐT: ${khachHang['soDienThoai']})',
                                    ),
                                  );
                                }).toList()
                                : [
                                  const DropdownMenuItem<int>(
                                    child: Text('Không có khách hàng'),
                                  ),
                                ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedKhachHangId = value;
                            print('Đã chọn: $_selectedKhachHangId');
                          });
                        },
                      ),
                      if (_selectedKhachHangId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Khách hàng đã chọn: ${_khachHangs.firstWhere((kh) => kh['maKhachHang'] == _selectedKhachHangId, orElse: () => {'tenKhachHang': 'Không rõ'})['tenKhachHang']} (Mã: $_selectedKhachHangId)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _isBookingConfirmed = false;
                      Navigator.pop(context);
                    },
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _selectedKhachHangId != null
                            ? () {
                              selectedMaKhachHang = _selectedKhachHangId;
                              _isBookingConfirmed = true; // Xác nhận đặt sân
                              Navigator.pop(context);
                            }
                            : null,
                    child: const Text('Xác nhận'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    // Kiểm tra nếu không có xác nhận, hủy quá trình
    if (!_isBookingConfirmed || selectedMaKhachHang == null) {
      _isBookingConfirmed = false; // Đặt lại trạng thái
      return;
    }

    final selectedStartHour = int.parse(selectedHour!.split(':')[0]);
    final bookingStartTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedStartHour,
    );

    final selectedEndTime = bookingStartTime.add(
      Duration(hours: selectedDuration.toInt()),
    );

    // Kiểm tra thời gian dựa trên DateTime.now() (11:26 AM, 14/06/2025)
    final now = DateTime.now();
    if (bookingStartTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Thời gian bắt đầu phải sau thời điểm hiện tại (11:26 AM, 14/06/2025)!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      _isBookingConfirmed = false; // Đặt lại trạng thái
      return;
    }

    final selectedCourtSlot = courtSlots.firstWhere(
      (c) => c.court == selectedCourt,
    );

    final hoursToCheck = List.generate(
      selectedDuration.toInt(),
      (i) => '${(selectedStartHour + i).toString().padLeft(2, '0')}:00',
    );

    final isOverlap = selectedCourtSlot.slots.any(
      (s) => hoursToCheck.contains(s.time) && s.status == 'locked',
    );

    if (isOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Khung giờ đã có người đặt!")),
      );
      _isBookingConfirmed = false; // Đặt lại trạng thái
      return;
    }

    final tongTien = calculateBookingCost(
      selectedDate,
      selectedHour!,
      selectedDuration.toInt(),
    );
    final court = courts.firstWhere((c) => c['tenSan'] == selectedCourt);

    final bookingData = {
      "maKhachHang": selectedMaKhachHang,
      "maSan": court['maSan'],
      "ngayDat": DateFormat('yyyy-MM-dd').format(bookingStartTime),
      "gioBatDau": DateFormat('HH:mm').format(bookingStartTime),
      "thoiLuong": selectedDuration.toInt(),
      "trangThai": "Đã thanh toán", // Đặt trực tiếp trạng thái thanh toán
    };

    try {
      final url = Uri.parse('${Ipconfigsetting.ip}/api/DatSans');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final maDatSan = jsonResponse['maDatSan'] as int?;

        // (Tùy chọn) Tạo hóa đơn ngay sau khi đặt sân
        final hoaDonData = {
          "maKhachHang": selectedMaKhachHang,
          "maDatSan": maDatSan,
          "thoiGianThanhToan": DateTime.now().toIso8601String(),
          "soTien": tongTien,
          "trangThai": "Đã thanh toán",
          "phuongThucThanhToan": "Tự động", // Hoặc để null nếu không cần
        };

        final hoaDonUrl = Uri.parse('${Ipconfigsetting.ip}/api/HoaDons');
        final hoaDonResponse = await http.post(
          hoaDonUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(hoaDonData),
        );

        if (hoaDonResponse.statusCode == 201) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅Đặt sân và thanh toán thành công!'),
              backgroundColor: Color(0xFF1976D2),
            ),
          );
          Navigator.pop(context); // Quay lại màn hình trước
          _isBookingConfirmed = false; // Đặt lại trạng thái
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ' Lỗi tạo hóa đơn: [${hoaDonResponse.statusCode}] ${hoaDonResponse.body}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ' Đặt sân thất bại! [${response.statusCode}] ${response.body}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      _isBookingConfirmed = false; // Đặt lại trạng thái sau khi hoàn tất
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Hủy quá trình đặt sân khi nhấn Back
        if (_isBookingConfirmed) {
          _isBookingConfirmed = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quá trình đặt sân đã bị hủy!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return true; // Cho phép quay lại
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đặt lịch ngày trực quan (Admin)'),
          backgroundColor: const Color(0xFF1976D2), // Xanh dương đậm
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                          fetchSlots();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF1976D2,
                        ), // Xanh dương đậm
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    color: const Color(0xFF64B5F6), // Xanh dương nhạt
                    child: Column(
                      children: [
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          color: const Color(0xFFBBDEFB), // Lighter blue
                          child: const Text(''),
                        ),
                        ...courts.map(
                          (court) => Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              court['tenSan'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder.all(color: Colors.blueGrey[200]!),
                        columnWidths: {
                          for (int i = 0; i < hours.length; i++)
                            i: const FixedColumnWidth(80),
                        },
                        children: [
                          TableRow(
                            children:
                                hours
                                    .map(
                                      (h) => Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        color: const Color(0xFFBBDEFB),
                                        child: Text(
                                          h,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                          ...courts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final court = entry.value;
                            final courtName = court['tenSan'];
                            final courtData = courtSlots.firstWhere(
                              (c) => c.court == courtName,
                              orElse:
                                  () => CourtSlot(court: courtName, slots: []),
                            );

                            return TableRow(
                              children:
                                  hours.map((h) {
                                    final slot = courtData.slots.firstWhere(
                                      (s) => s.time == h,
                                      orElse:
                                          () => Slot(
                                            time: h,
                                            status: 'available',
                                          ),
                                    );

                                    final isSelected =
                                        selectedCourt == courtName &&
                                        selectedHour == h;
                                    final color = getColor(
                                      slot.status,
                                      isSelected,
                                    );

                                    return GestureDetector(
                                      onTap:
                                          slot.status == 'available'
                                              ? () {
                                                setState(() {
                                                  selectedCourt = courtName;
                                                  selectedHour = h;
                                                });
                                              }
                                              : null,
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: color,
                                          border: Border.all(
                                            color: Colors.blueGrey[200]!,
                                          ),
                                        ),
                                        child:
                                            slot.status == 'available'
                                                ? null
                                                : const Icon(
                                                  Icons.lock,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Table(
                  border: TableBorder.all(color: Colors.blueGrey[200]!),
                  columnWidths: const {
                    0: FixedColumnWidth(100),
                    1: FixedColumnWidth(100),
                    2: FixedColumnWidth(100),
                  },
                  children: [
                    TableRow(
                      children: [
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          color: const Color(0xFFBBDEFB),
                          child: const Text(
                            'Thời gian',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          color: const Color(0xFFBBDEFB),
                          child: const Text(
                            'T7-CN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          color: const Color(0xFFBBDEFB),
                          child: const Text(
                            'T2-T6',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: const Text(
                            '18:00-05:00',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: const Text(
                            '110,000 Đ',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: const Text(
                            '100,000 Đ',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: const Text(
                            '05:00-10:00',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: const Text(
                            '80,000 Đ',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: const Text(
                            '70,000 Đ',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: const Text(
                            '10:00-18:00',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: const Text(
                            '140,000 Đ',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: const Text(
                            '100,000 Đ',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Thời lượng: ${selectedDuration.toInt()} giờ'),
                  Slider(
                    value: selectedDuration,
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label: selectedDuration.toInt().toString(),
                    activeColor: const Color(0xFF1976D2), // Xanh dương đậm
                    inactiveColor: const Color(0xFF64B5F6), // Xanh dương nhạt
                    onChanged:
                        (value) => setState(() => selectedDuration = value),
                  ),
                  ElevatedButton(
                    onPressed:
                        selectedCourt != null && selectedHour != null
                            ? _bookSlot
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF1976D2,
                      ), // Xanh dương đậm
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                    child: const Text(
                      'TIẾP THEO',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourtSlot {
  final String court;
  final List<Slot> slots;

  CourtSlot({required this.court, required this.slots});
}

class Slot {
  final String time;
  final String status;

  Slot({required this.time, required this.status});
}
