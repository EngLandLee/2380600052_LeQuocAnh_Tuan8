# Design Document: Hệ thống Authentication ASP.NET Core Identity & Flutter Client (Tuần 7)

- **Ngày tạo:** 2026-10-21
- **Sinh viên:** Lê Quốc Anh (MSSV: 2380600052)
- **Học phần:** Lập trình thiết bị di động (LTDD) - Bài thực hành Tuần 7 V2
- **Môi trường phát triển:** Linux (Ubuntu), Visual Studio Code (VS Code), .NET 8 SDK, Flutter 3.47+

---

## 1. Tổng quan mục tiêu
Xây dựng một hệ thống hoàn chỉnh từ Backend đến Frontend giải quyết toàn bộ yêu cầu trong tài liệu bài giảng Tuần 7 và các bài tập về nhà của giảng viên:
1. **Backend API (.NET 8 Web API)**:
   - Sử dụng ASP.NET Core Identity để quản lý người dùng, mật khẩu mã hóa, vai trò (`Admin`, `User`).
   - Sử dụng JWT Bearer token để xác thực và ủy quyền (Authentication & Authorization).
   - Cơ sở dữ liệu: SQLite (`app.db`) với Entity Framework Core 8, đảm bảo chạy nhẹ nhàng và độc lập trên Linux.
   - Thêm nghiệp vụ Quản lý Danh mục (Category) & Sản phẩm (Product) có phân quyền Admin.
   - Ràng buộc dữ liệu: Khi xóa Danh mục, sản phẩm thuộc danh mục đó tự động cập nhật về `null` (không bị xóa).
2. **Frontend App (Flutter)**:
   - Giao diện Đăng ký (`RegistrationScreen`) và Đăng nhập (`LoginScreen`).
   - Tích hợp `flutter_dotenv` để quản lý `BASE_URL` qua file `.env`.
   - Tích hợp `jwt_decoder` để giải mã token, lấy claims về `username`, `role`, thời hạn token.
   - Tích hợp `shared_preferences` lưu token cục bộ để tự động đăng nhập khi mở app.
   - Sửa lỗi điều hướng phân quyền: Admin vào `AdminScreen`, User vào `MainScreen`.
   - Sửa lỗi tự động đăng nhập (Auto-login): Khôi phục role chính xác từ token đã lưu để vào đúng màn hình.
   - Chức năng Đăng xuất: Xóa token và đưa về màn hình Đăng nhập.
   - Giao diện Admin quản lý danh mục (Thêm / Sửa / Xóa) và xem danh sách sản phẩm.

---

## 2. Kiến trúc hệ thống & Cấu trúc thư mục

Thư mục gốc: `/home/quocanh/LeQuocAnh_2380600052`

```
LeQuocAnh_2380600052/
├── LTDD Tuan7 V2.docx
├── docs/
│   └── superpowers/specs/2026-10-21-ltdd-tuan7-auth-identity-flutter-design.md
├── backend/                             # Dự án ASP.NET Core 8 Web API
│   ├── Controllers/
│   │   ├── AuthenticateController.cs
│   │   ├── CategoryController.cs
│   │   └── ProductController.cs
│   ├── Data/
│   │   └── ApplicationDbContext.cs
│   ├── Models/
│   │   ├── User.cs
│   │   ├── Category.cs
│   │   ├── Product.cs
│   │   └── DTOs/
│   │       ├── LoginModel.cs
│   │       ├── RegistrationModel.cs
│   │       ├── CategoryDto.cs
│   │       └── ProductDto.cs
│   ├── Repositories/
│   │   ├── IProductRepository.cs
│   │   └── ProductRepository.cs
│   ├── Program.cs
│   ├── appsettings.json
│   └── backend.csproj
└── frontend/                            # Dự án Flutter
    ├── .env
    ├── pubspec.yaml
    └── lib/
        ├── config/
        │   └── config_url.dart
        ├── models/
        │   ├── category.dart
        │   └── product.dart
        ├── services/
        │   ├── api_client.dart
        │   ├── auth_service.dart
        │   ├── category_service.dart
        │   └── product_service.dart
        ├── utils/
        │   └── auth_helper.dart
        ├── screens/
        │   ├── login_screen.dart
        │   ├── registration_screen.dart
        │   ├── admin_screen.dart
        │   └── main_screen.dart
        └── main.dart
```

