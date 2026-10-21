# Design Document: Xác Thực OTP Đăng Ký Tài Khoản Qua Gmail (Tuần 7)

- **Ngày tạo:** 2026-10-21
- **Sinh viên:** Lê Quốc Anh (MSSV: 2380600052)
- **Học phần:** Lập trình thiết bị di động (LTDD) - Nâng cao xác thực OTP qua Gmail
- **Môi trường phát triển:** Linux, VS Code, .NET 8 SDK, Flutter 3.47+

---

## 1. Mục tiêu
Nâng cấp hệ thống Authentication của đồ án bằng cách bổ sung quy trình xác thực mã OTP qua Gmail khi đăng ký tài khoản mới:
1. Đảm bảo người dùng sở hữu địa chỉ email hợp lệ trước khi tài khoản được lưu vào CSDL Identity.
2. Tránh tình trạng người dùng nhập email giả mạo hoặc spam tài khoản rác.
3. Cung cấp cơ chế gửi email qua chuẩn SMTP của Gmail (`smtp.gmail.com:587`), kết hợp chế độ Dev Fallback (in mã OTP ra Console / Terminal) giúp kiểm thử linh hoạt.
4. Cung cấp giao diện Flutter chuyên nghiệp (`OtpVerificationScreen`) với đồng hồ đếm ngược (Countdown 60s) và chức năng gửi lại mã OTP.

---

## 2. Kiến trúc & Luồng hoạt động (Sequence Flow)

```
[Flutter App]                          [ASP.NET Web API]                       [Gmail SMTP Server]
      |                                        |                                        |
      | 1. POST /register-send-otp            |                                        |
      | (username, email, password, role)      |                                        |
      |--------------------------------------->|                                        |
      |                                        | 2. Kiểm tra tồn tại username/email     |
      |                                        | 3. Sinh OTP 6 số ngẫu nhiên            |
      |                                        | 4. Lưu cache OTP + DTO (5 phút)        |
      |                                        | 5. Gửi email chứa OTP                  |
      |                                        |--------------------------------------->|
      | 6. HTTP 200 OK                         |<---------------------------------------|
      |<---------------------------------------|                                        |
      |                                        |                                        |
      | [Mở OtpVerificationScreen]             |                                        |
      | (Đếm ngược 60s, chờ nhập OTP)          |                                        |
      |                                        |                                        |
      | 7. POST /verify-register-otp           |                                        |
      | (email, otp)                           |                                        |
      |--------------------------------------->|                                        |
      |                                        | 8. Kiểm tra OTP hợp lệ                 |
      |                                        | 9. Tạo User trong Identity             |
      |                                        | 10. Gán Role & EmailConfirmed = true   |
      | 11. HTTP 200 OK                        |                                        |
      |<---------------------------------------|                                        |
      |                                        |                                        |
      | [Chuyển về LoginScreen]                |                                        |
```

---

## 3. Đặc tả chi tiết Backend

### 3.1. Cấu hình `appsettings.json`
```json
"EmailSettings": {
  "SmtpServer": "smtp.gmail.com",
  "Port": 587,
  "SenderName": "LTDD Hutech Auth",
  "SenderEmail": "your-email@gmail.com",
  "AppPassword": "your-16-char-app-password",
  "EnableSsl": true
}
```

### 3.2. Cấu trúc lưu trữ OTP trong MemoryCache
- Key: `otp_register_{email}`
- Data Model:
  ```csharp
  public class PendingRegistration
  {
      public RegistrationModel RegistrationData { get; set; } = null!;
      public string OtpCode { get; set; } = string.Empty;
      public DateTime ExpiryTime { get; set; }
      public int FailedAttempts { get; set; } = 0;
  }
  ```
- Thời gian sống trong Cache: 5 phút.
- Giới hạn thử sai: 5 lần (vượt quá 5 lần sẽ vô hiệu hóa mã OTP để chống brute-force).

