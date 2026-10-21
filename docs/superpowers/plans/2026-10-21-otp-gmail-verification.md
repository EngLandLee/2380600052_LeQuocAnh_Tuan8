# Kế hoạch triển khai Xác Thực OTP Qua Gmail (Tuần 7)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triển khai hoàn chỉnh tính năng xác thực OTP 6 số qua Gmail khi đăng ký tài khoản cho cả Backend ASP.NET Core 8 Web API và ứng dụng di động Flutter.

**Architecture:** Sử dụng `IMemoryCache` để lưu trữ tạm thời thông tin đăng ký và mã OTP (hạn 5 phút, giới hạn 5 lần thử sai). `EmailService` gửi email HTML qua Gmail SMTP (`smtp.gmail.com:587`) và tự động fallback in khung OTP ra Terminal nếu chưa có mật khẩu ứng dụng Gmail. Frontend Flutter bổ sung màn hình `OtpVerificationScreen` với countdown timer 60s và cơ chế gửi lại mã OTP.

**Tech Stack:** C# .NET 8, `System.Net.Mail`, `Microsoft.Extensions.Caching.Memory`, Flutter Dart, `http`.

---

### Task 1: Backend Email & OTP Infrastructure

**Files:**
- Modify: `backend/appsettings.json`
- Create: `backend/Models/PendingRegistration.cs`
- Create: `backend/Models/DTOs/VerifyOtpModel.cs`
- Create: `backend/Services/IEmailService.cs`
- Create: `backend/Services/EmailService.cs`
- Create: `backend/Services/IOtpService.cs`
- Create: `backend/Services/OtpService.cs`
- Modify: `backend/Program.cs`

- [ ] **Step 1: Update appsettings.json with EmailSettings**
`backend/appsettings.json`: Thêm mục `"EmailSettings"`.

- [ ] **Step 2: Create PendingRegistration and VerifyOtpModel**
`backend/Models/PendingRegistration.cs` và `backend/Models/DTOs/VerifyOtpModel.cs`.

- [ ] **Step 3: Create IEmailService and EmailService**
`backend/Services/IEmailService.cs` và `backend/Services/EmailService.cs` (hỗ trợ gửi SMTP Gmail và Dev fallback console log).

- [ ] **Step 4: Create IOtpService and OtpService**
`backend/Services/IOtpService.cs` và `backend/Services/OtpService.cs` sử dụng `IMemoryCache`.

- [ ] **Step 5: Register services in Program.cs & verify build**
Đăng ký `AddMemoryCache()`, `AddScoped<IEmailService, EmailService>()`, `AddSingleton<IOtpService, OtpService>()` và chạy `dotnet build`.

---

### Task 2: Backend OTP Endpoints in AuthenticateController

**Files:**
- Modify: `backend/Controllers/AuthenticateController.cs`

- [ ] **Step 1: Add register-send-otp, verify-register-otp, and resend-otp endpoints**
Inject `IOtpService` và `IEmailService` vào `AuthenticateController` và thêm 3 actions.

- [ ] **Step 2: Build and verify backend**
Chạy `dotnet build`.

---

### Task 3: Backend Automated Verification for OTP Flow

**Files:**
- Create: `backend/tests/verify_otp_flow.py`

- [ ] **Step 1: Write Python script testing OTP flow**
Kiểm tra: Gửi OTP, Nhập sai OTP (thất bại), Nhập đúng OTP (thành công tạo User), Đăng nhập bằng tài khoản vừa tạo.

- [ ] **Step 2: Run verification with backend active**
Chạy `python3 backend/tests/verify_otp_flow.py` và xác nhận PASS 100%.

---

### Task 4: Frontend AuthService Updates for OTP

**Files:**
- Modify: `frontend/lib/services/auth_service.dart`

- [ ] **Step 1: Add registerSendOtp, verifyRegisterOtp, and resendOtp**
Cập nhật `AuthService` gọi các API OTP tương ứng.

---

### Task 5: Frontend OtpVerificationScreen & RegistrationScreen Flow

**Files:**
- Create: `frontend/lib/screens/otp_verification_screen.dart`
- Modify: `frontend/lib/screens/registration_screen.dart`

- [ ] **Step 1: Create OtpVerificationScreen**
Tạo giao diện nhập mã OTP 6 số, đồng hồ đếm ngược 60 giây, nút Gửi lại mã và nút Xác nhận.

- [ ] **Step 2: Update RegistrationScreen to navigate to OtpVerificationScreen**
Khi nhấn "Đăng ký" -> gọi `registerSendOtp` -> chuyển sang `OtpVerificationScreen`.

- [ ] **Step 3: Run flutter analyze and flutter test**
Đảm bảo 0 issues và vượt qua tất cả widget tests.