---

## 3. Đặc tả chi tiết Backend (.NET 8 Web API)

### 3.1. Các thư viện NuGet
- `Microsoft.AspNetCore.Identity.EntityFrameworkCore` (8.0.x)
- `Microsoft.AspNetCore.Authentication.JwtBearer` (8.0.x)
- `Microsoft.EntityFrameworkCore.Sqlite` (8.0.x)
- `Microsoft.EntityFrameworkCore.Design` (8.0.x)

### 3.2. Data Models & Entity Configurations
1. **User**:
   ```csharp
   public class User : IdentityUser
   {
       [MaxLength(5)]
       public string? Initials { get; set; }
   }
   ```
2. **Category**:
   ```csharp
   public class Category
   {
       public int Id { get; set; }
       [Required, MaxLength(100)]
       public string Name { get; set; } = string.Empty;
       public string? Description { get; set; }
       public ICollection<Product> Products { get; set; } = new List<Product>();
   }
   ```
3. **Product**:
   ```csharp
   public class Product
   {
       public int Id { get; set; }
       [Required, MaxLength(150)]
       public string Name { get; set; } = string.Empty;
       public decimal Price { get; set; }
       public string? Description { get; set; }
       public int? CategoryId { get; set; }
       public Category? Category { get; set; }
   }
   ```
4. **ApplicationDbContext**:
   - `DbSet<Product> Products`
   - `DbSet<Category> Categories`
   - Quan hệ 1-N giữa Category và Product với cấu hình `OnDelete(DeleteBehavior.SetNull)`: khi xóa một danh mục, cột `CategoryId` trong bảng Product sẽ chuyển thành `NULL`, không làm mất dữ liệu sản phẩm.

### 3.3. API Endpoints
* **Authentication (`/api/Authenticate`)**:
  - `POST /register`: Nhận `RegistrationModel` (Username, Email, Password, Initials, Role). Tạo User trong Identity, gán Role tương ứng.
  - `POST /login`: Nhận `LoginModel` (Username, Password). Kiểm tra mật khẩu, sinh JWT Token chứa Claims: `ClaimTypes.Name`, `ClaimTypes.Role`, `JwtRegisteredClaimNames.Jti`. Trả về `{ status: true, message: "...", token: "..." }`.
* **Category (`/api/Category`)**:
  - `GET /`: Lấy toàn bộ danh mục (AllowAnonymous hoặc Authenticated).
  - `POST /`: `[Authorize(Roles = "Admin")]` Thêm mới danh mục.
  - `PUT /{id}`: `[Authorize(Roles = "Admin")]` Cập nhật danh mục.
  - `DELETE /{id}`: `[Authorize(Roles = "Admin")]` Xóa danh mục.
* **Product (`/api/Product`)**:
  - `GET /`: `[Authorize]` Lấy danh sách sản phẩm (kèm thông tin danh mục).
  - `POST /`: `[Authorize(Roles = "Admin")]` Tạo sản phẩm mới.
  - `PUT /{id}`: `[Authorize(Roles = "Admin")]` Sửa sản phẩm.
  - `DELETE /{id}`: `[Authorize(Roles = "Admin")]` Xóa sản phẩm.

---

## 4. Đặc tả chi tiết Frontend (Flutter)

### 4.1. Các thư viện Pub
- `http: ^1.2.0`
- `flutter_dotenv: ^5.1.0`
- `jwt_decoder: ^2.0.1`
- `shared_preferences: ^2.2.0`