### 3.3. Dịch vụ gửi Email (`IEmailService` & `EmailService`)
- Dùng `System.Net.Mail.SmtpClient`.
- Khi `AppPassword` hoặc `SenderEmail` chưa được cấu hình thật:
  - Tự động fallback: In khung viền nổi bật chứa mã OTP ra Console / Terminal của Backend để kiểm thử ngay lập tức.
  - Khi có thông tin thật: Kết nối bảo mật TLS/SSL tới `smtp.gmail.com:587` và gửi thư HTML đẹp mắt.

### 3.4. API Endpoints mới trong `AuthenticateController`
1. `POST /api/Authenticate/register-send-otp`:
   - Input: `RegistrationModel` (Username, Email, Password, Initials, Role).
   - Kiểm tra `FindByNameAsync` và `FindByEmailAsync`.
   - Sinh OTP 6 chữ số, lưu vào Cache.
   - Gửi OTP qua `IEmailService`.
   - Output: `{ status: true, message: "Mã xác thực OTP đã được gửi về Gmail của bạn." }`.
2. `POST /api/Authenticate/verify-register-otp`:
   - Input: `VerifyOtpModel` (Email, Otp).
   - Kiểm tra mã OTP trong Cache:
     - Không tìm thấy hoặc hết hạn -> Trả về lỗi 400.
     - Sai mã OTP -> Tăng `FailedAttempts`, trả về lỗi 400.
     - Đúng mã OTP -> Lấy `RegistrationData`, gọi `UserManager.CreateAsync(user, password)`, gán Role, xóa Cache.
   - Output: `{ status: true, message: "Xác thực tài khoản thành công! Vui lòng đăng nhập." }`.
3. `POST /api/Authenticate/resend-otp`:
   - Input: `{ email: string }`.
   - Sinh mã OTP mới, gia hạn thêm 5 phút, gửi lại qua email.
   - Output: `{ status: true, message: "Đã gửi lại mã OTP mới về Gmail." }`.

---

## 4. Đặc tả chi tiết Frontend (Flutter)

### 4.1. Màn hình `RegistrationScreen`
- Người dùng điền đầy đủ form.
- Nhấn "Đăng Ký":
  - Hiển thị loading.
  - Gọi `AuthService.registerSendOtp(...)`.
  - Thành công: Chuyển sang `OtpVerificationScreen(email: ..., registrationData: ...)`.

### 4.2. Màn hình `OtpVerificationScreen`
- Hiển thị email người nhận (ví dụ `user@gmail.com`).
- Trường nhập mã OTP: 6 ô ký tự hoặc 1 ô text to rõ, bàn phím số `TextInputType.number`, độ dài max 6.
- Bộ đếm thời gian Countdown 60 giây (`Timer.periodic`):
  - Hiển thị: "Gửi lại mã sau (45s)".
  - Hết 60s: Nút "Gửi lại mã OTP" hoạt động.
- Nút "Xác Nhận & Hoàn Tất":
  - Gọi `AuthService.verifyRegisterOtp(email, otp)`.
  - Thành công: Hiển thị SnackBar thông báo thành công, `Navigator.pushAndRemoveUntil` đưa người dùng về `LoginScreen`.

---

## 5. Tiêu chí kiểm thử & Nghiệm thu
1. **Kiểm thử gửi OTP:** Điền form đăng ký, bấm gửi OTP -> API trả 200, Terminal backend hiển thị mã OTP rõ ràng.
2. **Kiểm thử nhập sai OTP:** Nhập mã sai -> Ứng dụng báo lỗi "Mã OTP không chính xác".
3. **Kiểm thử nhập đúng OTP:** Nhập mã đúng -> Ứng dụng báo "Xác thực thành công", tài khoản được tạo trong CSDL SQLite, chuyển sang màn hình Đăng nhập.
4. **Kiểm thử Đăng nhập sau khi xác thực OTP:** Dùng tài khoản vừa tạo đăng nhập thành công vào app với đúng vai trò (Admin hoặc User).
