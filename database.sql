	CREATE DATABASE QuanLySanCauLong;
	GO
	USE QuanLySanCauLong;
	GO

	-- Bảng khách hàng
	CREATE TABLE KhachHang (
		MaKhachHang INT IDENTITY(1,1) PRIMARY KEY,
		TenKhachHang NVARCHAR(100) NOT NULL,
		SoDienThoai NVARCHAR(20),
		Email NVARCHAR(100)
	);
	GO

	-- Bảng sân
	CREATE TABLE San (
		MaSan INT IDENTITY(1,1) PRIMARY KEY,
		TenSan NVARCHAR(50) NOT NULL, -- Ví dụ: "Sân 1"
		TinhTrang NVARCHAR(20) DEFAULT N'đang hoạt động' -- hoạt động, bảo trì, khóa
	);
	GO

	-- Bảng đặt sân
	CREATE TABLE DatSan (
		MaDatSan INT IDENTITY(1,1) PRIMARY KEY,
		MaKhachHang INT NOT NULL FOREIGN KEY REFERENCES KhachHang(MaKhachHang),
		MaSan INT NOT NULL FOREIGN KEY REFERENCES San(MaSan),
		NgayDat DATE NOT NULL,
		GioBatDau TIME NOT NULL,
		ThoiLuong INT NOT NULL, -- đơn vị: phút
		TrangThai NVARCHAR(20) DEFAULT N'đã đặt' -- đã đặt, đã hủy, đã hoàn thành
	);
	GO

	-- Bảng hóa đơn
	CREATE TABLE HoaDon (
		MaHoaDon INT IDENTITY(1,1) PRIMARY KEY,
		MaDatSan INT UNIQUE FOREIGN KEY REFERENCES DatSan(MaDatSan),
		SoTien DECIMAL(10,2) NOT NULL,
		ThoiGianThanhToan DATETIME,
		PhuongThucThanhToan NVARCHAR(50), -- tiền mặt, chuyển khoản, ví điện tử
		TrangThai NVARCHAR(20) DEFAULT N'chưa thanh toán' -- đã thanh toán, chưa thanh toán, đã hủy
	);
	GO

	-- Bảng lịch sử hủy
	CREATE TABLE HuyDatSan (
		MaHuy INT IDENTITY(1,1) PRIMARY KEY,
		MaDatSan INT FOREIGN KEY REFERENCES DatSan(MaDatSan),
		ThoiGianHuy DATETIME DEFAULT GETDATE(),
		LyDo NVARCHAR(255)
	);
	GO

	-- Bảng phản hồi từ khách
	CREATE TABLE PhanHoi (
		MaPhanHoi INT IDENTITY(1,1) PRIMARY KEY,
		MaKhachHang INT FOREIGN KEY REFERENCES KhachHang(MaKhachHang),
		MaSan INT FOREIGN KEY REFERENCES San(MaSan),
		NoiDung NVARCHAR(500),
		DanhGia INT CHECK (DanhGia BETWEEN 1 AND 5),
		ThoiGianGopY DATETIME DEFAULT GETDATE()
	);
	GO

	-- Bảng tài khoản quản trị
	CREATE TABLE NguoiDung (
		MaNguoiDung INT IDENTITY(1,1) PRIMARY KEY,
		TenDangNhap NVARCHAR(50) NOT NULL UNIQUE,
		MatKhauHash NVARCHAR(255) NOT NULL,
		VaiTro NVARCHAR(20) DEFAULT N'nhân viên' -- nhân viên, quản trị
	);
	GO

	-- Bảng ghi log hoạt động
	CREATE TABLE NhatKyHoatDong (
		MaNhatKy INT IDENTITY(1,1) PRIMARY KEY,
		MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung),
		HanhDong NVARCHAR(100),
		BangTacDong NVARCHAR(50),
		MaBanGhi INT,
		ThoiGian DATETIME DEFAULT GETDATE(),
		MoTa NVARCHAR(255)
	);
	GO

	CREATE TABLE PhienDangNhap (
		MaPhien INT IDENTITY(1,1) PRIMARY KEY,
		MaNguoiDung INT NOT NULL FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung),
		Token NVARCHAR(255) NOT NULL,
		ThoiGianTao DATETIME DEFAULT GETDATE(),
		HetHan DATETIME NOT NULL,
		DiaChiIP NVARCHAR(50),
		ThietBi NVARCHAR(100)
	);
	GO

	-- Thêm khách hàng mẫu
INSERT INTO KhachHang (TenKhachHang, SoDienThoai, Email)
VALUES 
(N'Nguyễn Văn A', '0912345678', 'vana@example.com'),
(N'Trần Thị B', '0987654321', 'thib@example.com');

-- Thêm sân mẫu
INSERT INTO San (TenSan, TinhTrang)
VALUES 
(N'Sân 1', N'đang hoạt động'),
(N'Sân 2', N'đang hoạt động'),
(N'Sân 3', N'bảo trì'),
(N'Sân 4', N'khóa');

-- Thêm tài khoản người dùng mẫu (mật khẩu để raw, bạn nên hash khi dùng thực tế)
INSERT INTO NguoiDung (TenDangNhap, MatKhauHash, VaiTro)
VALUES 
(N'admin', N'admin123', N'quản trị'),
(N'staff1', N'staff123', N'nhân viên');

select * from DatSan
INSERT INTO DatSan(MaKhachHang, MaSan, NgayDat, GioBatDau, ThoiLuong, TrangThai)
VALUES (1, 1, '2025-10-17', CAST('12:00:00' AS TIME), 2, N'đã đặt');
