# Design Document: Ứng Dụng Chấm Công Thông Minh WorkPulse AI (Face ID, NFC, Video Call Nhóm & AI Energy Pulse)

- **Ngày tạo:** 2026-10-21
- **Sinh viên:** Lê Quốc Anh (MSSV: 2380600052)
- **Học phần:** Lập trình thiết bị di động (LTDD) - Đồ án Ứng dụng Doanh nghiệp Nâng cao
- **Môi trường phát triển:** Linux (VS Code), .NET 8 SDK, Flutter 3.47+, SQLite, Google ML Kit, NFC, WebRTC

---

## 1. Tổng quan & Tầm nhìn sản phẩm
**WorkPulse AI** là giải pháp chấm công và quản lý ca trực doanh nghiệp thế hệ mới, giải quyết triệt để các hạn chế của phần mềm chấm công truyền thống:
1. **Chống gian lận đa tầng:** Kết hợp nhận diện khuôn mặt AI với thuật toán phát hiện người thật 3D Liveness (chớp mắt, cử động) và thẻ từ vật lý NFC.
2. **Chấm công 1 chạm siêu tốc (NFC Tap):** Quẹt thẻ nhân viên qua chip NFC mặt lưng điện thoại trong 0.2 giây.
3. **Chế độ Chấm công kép (Dual-Factor Security):** Bắt buộc chạm thẻ NFC kết hợp quét khuôn mặt (loại bỏ 100% tình trạng chấm công hộ).
4. **Tính năng độc quyền - AI Mood & Energy Pulse:** Phân tích độ tươi tắn và mức năng lượng buổi sáng của nhân viên khi check-in, giúp ban quản lý thấu hiểu sức khỏe tinh thần và phòng ngừa kiệt sức (burnout) trong ca làm việc.
5. **Gọi Video Nhóm Ca Trực (Shift Video Standup):** Tích hợp phòng họp video call nhiều người tham gia để giao ban đầu ca hoặc báo cáo cuối ngày ngay trong app mà không cần mở Zoom/Teams.
6. **Giao diện hiện đại (Modern Executive UI):** Thiết kế thẻ bóng mờ Glassmorphic, tone màu Indigo & Emerald, trải nghiệm mượt mà, trực quan.

---

## 2. Kiến trúc Hệ thống & Cơ sở dữ liệu

```
[Flutter Mobile Client]
  ├── Module 1: Camera & Google ML Kit (Face Detection, Liveness, Smile & Blink Tracking)
  ├── Module 2: NFC Manager (Hardware Badge Reader & UID Extractor)
  ├── Module 3: WebRTC / Video Room (Group Mesh / Audio-Video Conference)
  ├── Module 4: UI Engine (Executive Dashboard, Timekeeping Charts, Well-being Meter)
         │
         ▼ (HTTP JSON REST + Bearer JWT Token)
[ASP.NET Core 8 Web API]
  ├── AuthenticateController (Identity, JWT, Gmail OTP)
  ├── AttendanceController (Face/NFC Check-in, Check-out, History, Well-being Metrics)
  ├── MeetingController (Rooms, Participant Management, Conference Handshake)
  ├── UserController (NFC Badge Association, Profile)
         │
         ▼ (Entity Framework Core 8)
[SQLite Database - app.db]
  ├── AspNetUsers (IdentityUser + Initials, NfcCardId, Department)
  ├── AttendanceRecords (UserId, InTime, OutTime, Method, EnergyScore, Mood, LivenessScore)
  └── MeetingRooms (RoomCode, Title, HostUserId, CreatedAt, IsActive)
```

### 2.1. Cấu trúc CSDL chi tiết

#### Model `User` (Mở rộng từ IdentityUser):
- `string? Initials`: Ký tự viết tắt.
- `string? NfcCardId`: Mã định danh thẻ từ NFC gắn với nhân viên (UID ví dụ: `04:A1:B2:C3`).
- `string? Department`: Phòng ban / Ca trực (ví dụ: "Kỹ thuật", "Kinh doanh", "Vận hành").