### 4.2. Quản lý trạng thái & Xử lý Token (`AuthHelper`)
- Lưu trữ: `jwt_token` được lưu vào `SharedPreferences`.
- Giải mã & Kiểm tra thời hạn:
  - `JwtDecoder.decode(token)` để lấy `role` (qua ClaimTypes.Role hoặc key `role`).
  - `JwtDecoder.isExpired(token)`: Nếu `true`, tự động xóa token và yêu cầu đăng nhập lại.
- Đăng xuất:
  - Gọi `await prefs.remove('jwt_token')`.
  - Điều hướng: `Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false)`.

### 4.3. Luồng điều hướng (Routing Flow)
1. **Khởi động ứng dụng**:
   - `main()` gọi `await dotenv.load(fileName: ".env")`.
   - Mở `LoginScreen`.
   - `LoginScreen.initState()` gọi `_checkToken()`:
     - Nếu không có token hoặc token đã hết hạn -> Ở lại `LoginScreen`.
     - Nếu token hợp lệ: kiểm tra role:
       - Nếu `role == 'Admin'` -> Điều hướng `AdminScreen`.
       - Nếu khác -> Điều hướng `MainScreen`.
2. **Đăng nhập (`_handleLogin`)**:
   - Gọi `AuthService.login(username, password)`.
   - Thành công: Lưu token vào `SharedPreferences`, trích xuất `role`.
   - Điều hướng đúng màn hình tương ứng với vai trò.

### 4.4. Giao diện người dùng (Screens)
- **`LoginScreen`**: Ô nhập Username, Password (ẩn/hiện mật khẩu), nút Đăng nhập, liên kết chuyển sang màn hình Đăng ký.
- **`RegistrationScreen`**: Ô nhập Username, Email, Password, Initials, Dropdown/Field chọn Role (`User` hoặc `Admin`), nút Đăng ký, liên kết quay lại Đăng nhập.
- **`AdminScreen`**:
  - Header/AppBar hiển thị tên Admin + Nút Đăng xuất.
  - Tab 1: **Quản lý Danh mục (Category)**: Danh sách danh mục, nút Thêm danh mục, nút Sửa, nút Xóa (kèm dialog xác nhận).
  - Tab 2: **Quản lý Sản phẩm**: Xem danh sách sản phẩm và danh mục tương ứng.
- **`MainScreen`**:
  - Header/AppBar hiển thị thông tin User + Nút Đăng xuất.
  - Danh sách sản phẩm được nhóm hoặc lọc theo Danh mục.

---

## 5. Kế hoạch kiểm thử & Tiêu chí nghiệm thu (Acceptance Criteria)
1. **Kiểm thử Đăng ký & Đăng nhập**:
   - Đăng ký tài khoản User và Admin thành công.
   - Đăng nhập đúng mật khẩu: cấp token hợp lệ; sai mật khẩu: báo lỗi rõ ràng.
2. **Kiểm thử Phân quyền (Bug 1 & 2)**:
   - Đăng nhập với tài khoản Admin -> Chuyển vào `AdminScreen`.
   - Đăng nhập với tài khoản User -> Chuyển vào `MainScreen`.
   - Đóng ứng dụng / khởi động lại app -> Tự động vào đúng màn hình theo quyền của tài khoản đã đăng nhập trước đó.
3. **Kiểm thử Đăng xuất**:
   - Nhấn Đăng xuất -> Token bị xóa khỏi SharedPreferences, app quay về `LoginScreen`, không thể nhấn nút Back để quay lại màn hình trước.
4. **Kiểm thử Quản lý danh mục & Ràng buộc CSDL**:
   - Admin tạo mới, chỉnh sửa và xóa danh mục thành công.
   - Khi xóa danh mục, các sản phẩm trước đó thuộc danh mục đó vẫn tồn tại và chuyển `CategoryId` về `null`.
