# Hệ thống Authentication ASP.NET Core Identity & Flutter Client (Tuần 7) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng hoàn chỉnh từ A-Z hệ thống ASP.NET Core 8 Web API (Identity + JWT + SQLite) và ứng dụng di động Flutter (Login, Register, Phân quyền Admin/User, Auto-login, Đăng xuất, CRUD Danh mục sản phẩm) theo yêu cầu bài thực hành Tuần 7 và các bài tập về nhà.

**Architecture:** Monorepo gồm 2 thư mục độc lập `backend/` (ASP.NET Core 8 Web API dùng EF Core SQLite và JWT Bearer) và `frontend/` (Flutter app dùng `flutter_dotenv`, `jwt_decoder`, `shared_preferences`, `http`). Backend chịu trách nhiệm quản lý User, phân quyền, cấp JWT token và xử lý quan hệ Category - Product (SetNull khi xóa). Frontend chịu trách nhiệm giao diện, giải mã token để điều hướng đúng vai trò và gọi API.

**Tech Stack:**
- Backend: C# / .NET 8 SDK, ASP.NET Core Web API, EF Core 8 SQLite, ASP.NET Core Identity, JWT Bearer, Swashbuckle Swagger.
- Frontend: Flutter 3.47+, Dart 3.13+, `flutter_dotenv`, `jwt_decoder`, `shared_preferences`, `http`.

## Global Constraints
- Root workspace: `/home/quocanh/LeQuocAnh_2380600052`
- Database: SQLite (`backend/app.db`) - không yêu cầu Docker/SQL Server cồng kềnh.
- API Base URL: `http://localhost:5000/api/` hoặc `http://10.0.2.2:5000/api/` trên máy ảo Android.
- Tên các gói NuGet và Pub phải đúng tuyệt đối theo tài liệu.
- Ràng buộc: Xóa danh mục sản phẩm thì sản phẩm thuộc danh mục đó không bị xóa mà chuyển `CategoryId = null`.

---

### Task 1: Environment & .NET SDK Setup on Linux

**Files:**
- Modify: `~/.bashrc` (thêm PATH cho .dotnet)

**Interfaces:**
- Consumes: Shell environment
- Produces: `dotnet` CLI (version 8.0.x), `dotnet-ef` global tool

- [ ] **Step 1: Check and download .NET 8 install script**
```bash
curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
chmod +x /tmp/dotnet-install.sh
```

- [ ] **Step 2: Install .NET 8 SDK locally**
```bash
/tmp/dotnet-install.sh --channel 8.0 --install-dir /home/quocanh/.dotnet
```

- [ ] **Step 3: Export PATH and verify dotnet**
```bash
export DOTNET_ROOT=/home/quocanh/.dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
dotnet --version
```
Expected: `8.0.xxx`

- [ ] **Step 4: Install dotnet-ef global tool**
```bash
dotnet tool install --global dotnet-ef || dotnet tool update --global dotnet-ef
dotnet ef --version
```
Expected: `8.0.x`

---

### Task 2: Backend Scaffolding & Dependencies

**Files:**
- Create: `backend/backend.csproj`
- Create: `backend/Program.cs`
- Create: `backend/appsettings.json`

**Interfaces:**
- Consumes: `dotnet` SDK 8.0
- Produces: Build-ready ASP.NET Core Web API project