#### Model `AttendanceRecord`:
- `int Id`: Khóa chính.
- `string UserId`: Khóa ngoại liên kết `User`.
- `DateTime CheckInTime`: Thời gian vào ca.
- `DateTime? CheckOutTime`: Thời gian kết thúc ca.
- `string Method`: Phương thức chấm công (`"FaceID"`, `"NFC"`, `"Dual_NFC_Face"`).
- `double EnergyScore`: Điểm năng lượng (0.0 - 100.0%).
- `string MoodLabel`: Nhãn cảm xúc (`"Tươi tắn"`, `"Tích cực"`, `"Bình thường"`, `"Mệt mỏi"`).
- `bool IsLivenessVerified`: Đã xác thực người thật qua cử động (chống ảnh chụp).
- `string? DeviceInfo`: Tên thiết bị chấm công.
- `string? Notes`: Ghi chú chấm công.

#### Model `MeetingRoom`:
- `int Id`: Khóa chính.
- `string RoomCode`: Mã phòng họp duy nhất (ví dụ: `SHIFT-A1-2026`).
- `string Title`: Tiêu đề buổi giao ban / họp nhóm.
- `string HostUserId`: Người tạo phòng.
- `DateTime CreatedAt`: Thời điểm khởi tạo.
- `bool IsActive`: Phòng còn hoạt động hay đã đóng.

---

## 3. Đặc tả tính năng cốt lõi (Core Features)

### 3.1. Chấm công Khuôn mặt Face ID & 3D Liveness
- **Công nghệ:** Google ML Kit Face Detection chạy On-Device (tốc độ cao, riêng tư).
- **Cơ chế chống giả mạo ảnh chụp (Anti-Spoofing):**
  - Quét thời gian thực (Real-time tracking) với khung oval dẫn hướng.
  - Phân tích góc quay đầu (Euler Y, Euler Z): yêu cầu nhìn thẳng.
  - Kiểm tra chớp mắt: Giá trị `leftEyeOpenProbability` và `rightEyeOpenProbability` chuyển đổi động từ mở (> 0.7) sang nhắm (< 0.25).
  - Khi hoàn thành chuỗi cử động hợp lệ -> Chụp frame, tính điểm liveness và phát âm thanh xác nhận "Tít" thành công.

### 3.2. Chấm công Thẻ từ NFC (NFC Badge Check-in)
- **Công nghệ:** Thư viện `nfc_manager` tương thích tiêu chuẩn ISO/IEC 14443 Type A/B, NDEF.
- **Quy trình chấm công:**
  - Nhân viên chọn "Chấm công thẻ NFC" (hoặc tự động kích hoạt khi chạm thẻ).
  - Màn hình hiển thị radar sóng NFC xoay vòng.
  - Chạm thẻ vào mặt lưng máy -> Đọc UID thẻ -> Gửi lên API `POST /api/Attendance/check-in-nfc`.
  - Thiết bị rung nhẹ (Haptic feedback) và hiển thị thông báo "Xin chào [Tên], Chấm công thành công!".
- **Đăng ký thẻ mới:** Cho phép Admin hoặc nhân viên tự gán thẻ từ chưa đăng ký vào tài khoản bằng 1 chạm.

### 3.3. Chế độ Chấm công Siêu bảo mật (Dual-Factor NFC + Face)
- **Bước 1:** Chạm thẻ nhân viên NFC để xác định danh tính chủ thẻ.
- **Bước 2:** Camera tự động kích hoạt để nhận diện khuôn mặt và xác thực liveness.
- Loại bỏ hoàn toàn 100% tình trạng "quẹt thẻ hộ" hoặc "mượn thẻ của đồng nghiệp".

### 3.4. AI Mood & Energy Pulse (Sức khỏe & Năng lượng nhân viên)
- **Thuật toán phân tích:**
  - Trích xuất các chỉ số từ Google ML Kit: `smilingProbability` (độ tươi cười), `headEulerAngle` (độ thẳng thắn/tập trung), độ mở của mắt.
  - Công thức tính điểm `EnergyScore`:
    $$\text{EnergyScore} = \text{round}(40 + (\text{Smile} \times 35) + (\text{EyeOpen} \times 25))$$
  - Phân loại tâm trạng (`MoodLabel`):
    - $\ge 80\%$: *"Tràn đầy năng lượng"* (Xanh lục sáng).
    - $60\% - 79\%$: *"Tươi tắn, sẵn sàng"* (Xanh dương).
    - $40\% - 59\%$: *"Bình thường"* (Vàng cam).
    - $< 40\%$: *"Mệt mỏi / Cần nghỉ ngơi"* (Đỏ cam).
