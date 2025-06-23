import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ly_cau_long/DAO/giaidauservice.dart';

class ThemGiaiDauScreen extends StatefulWidget {
  const ThemGiaiDauScreen({super.key});

  @override
  State<ThemGiaiDauScreen> createState() => _ThemGiaiDauScreenState();
}

class _ThemGiaiDauScreenState extends State<ThemGiaiDauScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tenGiaiController = TextEditingController();
  final TextEditingController _moTaController = TextEditingController();
  final TextEditingController _diaDiemController = TextEditingController();
  final TextEditingController _giaiThuongController = TextEditingController();
  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;

  Future<void> _chonNgayBatDau() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _ngayBatDau = picked);
    }
  }

  Future<void> _chonNgayKetThuc() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngayBatDau ?? DateTime.now(),
      firstDate: _ngayBatDau ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _ngayKetThuc = picked);
    }
  }

  void _luuThongTin() {
    if (_formKey.currentState!.validate()) {
      final giaiDau = {
        'tenGiai': _tenGiaiController.text,
        'moTa': _moTaController.text,
        'ngayBatDau': _ngayBatDau?.toIso8601String().split('T').first,
        'ngayKetThuc': _ngayKetThuc?.toIso8601String().split('T').first,
        'diaDiem': _diaDiemController.text,
        'giaiThuong': double.tryParse(_giaiThuongController.text) ?? 0,
        'trangThai': 'Sắp diễn ra',
      };

      // Gửi API tại đây nếu có
      print('Lưu giải đấu: $giaiDau');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã lưu giải đấu!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm Giải Đấu'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _tenGiaiController,
                  decoration: InputDecoration(labelText: 'Tên giải'),
                  validator: (value) => value!.isEmpty ? 'Nhập tên giải' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _moTaController,
                  decoration: InputDecoration(labelText: 'Mô tả'),
                  maxLines: 3,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _chonNgayBatDau,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Ngày bắt đầu',
                          ),
                          child: Text(
                            _ngayBatDau == null
                                ? 'Chọn ngày'
                                : DateFormat('dd/MM/yyyy').format(_ngayBatDau!),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _chonNgayKetThuc,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Ngày kết thúc',
                          ),
                          child: Text(
                            _ngayKetThuc == null
                                ? 'Chọn ngày'
                                : DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_ngayKetThuc!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _diaDiemController,
                  decoration: InputDecoration(labelText: 'Địa điểm tổ chức'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _giaiThuongController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Giải thưởng (VNĐ)'),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _luuThongTin,
                  icon: Icon(Icons.save),
                  label: Text('Lưu giải đấu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