- [ ] **Step 1: Create Web API project in backend/**
```bash
cd /home/quocanh/LeQuocAnh_2380600052
mkdir -p backend
cd backend
dotnet new webapi --use-controllers -n backend -o .
```

- [ ] **Step 2: Add NuGet packages**
```bash
dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore --version 8.0.10
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer --version 8.0.10
dotnet add package Microsoft.EntityFrameworkCore.Sqlite --version 8.0.10
dotnet add package Microsoft.EntityFrameworkCore.Design --version 8.0.10
dotnet add package Swashbuckle.AspNetCore --version 6.6.2
```

- [ ] **Step 3: Verify build**
```bash
dotnet build
```
Expected: `Build succeeded. 0 Warning(s) 0 Error(s)`

- [ ] **Step 4: Commit**
```bash
cd /home/quocanh/LeQuocAnh_2380600052
git add backend/
git commit -m "feat(backend): scaffold .NET 8 Web API project with Identity and JWT packages"
```

---

### Task 3: Backend Models, DTOs & ApplicationDbContext with SQLite

**Files:**
- Create: `backend/Models/User.cs`
- Create: `backend/Models/Category.cs`
- Create: `backend/Models/Product.cs`
- Create: `backend/Models/DTOs/LoginModel.cs`
- Create: `backend/Models/DTOs/RegistrationModel.cs`
- Create: `backend/Models/DTOs/CategoryDto.cs`
- Create: `backend/Models/DTOs/ProductDto.cs`
- Create: `backend/Data/ApplicationDbContext.cs`

**Interfaces:**
- Consumes: EF Core, ASP.NET Core Identity
- Produces: SQLite Database Migration with User, Category, Product tables and DeleteBehavior.SetNull

- [ ] **Step 1: Create User model**
`backend/Models/User.cs`:
```csharp
using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;

namespace backend.Models;

public class User : IdentityUser
{
    [MaxLength(5)]
    public string? Initials { get; set; }
}
```

- [ ] **Step 2: Create Category and Product models**
`backend/Models/Category.cs`:
```csharp
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace backend.Models;

public class Category
{
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    [JsonIgnore]
    public ICollection<Product> Products { get; set; } = new List<Product>();
}
```

`backend/Models/Product.cs`:
```csharp
using System.ComponentModel.DataAnnotations;

namespace backend.Models;

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

- [ ] **Step 3: Create DTOs**
`backend/Models/DTOs/LoginModel.cs`:
```csharp
using System.ComponentModel.DataAnnotations;

namespace backend.Models.DTOs;

public class LoginModel
{
    [Required]
    public string Username { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
}
```

`backend/Models/DTOs/RegistrationModel.cs`:
```csharp
using System.ComponentModel.DataAnnotations;

namespace backend.Models.DTOs;

public class RegistrationModel
{
    [Required]
    public string Username { get; set; } = string.Empty;

    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required, MinLength(6)]
    public string Password { get; set; } = string.Empty;

    public string? Initials { get; set; }

    public string? Role { get; set; } // "Admin" or "User"
}
```

`backend/Models/DTOs/CategoryDto.cs`:
```csharp
using System.ComponentModel.DataAnnotations;

namespace backend.Models.DTOs;

public class CategoryDto
{
    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }
}
```

`backend/Models/DTOs/ProductDto.cs`:
```csharp
using System.ComponentModel.DataAnnotations;

namespace backend.Models.DTOs;

public class ProductDto
{
    [Required, MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    public decimal Price { get; set; }

    public string? Description { get; set; }

    public int? CategoryId { get; set; }
}
```

- [ ] **Step 4: Create ApplicationDbContext with DeleteBehavior.SetNull**
`backend/Data/ApplicationDbContext.cs`:
```csharp
using backend.Models;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace backend.Data;

public class ApplicationDbContext : IdentityDbContext<User>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    public DbSet<Product> Products => Set<Product>();
    public DbSet<Category> Categories => Set<Category>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<User>().Property(u => u.Initials).HasMaxLength(5);

        // Foreign Key: Product -> Category with SetNull on delete
        builder.Entity<Product>()
            .HasOne(p => p.Category)
            .WithMany(c => c.Products)
            .HasForeignKey(p => p.CategoryId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
```

- [ ] **Step 5: Run EF Core Migration & Update Database**
```bash
cd /home/quocanh/LeQuocAnh_2380600052/backend
dotnet ef migrations add InitialIdentityAndModels
dotnet ef database update
```
Expected: `Done. To undo this action, use 'ef migrations remove'` and SQLite `app.db` created.

- [ ] **Step 6: Commit**
```bash
cd /home/quocanh/LeQuocAnh_2380600052
git add backend/
git commit -m "feat(backend): add models, DTOs, DbContext with SetNull cascade, and initial migration"
```

---

### Task 4: Backend Controllers, Program.cs & JWT Setup

**Files:**
- Create: `backend/Controllers/AuthenticateController.cs`
- Create: `backend/Controllers/CategoryController.cs`
- Create: `backend/Controllers/ProductController.cs`
- Modify: `backend/appsettings.json`
- Modify: `backend/Program.cs`

**Interfaces:**
- Consumes: `ApplicationDbContext`, `UserManager<User>`, `RoleManager<IdentityRole>`, JWT Settings
- Produces: Complete REST API with Swagger, JWT Auth, Role Seed

- [ ] **Step 1: Configure appsettings.json**
`backend/appsettings.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=app.db"
  },
  "JWTKey": {
    "Secret": "A_Very_Long_Super_Secret_Key_For_JWT_Token_Signing_2026_LeQuocAnh!",
    "ValidIssuer": "LTDD_Backend_API",
    "ValidAudience": "LTDD_Flutter_Client",
    "TokenExpiryTimeInHour": "24"
  }
}
```

- [ ] **Step 2: Implement AuthenticateController**
`backend/Controllers/AuthenticateController.cs`:
```csharp
using backend.Models;
using backend.Models.DTOs;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthenticateController : ControllerBase
{
    private readonly UserManager<User> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly IConfiguration _configuration;

    public AuthenticateController(
        UserManager<User> userManager,
        RoleManager<IdentityRole> roleManager,
        IConfiguration configuration)
    {
        _userManager = userManager;
        _roleManager = roleManager;
        _configuration = configuration;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegistrationModel model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var userExists = await _userManager.FindByNameAsync(model.Username);
        if (userExists != null)
            return BadRequest(new { status = false, message = "Tên đăng nhập đã tồn tại" });

        var user = new User
        {
            UserName = model.Username,
            Email = model.Email,
            Initials = model.Initials
        };

        var result = await _userManager.CreateAsync(user, model.Password);
        if (!result.Succeeded)
            return StatusCode(StatusCodes.Status500InternalServerError,
                new { status = false, message = string.Join("; ", result.Errors.Select(e => e.Description)) });

        var targetRole = string.IsNullOrWhiteSpace(model.Role) ? "User" : model.Role;
        if (!await _roleManager.RoleExistsAsync(targetRole))
        {
            await _roleManager.CreateAsync(new IdentityRole(targetRole));
        }
        await _userManager.AddToRoleAsync(user, targetRole);

        return Ok(new { status = true, message = "Đăng ký tài khoản thành công" });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginModel model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var user = await _userManager.FindByNameAsync(model.Username);
        if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
            return Unauthorized(new { status = false, message = "Tên đăng nhập hoặc mật khẩu không chính xác" });

        var userRoles = await _userManager.GetRolesAsync(user);
        var authClaims = new List<Claim>
        {
            new Claim(ClaimTypes.Name, user.UserName ?? string.Empty),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        foreach (var role in userRoles)
        {
            authClaims.Add(new Claim(ClaimTypes.Role, role));
        }

        var token = GenerateToken(authClaims);
        var primaryRole = userRoles.FirstOrDefault() ?? "User";

        return Ok(new
        {
            status = true,
            message = "Đăng nhập thành công",
            token = token,
            role = primaryRole,
            username = user.UserName
        });
    }

    private string GenerateToken(IEnumerable<Claim> claims)
    {
        var jwtSettings = _configuration.GetSection("JWTKey");
        var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Secret"]!));

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddHours(Convert.ToDouble(jwtSettings["TokenExpiryTimeInHour"])),
            Issuer = jwtSettings["ValidIssuer"],
            Audience = jwtSettings["ValidAudience"],
            SigningCredentials = new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }
}
```

- [ ] **Step 3: Implement CategoryController**
`backend/Controllers/CategoryController.cs`:
```csharp
using backend.Data;
using backend.Models;
using backend.Models.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CategoryController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CategoryController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var categories = await _context.Categories.ToListAsync();
        return Ok(new { status = true, data = categories });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var category = await _context.Categories.FindAsync(id);
        if (category == null) return NotFound(new { status = false, message = "Không tìm thấy danh mục" });
        return Ok(new { status = true, data = category });
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CategoryDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var category = new Category
        {
            Name = dto.Name,
            Description = dto.Description
        };

        _context.Categories.Add(category);
        await _context.SaveChangesAsync();
        return Ok(new { status = true, message = "Tạo danh mục thành công", data = category });
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, [FromBody] CategoryDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var category = await _context.Categories.FindAsync(id);
        if (category == null) return NotFound(new { status = false, message = "Không tìm thấy danh mục" });

        category.Name = dto.Name;
        category.Description = dto.Description;

        await _context.SaveChangesAsync();
        return Ok(new { status = true, message = "Cập nhật danh mục thành công", data = category });
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var category = await _context.Categories.FindAsync(id);
        if (category == null) return NotFound(new { status = false, message = "Không tìm thấy danh mục" });

        _context.Categories.Remove(category);
        await _context.SaveChangesAsync(); // Products will have CategoryId set to null automatically

        return Ok(new { status = true, message = "Xóa danh mục thành công (các sản phẩm liên quan đã chuyển sang Chưa phân loại)" });
    }
}
```

- [ ] **Step 4: Implement ProductController**
`backend/Controllers/ProductController.cs`:
```csharp
using backend.Data;
using backend.Models;
using backend.Models.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize] // Yêu cầu xác thực theo bài tập về nhà
public class ProductController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ProductController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var products = await _context.Products.Include(p => p.Category).ToListAsync();
        return Ok(new { status = true, data = products });
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] ProductDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var product = new Product
        {
            Name = dto.Name,
            Price = dto.Price,
            Description = dto.Description,
            CategoryId = dto.CategoryId
        };

        _context.Products.Add(product);
        await _context.SaveChangesAsync();
        return Ok(new { status = true, message = "Thêm sản phẩm thành công", data = product });
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var product = await _context.Products.FindAsync(id);
        if (product == null) return NotFound(new { status = false, message = "Không tìm thấy sản phẩm" });

        _context.Products.Remove(product);
        await _context.SaveChangesAsync();
        return Ok(new { status = true, message = "Xóa sản phẩm thành công" });
    }
}
```

- [ ] **Step 5: Configure Program.cs with Seed Data & Swagger JWT**
`backend/Program.cs`:
```csharp
using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// 1. DbContext
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

// 2. Identity
builder.Services.AddIdentity<User, IdentityRole>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequireLowercase = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.Password.RequiredLength = 6;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

// 3. JWT Authentication
var jwtSettings = builder.Configuration.GetSection("JWTKey");
var key = Encoding.UTF8.GetBytes(jwtSettings["Secret"]!);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["ValidIssuer"],
        ValidAudience = jwtSettings["ValidAudience"],
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };
});

builder.Services.AddAuthorization();
builder.Services.AddControllers();

// 4. CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});

// 5. Swagger with Bearer Support
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "LTDD Tuan 7 API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Nhập 'Bearer {token}' để xác thực"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// 6. Seed Roles & Default Admin Account
using (var scope = app.Services.CreateScope())
{
    var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<User>>();

    string[] roles = ["Admin", "User"];
    foreach (var role in roles)
    {
        if (!await roleManager.RoleExistsAsync(role))
        {
            await roleManager.CreateAsync(new IdentityRole(role));
        }
    }

    var adminUser = await userManager.FindByNameAsync("admin");
    if (adminUser == null)
    {
        adminUser = new User
        {
            UserName = "admin",
            Email = "admin@example.com",
            Initials = "ADM"
        };
        await userManager.CreateAsync(adminUser, "Admin@123");
        await userManager.AddToRoleAsync(adminUser, "Admin");
    }
}

app.UseSwagger();
app.UseSwaggerUI();

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
```

- [ ] **Step 6: Build & Test Backend API**
```bash
cd /home/quocanh/LeQuocAnh_2380600052/backend
dotnet build
```
Expected: `Build succeeded. 0 Error(s)`

- [ ] **Step 7: Commit**
```bash
cd /home/quocanh/LeQuocAnh_2380600052
git add backend/
git commit -m "feat(backend): complete Authenticate, Category, Product controllers with JWT and Seed"
```

---

### Task 5: Frontend Flutter Scaffolding & Dependencies

**Files:**
- Create: `frontend/` project structure
- Create: `frontend/assets/.env`
- Modify: `frontend/pubspec.yaml`

**Interfaces:**
- Consumes: Flutter SDK 3.47+
- Produces: Configured Flutter project with `jwt_decoder`, `flutter_dotenv`, `shared_preferences`, `http`

- [ ] **Step 1: Create Flutter project**
```bash
cd /home/quocanh/LeQuocAnh_2380600052
flutter create --org com.lequocanh --project-name frontend frontend
```

- [ ] **Step 2: Add required dependencies to frontend/pubspec.yaml**
```bash
cd /home/quocanh/LeQuocAnh_2380600052/frontend
flutter pub add http flutter_dotenv jwt_decoder shared_preferences
```

- [ ] **Step 3: Create assets/.env and declare in pubspec.yaml**
`frontend/assets/.env`:
```
BASE_URL=http://localhost:5000/api/
```

Update `frontend/pubspec.yaml` to include assets:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/.env
```

- [ ] **Step 4: Run flutter pub get**
```bash
flutter pub get
```
Expected: `Got dependencies!`

- [ ] **Step 5: Commit**
```bash
cd /home/quocanh/LeQuocAnh_2380600052
git add frontend/
git commit -m "feat(frontend): scaffold Flutter project and add required dependencies"
```

---

### Task 6: Frontend Core Services & Auth Helpers

**Files:**
- Create: `frontend/lib/config/config_url.dart`
- Create: `frontend/lib/models/category.dart`
- Create: `frontend/lib/models/product.dart`
- Create: `frontend/lib/utils/auth_helper.dart`
- Create: `frontend/lib/services/api_client.dart`
- Create: `frontend/lib/services/auth_service.dart`
- Create: `frontend/lib/services/category_service.dart`
- Create: `frontend/lib/services/product_service.dart`

**Interfaces:**
- Consumes: `flutter_dotenv`, `jwt_decoder`, `shared_preferences`, `http`
- Produces: Centralized API communication, token storage, and authentication state management

- [ ] **Step 1: Create config_url.dart**
`frontend/lib/config/config_url.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigUrl {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      return "http://localhost:5000/api/";
    }
    return url;
  }
}
```

- [ ] **Step 2: Create Category and Product Dart models**
`frontend/lib/models/category.dart`:
```dart
class Category {
  final int id;
  final String name;
  final String? description;

  Category({required this.id, required this.name, this.description});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
}
```

`frontend/lib/models/product.dart`:
```dart
import 'category.dart';

class Product {
  final int id;
  final String name;
  final double price;
  final String? description;
  final int? categoryId;
  final Category? category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.categoryId,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int?,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }
}
```

- [ ] **Step 3: Create AuthHelper with Token decode & Role extraction**
`frontend/lib/utils/auth_helper.dart`:
```dart
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static const String tokenKey = 'jwt_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    try {
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }

  static Future<String> getRole() async {
    final token = await getToken();
    if (token == null) return 'User';
    try {
      final decoded = JwtDecoder.decode(token);
      final role = decoded['role'] ??
          decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      return role?.toString() ?? 'User';
    } catch (_) {
      return 'User';
    }
  }

  static Future<String> getUsername() async {
    final token = await getToken();
    if (token == null) return '';
    try {
      final decoded = JwtDecoder.decode(token);
      final name = decoded['unique_name'] ??
          decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'];
      return name?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }
}
```

- [ ] **Step 4: Create ApiClient**
`frontend/lib/services/api_client.dart`:
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../utils/auth_helper.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ConfigUrl.baseUrl;

  Future<Map<String, String>> _buildHeaders([Map<String, String>? extra]) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await AuthHelper.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _buildHeaders();
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  Future<http.Response> post(String endpoint, dynamic body) async {
    final headers = await _buildHeaders();
    return http.post(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String endpoint, dynamic body) async {
    final headers = await _buildHeaders();
    return http.put(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _buildHeaders();
    return http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }
}
```

- [ ] **Step 5: Create AuthService, CategoryService, ProductService**
`frontend/lib/services/auth_service.dart`:
```dart
import 'dart:convert';
import 'api_client.dart';
import '../utils/auth_helper.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _api.post('Authenticate/login', {
        'username': username,
        'password': password,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final token = data['token'] as String;
        await AuthHelper.saveToken(token);
        final role = await AuthHelper.getRole();
        return {'success': true, 'token': token, 'role': role, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng nhập thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? initials,
    String? role,
  }) async {
    try {
      final response = await _api.post('Authenticate/register', {
        'username': username,
        'email': email,
        'password': password,
        'initials': initials,
        'role': role ?? 'User',
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng ký thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
```

`frontend/lib/services/category_service.dart`:
```dart
import 'dart:convert';
import '../models/category.dart';
import 'api_client.dart';

class CategoryService {
  final ApiClient _api = ApiClient();

  Future<List<Category>> getAll() async {
    final response = await _api.get('Category');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List;
      return list.map((e) => Category.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> create(String name, String? description) async {
    final response = await _api.post('Category', {
      'name': name,
      'description': description,
    });
    return response.statusCode == 200;
  }

  Future<bool> update(int id, String name, String? description) async {
    final response = await _api.put('Category/$id', {
      'name': name,
      'description': description,
    });
    return response.statusCode == 200;
  }

  Future<bool> delete(int id) async {
    final response = await _api.delete('Category/$id');
    return response.statusCode == 200;
  }
}
```

`frontend/lib/services/product_service.dart`:
```dart
import 'dart:convert';
import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient _api = ApiClient();

  Future<List<Product>> getAll() async {
    final response = await _api.get('Product');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List;
      return list.map((e) => Product.fromJson(e)).toList();
    }
    return [];
  }
}
```

- [ ] **Step 6: Commit**
```bash
cd /home/quocanh/LeQuocAnh_2380600052
git add frontend/
git commit -m "feat(frontend): implement ApiClient, AuthHelper, Category and Product services"
```

---

### Task 7: Frontend Authentication Screens (Login & Register with Role Navigation)

**Files:**
- Create: `frontend/lib/screens/login_screen.dart`
- Create: `frontend/lib/screens/registration_screen.dart`

**Interfaces:**
- Consumes: `AuthService`, `AuthHelper`
- Produces: Interactive login and registration forms with validation and role-based redirect

- [ ] **Step 1: Implement RegistrationScreen**
`frontend/lib/screens/registration_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _initialsController = TextEditingController();
  String _selectedRole = 'User';
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _authService = AuthService();

  Future<void> _handleRegister() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đủ Username, Email và Mật khẩu'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      initials: _initialsController.text.trim(),
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Trở về LoginScreen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Ký Tài Khoản')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Tên đăng nhập', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _initialsController,
                maxLength: 5,
                decoration: const InputDecoration(labelText: 'Ký tự viết tắt (Initials, max 5)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Vai trò (Role)', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'User', child: Text('Người dùng (User)')),
                  DropdownMenuItem(value: 'Admin', child: Text('Quản trị viên (Admin)')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val ?? 'User'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Đăng Ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Implement LoginScreen with Role Navigation & Auto-Login Fix**
`frontend/lib/screens/login_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/auth_helper.dart';
import 'admin_screen.dart';
import 'main_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  // SỬA LỖI 2: Tự động đăng nhập kiểm tra thời hạn và điều hướng ĐÚNG Role
  Future<void> _checkToken() async {
    final isValid = await AuthHelper.isTokenValid();
    if (!isValid) {
      await AuthHelper.logout();
      return;
    }

    final role = await AuthHelper.getRole();
    if (!mounted) return;

    _navigateToRoleScreen(role);
  }

  void _navigateToRoleScreen(String role) {
    if (role.toLowerCase() == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  // SỬA LỖI 1: Khi đăng nhập, đọc Role từ token để vào đúng AdminScreen hoặc MainScreen
  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập và mật khẩu'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      final role = result['role'] as String;
      _navigateToRoleScreen(role);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Tên đăng nhập', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Đăng Nhập'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản? '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                      );
                    },
                    child: const Text('Đăng ký ngay'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**
```bash
cd /home/quocanh/LeQuocAnh_2380600052
git add frontend/
git commit -m "feat(frontend): add LoginScreen and RegistrationScreen with role-based routing"
```

---

### Task 8: Frontend Main & Admin Screens (with Logout and Category CRUD)

**Files:**
- Create: `frontend/lib/screens/main_screen.dart`
- Create: `frontend/lib/screens/admin_screen.dart`
- Modify: `frontend/lib/main.dart`

**Interfaces:**
- Consumes: `CategoryService`, `ProductService`, `AuthHelper`
- Produces: Role-specific screens, Category CRUD for Admin, Products for User, Logout capability

- [ ] **Step 1: Implement MainScreen for Users with Logout**
`frontend/lib/screens/main_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/auth_helper.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final username = await AuthHelper.getUsername();
    final products = await _productService.getAll();
    setState(() {
      _username = username;
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await AuthHelper.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trang Chủ User ($_username)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Chưa có sản phẩm nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Danh mục: ${item.category?.name ?? "Chưa phân loại"}\n${item.description ?? ""}',
                        ),
                        trailing: Text(
                          '${item.price} đ',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
```

- [ ] **Step 2: Implement AdminScreen with Category CRUD & Logout**
`frontend/lib/screens/admin_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../utils/auth_helper.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categoryService = CategoryService();
  final _productService = ProductService();

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final username = await AuthHelper.getUsername();
    final categories = await _categoryService.getAll();
    final products = await _productService.getAll();
    setState(() {
      _username = username;
      _categories = categories;
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await AuthHelper.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showCategoryDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Thêm Danh Mục' : 'Sửa Danh Mục'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên danh mục'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context);

              if (category == null) {
                await _categoryService.create(nameController.text.trim(), descController.text.trim());
              } else {
                await _categoryService.update(category.id, nameController.text.trim(), descController.text.trim());
              }
              _loadData();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa danh mục'),
        content: Text(
          'Bạn có chắc muốn xóa danh mục "${category.name}"?\n(Các sản phẩm thuộc danh mục này sẽ chuyển sang trạng thái "Chưa phân loại")',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _categoryService.delete(category.id);
              _loadData();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel ($_username)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.category), text: 'Quản Lý Danh Mục'),
            Tab(icon: Icon(Icons.inventory), text: 'Danh Sách Sản Phẩm'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Danh mục
                Scaffold(
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => _showCategoryDialog(),
                    child: const Icon(Icons.add),
                  ),
                  body: _categories.isEmpty
                      ? const Center(child: Text('Chưa có danh mục nào'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.folder, color: Colors.indigo),
                                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(cat.description ?? 'Không có mô tả'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showCategoryDialog(category: cat),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDeleteCategory(cat),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Tab 2: Sản phẩm
                _products.isEmpty
                    ? const Center(child: Text('Chưa có sản phẩm'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final p = _products[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.shopping_cart),
                              title: Text(p.name),
                              subtitle: Text('Danh mục: ${p.category?.name ?? "Chưa phân loại"}'),
                              trailing: Text('${p.price} đ'),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
```

- [ ] **Step 3: Update frontend/lib/main.dart**
`frontend/lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint("Lỗi tải file .env: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LTDD Tuần 7 - Phân Quyền Identity & JWT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
```

- [ ] **Step 4: Check Flutter code analysis**
```bash
cd /home/quocanh/LeQuocAnh_2380600052/frontend
flutter analyze
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**
```bash
cd /home/quocanh/LeQuocAnh_2380600052
git add frontend/
git commit -m "feat(frontend): complete MainScreen, AdminScreen with Category CRUD and main entrypoint"
```

---

### Task 9: End-to-End Verification & Integration Test

**Files:**
- Create: `backend/tests/verify_endpoints.py`

**Interfaces:**
- Consumes: Running Backend API at `http://localhost:5000`
- Produces: Automated verification report testing register, login, role JWT claim, category CRUD, set null cascade constraint

- [ ] **Step 1: Write automated Python E2E verification script**
`backend/tests/verify_endpoints.py`:
```python
import json
import urllib.request
import urllib.error

BASE = "http://localhost:5000/api"

def request(path, method="GET", body=None, token=None):
    url = f"{BASE}/{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(body).encode("utf-8") if body else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            return response.status, json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode("utf-8"))

print("1. Testing Register New User...")
status, res = request("Authenticate/register", "POST", {
    "username": "testuser1",
    "email": "testuser1@example.com",
    "password": "Password@123",
    "initials": "TU1",
    "role": "User"
})
print(f"Register User: {status} -> {res.get('message')}")

print("\n2. Testing Login Admin (Default Seed)...")
status, res = request("Authenticate/login", "POST", {
    "username": "admin",
    "password": "Admin@123"
})
assert status == 200, f"Admin login failed: {res}"
admin_token = res["token"]
print(f"Admin Token obtained, role: {res.get('role')}")

print("\n3. Testing Category CRUD by Admin...")
status, cat_res = request("Category", "POST", {"name": "Điện Thoại", "description": "Thiết bị di động"}, token=admin_token)
assert status == 200
cat_id = cat_res["data"]["id"]
print(f"Created Category ID: {cat_id}")

print("\n4. Testing Product Creation attached to Category...")
status, prod_res = request("Product", "POST", {
    "name": "iPhone 15 Pro",
    "price": 25000000,
    "description": "Titan tự nhiên",
    "categoryId": cat_id
}, token=admin_token)
assert status == 200
prod_id = prod_res["data"]["id"]
print(f"Created Product ID: {prod_id} with CategoryId: {cat_id}")

print("\n5. Testing Delete Category and verify Product categoryId becomes null...")
status, del_res = request(f"Category/{cat_id}", "DELETE", token=admin_token)
assert status == 200
print(f"Deleted Category: {del_res.get('message')}")

status, prods = request("Product", "GET", token=admin_token)
matching = [p for p in prods["data"] if p["id"] == prod_id]
assert len(matching) == 1
assert matching[0]["categoryId"] is None, "CategoryId was not set to NULL!"
print("Verification PASSED: Product CategoryId successfully reset to null on Category deletion!")
```

- [ ] **Step 2: Run verification**
```bash
python3 backend/tests/verify_endpoints.py
```
Expected: `Verification PASSED`

- [ ] **Step 3: Final Git status and commit**
```bash
cd /home/quocanh/LeQuocAnh_2380600052
git status
git add .
git commit -m "test: add E2E verification script and confirm all requirements met"
```