- **Dashboard quản trị:** Biểu đồ xu hướng năng lượng phòng ban, cảnh báo nhân viên có chỉ số mệt mỏi liên tiếp 3 ngày để quản lý có kế hoạch hỗ trợ.

### 3.5. Gọi Video Nhóm Ca Trực (Shift Video Standup)
- **Phòng họp nhóm nội bộ:**
  - Quản lý tạo phòng họp theo ca trực (ví dụ: *"Giao ban ca sáng 21/10"*).
  - Nhân viên chỉ cần nhấn "Tham gia họp ca" trên Dashboard là vào phòng ngay.
- **Giao diện phòng họp:**
  - Bố cục lưới camera (Responsive Grid View) hỗ trợ hiển thị đồng thời nhiều thành viên.
  - Hiển thị tên và chức vụ của từng người trên khung video.
  - Thanh công cụ điều khiển phía dưới: Bật/Tắt Micro, Bật/Tắt Camera, Chuyển Camera Trước/Sau, Rời phòng họp.

---

## 4. Đặc tả Giao diện & Trải nghiệm Người dùng (UI/UX)

1. **Dashboard Nhân Viên (`HomeScreen`):**
   - Header: Lời chào, ảnh đại diện, chức vụ, trạng thái ca làm việc hiện tại (Chưa vào ca / Đang trong ca).
   - Card chính (Action Hub): 
     - Nút lớn: **"Quét Khuôn Mặt (Face Check-in)"** (gradient Xanh Dương - Tím).
     - Nút: **"Chạm Thẻ NFC"** (gradient Xanh Ngọc - Emerald).
     - Nút: **"Họp Ca Video Trực Tuyến"** (gradient Cam - Đỏ san hô).
   - Widget **Well-being Pulse**: Đồng hồ kim đo năng lượng hôm nay kèm câu chúc truyền cảm hứng.
   - Thống kê tuần: Số giờ làm việc, số ngày đi đúng giờ.
2. **Màn hình Quét Mặt (`FaceCheckInScreen`):**
   - Camera toàn màn hình với vòng radar quét xanh lơ dạng sci-fi.
   - Thanh hướng dẫn động: *"Vui lòng nhìn thẳng"*, *"Hãy chớp mắt nhẹ"*, *"Tuyệt vời! Đang ghi nhận..."*.
3. **Màn hình Quẹt Thẻ (`NfcCheckInScreen`):**
   - Animation sóng lan tỏa (Ripple wave animation), icon thẻ từ chạm vào điện thoại.
4. **Màn hình Họp Video (`GroupVideoCallScreen`):**
   - Bố cục tối màu (Dark mode) chuẩn điện ảnh, góc bo tròn, mượt mà.
5. **Dashboard Quản Trị Viên (`AdminScreen`):**
   - Danh sách theo thời gian thực ai đã check-in sáng nay.
   - Bảng phân tích chỉ số năng lượng toàn công ty.
   - Quản lý gán thẻ NFC cho nhân viên và mở phòng họp mới.

---

## 5. Kế hoạch Kiểm thử & Nghiệm thu
1. **Kiểm thử Face Check-in & Liveness:** Thử đưa ảnh tĩnh trước camera (phải từ chối), thực hiện chớp mắt (ghi nhận thành công).
2. **Kiểm thử NFC:** Chạm thẻ NFC vào mặt lưng máy (đọc đúng UID và lưu lịch sử công).
3. **Kiểm thử Dual-Factor:** Kết hợp NFC + Face ID xác nhận đầy đủ 2 bước.
4. **Kiểm thử Video Call Nhóm:** Vào phòng họp video, kiểm tra truyền hình ảnh, âm thanh, tắt mở mic/cam ổn định.
5. **Kiểm thử AI Energy Score:** Đo thử nhiều biểu cảm khác nhau để xác nhận công thức tính điểm và hiển thị chuẩn xác trên dashboard.
