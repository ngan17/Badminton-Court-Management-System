import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ly_cau_long/DAO/giaidauservice.dart';
import 'chitietgiadau.dart';

class GiaidauScreen extends StatefulWidget {
  final String? vaiTro;
  const GiaidauScreen({super.key, this.vaiTro});

  @override
  State<GiaidauScreen> createState() => _ThemGiaiDauScreenState();
}

class _ThemGiaiDauScreenState extends State<GiaidauScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tenGiaiController = TextEditingController();
  final TextEditingController _moTaController = TextEditingController();
  final TextEditingController _diaDiemController = TextEditingController();
  final TextEditingController _giaiThuongController = TextEditingController();
  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;

  late Future<List> _futureGiaiDau;

  @override
  void initState() {
    super.initState();
    _futureGiaiDau = GiaiDauService.fetchGiaiDau();
  }

  Future<void> _chonNgayBatDau() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _ngayKetThuc = picked);
    }
  }

  void _luuThongTin() async {
    if (_formKey.currentState!.validate()) {
      try {
        await GiaiDauService.insertGiaiDau(
          tenGiai: _tenGiaiController.text,
          ngayBatDau: _ngayBatDau ?? DateTime.now(),
          ngayKetThuc:
              _ngayKetThuc ?? DateTime.now().add(const Duration(days: 1)),
          diaDiem: _diaDiemController.text,
          moTa: _moTaController.text.isEmpty ? null : _moTaController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu giải đấu thành công!'),
            backgroundColor: Color(0xFF1976D2),
          ),
        );

        setState(() {
          _futureGiaiDau = GiaiDauService.fetchGiaiDau();
          _tenGiaiController.clear();
          _moTaController.clear();
          _diaDiemController.clear();
          _giaiThuongController.clear();
          _ngayBatDau = null;
          _ngayKetThuc = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu giải đấu: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý Giải Đấu',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('Assets/panelgiai2.jpg'),
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF64B5F6), Colors.white],
          ),
        ),
        child: FutureBuilder<List>(
          future: _futureGiaiDau,
          builder: (context, snapshot) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  if (widget.vaiTro == 'Quản trị' ||
                      widget.vaiTro == 'Nhân viên')
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: TabBar(
                        tabs: [
                          Tab(
                            child: Text(
                              'Danh sách',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 21, 5, 5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Tab(
                            child: Text(
                              'Thêm mới',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 35, 5, 5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: const Color(0xFF1976D2),
                        indicatorWeight: 3,
                      ),
                    )
                  else
                    Container(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDanhSach(snapshot),
                        if (widget.vaiTro == 'Quản trị' ||
                            widget.vaiTro == 'Nhân viên')
                          _buildForm()
                        else
                          Center(
                            child: Text(
                              'Bạn không có quyền truy cập!',
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDanhSach(AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: CircularProgressIndicator(color: const Color(0xFF1976D2)),
      );
    }
    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Lỗi: ${snapshot.error}',
          style: TextStyle(color: Colors.red.shade600),
        ),
      );
    }
    final data = snapshot.data!;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Icon(
              Icons.sports_tennis,
              color: const Color(0xFF1976D2),
              size: 30,
            ),
            title: Text(
              item['tenGiai'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 13, 4, 4),
              ),
            ),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['ngayBatDau']))} đến ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['ngayKetThuc']))}',
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 37, 40, 110),
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: const Color(0xFF1976D2)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GiaiDauDetailScreen(giaiDau: item),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm Giải Đấu Mới',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                style: const TextStyle(
                  color: Colors.white,
                ), // Text fill màu trắng
                controller: _tenGiaiController,
                decoration: InputDecoration(
                  labelText: 'Tên giải',
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 17, 8, 8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF1976D2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Nhập tên giải' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(
                  color: Colors.white,
                ), // Text fill màu trắng
                controller: _moTaController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF1976D2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _chonNgayBatDau,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _ngayBatDau == null
                              ? 'Chọn ngày bắt đầu'
                              : DateFormat('dd/MM/yyyy').format(_ngayBatDau!),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 19, 16, 7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _chonNgayKetThuc,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _ngayKetThuc == null
                              ? 'Chọn ngày kết thúc'
                              : DateFormat('dd/MM/yyyy').format(_ngayKetThuc!),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 18, 14, 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(
                  color: Colors.white,
                ), // Text fill màu trắng
                controller: _diaDiemController,
                decoration: InputDecoration(
                  labelText: 'Địa điểm tổ chức',
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF1976D2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(
                  color: Colors.white,
                ), // Text fill màu trắng
                controller: _giaiThuongController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Giải thưởng (VNĐ)',
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF1976D2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _luuThongTin,
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text(
                    'Lưu giải đấu',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: const Color.fromARGB(255, 29, 8, 8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                    shadowColor: const Color(0xFF1565C0).withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
