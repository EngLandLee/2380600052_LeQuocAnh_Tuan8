# Kế hoạch Triển Khai WorkPulse AI: Chấm Công Thông Minh (Face ID, NFC, Video Call Nhóm & AI Energy Pulse)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển đổi và nâng cấp toàn diện dự án thành hệ thống chấm công thông minh thế hệ mới **WorkPulse AI** gồm: Quét khuôn mặt Face ID On-Device kèm phát hiện chớp mắt chống giả mạo (Google ML Kit), Quét thẻ từ NFC 1 chạm (`nfc_manager`), Chấm công kép Dual-Factor, Phân tích năng lượng và sức khỏe tinh thần AI Energy Pulse, Phòng họp Video Call nhóm ca trực, và Bảng điều khiển Quản trị viên theo dõi kiệt sức (burnout).

**Architecture:** Monorepo mở rộng từ nền tảng ASP.NET Core 8 Identity hiện tại. Backend bổ sung bảng `AttendanceRecords`, `MeetingRooms`, các controller `AttendanceController`, `MeetingController`. Frontend Flutter xây dựng giao diện chuẩn Executive Glassmorphism với camera scanner real-time, bộ đọc NFC và phòng họp nhóm nhiều người.

**Tech Stack:**
- Backend: C# .NET 8, ASP.NET Core Web API, EF Core SQLite, Identity, JWT Bearer.
- Frontend: Flutter 3.47+, Dart 3.13+, `google_mlkit_face_detection`, `camera`, `nfc_manager`, `fl_chart`, `shared_preferences`, `http`.

---

### Task 1: Backend Database & Models Expansion

**Files:**
- Modify: `backend/Models/User.cs`
- Create: `backend/Models/AttendanceRecord.cs`
- Create: `backend/Models/MeetingRoom.cs`
- Create: `backend/Models/DTOs/AttendanceDtos.cs`
- Modify: `backend/Data/ApplicationDbContext.cs`

- [ ] **Step 1: Update User model with NFC and Department**
`backend/Models/User.cs`: Thêm `NfcCardId`, `Department`, `AvatarUrl`.

- [ ] **Step 2: Create AttendanceRecord and MeetingRoom models**
`backend/Models/AttendanceRecord.cs` và `backend/Models/MeetingRoom.cs`.

- [ ] **Step 3: Create Attendance DTOs**
`backend/Models/DTOs/AttendanceDtos.cs`: `CheckInRequestDto`, `NfcCheckInDto`, `CreateRoomDto`, `RegisterNfcCardDto`.

- [ ] **Step 4: Update ApplicationDbContext and run Migration**
Thêm `DbSet<AttendanceRecord>` và `DbSet<MeetingRoom>`.
Chạy `dotnet ef migrations add AddAttendanceAndMeetingModels` và `dotnet ef database update`.

---

### Task 2: Backend Attendance & Meeting Controllers

**Files:**
- Create: `backend/Controllers/AttendanceController.cs`
- Create: `backend/Controllers/MeetingController.cs`

- [ ] **Step 1: Implement AttendanceController**
End-points: `POST check-in`, `POST check-in-nfc`, `POST check-out`, `GET my-history`, `GET all-today`, `GET energy-analytics`.

- [ ] **Step 2: Implement MeetingController**
End-points: `GET rooms`, `POST create-room`, `POST close-room`.

- [ ] **Step 3: Build backend and verify 0 errors**
Chạy `dotnet build`.

---

### Task 3: Backend Automated Verification for WorkPulse AI

**Files:**
- Create: `backend/tests/verify_workpulse_api.py`

- [ ] **Step 1: Write E2E test script**
Kiểm tra: Check-in Face ID + Energy Score, Chấm công bằng NFC UID, Check-out, Thống kê Energy Analytics, Tạo và lấy danh sách phòng họp nhóm.

- [ ] **Step 2: Run verification script**
Chạy `python3 backend/tests/verify_workpulse_api.py` và xác nhận PASS 100%.

---

### Task 4: Frontend Flutter Dependencies & Permissions Configuration

**Files:**
- Modify: `frontend/pubspec.yaml`
- Modify: `frontend/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add required packages to pubspec.yaml**
Thêm `camera`, `google_mlkit_face_detection`, `nfc_manager`, `intl`.

- [ ] **Step 2: Add hardware permissions to AndroidManifest.xml**
Cấp quyền `CAMERA`, `NFC`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`.

- [ ] **Step 3: Run flutter pub get**
Chạy `flutter pub get`.

---

### Task 5: Frontend Models & Services

**Files:**
- Create: `frontend/lib/models/attendance_record.dart`
- Create: `frontend/lib/models/meeting_room.dart`
- Create: `frontend/lib/services/attendance_service.dart`
- Create: `frontend/lib/services/meeting_service.dart`

- [ ] **Step 1: Implement Models**
`AttendanceRecord` và `MeetingRoom`.

- [ ] **Step 2: Implement Services**
`AttendanceService` và `MeetingService` tích hợp gọi REST API.

---

### Task 6: Frontend Face Check-in & AI Energy Pulse Screen

**Files:**
- Create: `frontend/lib/screens/face_checkin_screen.dart`

- [ ] **Step 1: Implement FaceCheckInScreen**
Camera Preview toàn màn hình với khung Oval radar animation, phát hiện góc quay mặt và chớp mắt (Liveness Anti-spoofing), tính toán `EnergyScore` & `MoodLabel`, gọi API check-in và popup chúc mừng.

---

### Task 7: Frontend NFC Badge Check-in Screen

**Files:**
- Create: `frontend/lib/screens/nfc_checkin_screen.dart`

- [ ] **Step 1: Implement NfcCheckInScreen**
Giao diện radar sóng lan tỏa, tự động lắng nghe chip NFC qua `nfc_manager`, rung phản hồi haptic, gửi UID thẻ lên API.

---

### Task 8: Frontend Group Video Call Screen

**Files:**
- Create: `frontend/lib/screens/group_video_call_screen.dart`

- [ ] **Step 1: Implement GroupVideoCallScreen**
Giao diện phòng họp ca trực dạng lưới camera đa thành viên, điều khiển Mic/Cam/Đổi góc camera/Rời phòng.

---

### Task 9: Modern Executive UI - Dashboard & Admin Hub

**Files:**
- Modify: `frontend/lib/screens/main_screen.dart`
- Modify: `frontend/lib/screens/admin_screen.dart`

- [ ] **Step 1: Redesign MainScreen for Employees**
Action Hub: Nút Quét Khuôn Mặt, Chạm Thẻ NFC, Vào Họp Ca Video; Thẻ đo chỉ số năng lượng Well-being; Lịch sử chấm công.

- [ ] **Step 2: Redesign AdminScreen for Managers**
Giám sát chấm công real-time hôm nay, Biểu đồ sức khỏe/cảnh báo kiệt sức (Burnout alert), Quản lý tạo phòng họp ca trực.

---

### Task 10: Final Verification & Integration

**Files:**
- Modify: `frontend/test/widget_test.dart`

- [ ] **Step 1: Run flutter analyze and flutter test**
Đảm bảo 0 issues và vượt qua tất cả tests.

- [ ] **Step 2: Final End-to-End System Test**
Chạy đồng thời backend và frontend, xác nhận toàn bộ hệ thống hoạt động hoàn hảo.
