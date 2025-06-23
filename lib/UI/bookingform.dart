import 'package:do_an_quan_ly_cau_long/DAO/ipconfigsetting.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../UI/thanhtoan.dart';

class VisualBookingScreen extends StatefulWidget {
  final int? maKhachHang;
  final String? tenKhachHang;
  final int? maNguoiDung;
  final String? vaiTro;

  const VisualBookingScreen({
    super.key,
    this.maKhachHang,
    this.tenKhachHang,
    this.maNguoiDung,
    this.vaiTro,
  });

  @override
  State<VisualBookingScreen> createState() => _VisualBookingScreenState();
}

class _VisualBookingScreenState extends State<VisualBookingScreen> {
  String? selectedCourt;
  String? selectedHour;
  DateTime selectedDate = DateTime.now();
  double selectedDuration = 1;
  List<CourtSlot> courtSlots = [];

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

  int? get maKhachHang => widget.maKhachHang;
  String get tenKhachHang => widget.tenKhachHang ?? "";
  int? get maNguoiDung => widget.maNguoiDung;

  @override
  void initState() {
    super.initState();
    fetchSlots();
  }

  double calculateBookingCost(
    DateTime ngayDat,
    String gioBatDau,
    int thoiLuong,
  ) {
    int startHour;
    try {
      startHour = int.parse(gioBatDau.split(':')[0]);
      if (startHour < 0 || startHour > 23)
        throw FormatException("Giờ bắt đầu không hợp lệ");
    } catch (e) {
      print('Lỗi định dạng giờ: $e');
      return 0.0;
    }

    if (thoiLuong < 1) thoiLuong = 1; // Đảm bảo thời lượng không âm

    double totalCost = 0.0;
    final dayOfWeek = ngayDat.weekday;
    final isWeekend = dayOfWeek == 6 || dayOfWeek == 7;

    for (int hour = startHour; hour < startHour + thoiLuong; hour++) {
      int currentHour = hour % 24;
      double pricePerHour;

      if (currentHour >= 18 || currentHour < 5) {
        pricePerHour = isWeekend ? 110000.0 : 100000.0; // 18:00-05:00
      } else if (currentHour >= 5 && currentHour < 10) {
        pricePerHour = isWeekend ? 80000.0 : 70000.0; // 05:00-10:00
      } else {
        pricePerHour = isWeekend ? 140000.0 : 100000.0; // 10:00-18:00
      }

      totalCost += pricePerHour;
      print('Giờ $currentHour: Giá $pricePerHour, Tổng tạm: $totalCost');
    }

    print('Tổng chi phí: $totalCost');
    return totalCost;
  }

  Future<void> fetchSlots() async {
    final url = Uri.parse(
      '${Ipconfigsetting.ip}/api/DatSans?date=${selectedDate.toIso8601String().split('T')[0]}',
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
                      selectedDate.toIso8601String().split('T')[0] &&
                  booking['gioBatDau'] != null) {
                final startHour = int.parse(
                  booking['gioBatDau'].toString().split(":")[0],
                );
                final duration = booking['thoiLuong'];
                final endHour = startHour + duration - 1;

                if (h >= startHour && h <= endHour) {
                  if (booking['maKhachHang'] == maKhachHang) {
                    status = 'booked';
                  } else {
                    status = 'locked';
                  }
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
    if (isSelected) return const Color(0xFF42A5F5); // Softer blue for selection
    if (status == 'booked') return Colors.red;
    if (status == 'locked') return Colors.grey;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Hủy quá trình đặt sân khi nhấn Back
        if (selectedCourt != null && selectedHour != null) {
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
          title: const Text('Đặt lịch ngày trực quan'),
          backgroundColor: const Color(0xFF42A5F5), // Softer blue
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
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
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
                        backgroundColor: const Color(0xFF42A5F5), // Softer blue
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
                  // Cột cố định cho tên sân
                  Container(
                    width: 60,
                    color: const Color(0xFFB3E5FC), // Softer light blue
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
                        border: TableBorder.all(color: Colors.blueGrey[300]!),
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
                                            color: Colors.blueGrey[300]!,
                                          ),
                                        ),
                                        child:
                                            slot.status == 'available'
                                                ? null
                                                : Icon(
                                                  slot.status == 'booked'
                                                      ? Icons.close
                                                      : Icons.lock,
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
                    activeColor: const Color(0xFF42A5F5), // Softer blue
                    inactiveColor: Colors.blueGrey[300], // Softer grey
                    onChanged:
                        (value) => setState(() => selectedDuration = value),
                  ),
                  ElevatedButton(
                    onPressed:
                        selectedCourt != null && selectedHour != null
                            ? () async {
                              if (maKhachHang == null &&
                                  widget.vaiTro == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Bạn cần đăng nhập để đặt sân",
                                    ),
                                  ),
                                );
                                return;
                              }

                              final selectedStartHour = int.parse(
                                selectedHour!.split(':')[0],
                              );
                              final bookingStartTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedStartHour,
                              );

                              final selectedEndTime = bookingStartTime.add(
                                Duration(hours: selectedDuration.toInt()),
                              );

                              if (bookingStartTime.isBefore(DateTime.now())) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Thời gian bắt đầu phải sau hiện tại!",
                                    ),
                                  ),
                                );
                                return;
                              }

                              final hoursToCheck = List.generate(
                                selectedDuration.toInt(),
                                (i) =>
                                    '${(selectedStartHour + i).toString().padLeft(2, '0')}:00',
                              );

                              final selectedCourtSlot = courtSlots.firstWhere(
                                (c) => c.court == selectedCourt,
                              );

                              final isOverlap =
                                  selectedCourtSlot.slots
                                      .where(
                                        (s) =>
                                            hoursToCheck.contains(s.time) &&
                                            s.status != 'available',
                                      )
                                      .isNotEmpty;

                              if (isOverlap) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Khung giờ bạn chọn đã có người đặt!",
                                    ),
                                  ),
                                );
                                return;
                              }

                              final court = courts.firstWhere(
                                (c) => c['tenSan'] == selectedCourt,
                              );

                              final date = DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate);
                              final time =
                                  "${selectedHour!.padLeft(2, '0')}:00";

                              final bookingData = {
                                "maKhachHang": maKhachHang,
                                "maSan": court['maSan'],
                                "ngayDat": date,
                                "gioBatDau": time,
                                "thoiLuong": selectedDuration.toInt(),
                                "trangThai": "Chờ xác nhận",
                              };

                              final tongTien = calculateBookingCost(
                                selectedDate,
                                selectedHour!,
                                selectedDuration.toInt(),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PaymentInfoScreen(
                                        maKhachHang: maKhachHang!,
                                        maSan: court['maSan'],
                                        ngayDat: date,
                                        gioBatDau: time,
                                        thoiLuong: selectedDuration.toInt(),
                                        tongtien: tongTien,
                                        maDatSan:
                                            null, // maDatSan sẽ được tạo ở PaymentInfoScreen
                                      ),
                                ),
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5), // Softer blue
                    ),
                    child: const Text('TIẾP THEO'),
                  ),
                  const SizedBox(height: 16),
                  // Thêm bảng giá
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Table(
                        border: TableBorder.all(color: Colors.blueGrey[300]!),
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
                                color: const Color(0xFFBBDEFB), // Lighter blue
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
                                color: const Color(0xFFBBDEFB), // Lighter blue
                                child: const Text(
                                  'T7-CN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                height: 50, // Tăng chiều cao hàng
                                alignment: Alignment.center,
                                color: const Color(0xFFBBDEFB), // Lighter blue
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
