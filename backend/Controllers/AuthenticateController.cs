using backend.Models;
using backend.Models.DTOs;
using backend.Services;
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
    private readonly IOtpService _otpService;
    private readonly IEmailService _emailService;

    public AuthenticateController(
        UserManager<User> userManager,
        RoleManager<IdentityRole> roleManager,
        IConfiguration configuration,
        IOtpService otpService,
        IEmailService emailService)
    {
        _userManager = userManager;
        _roleManager = roleManager;
        _configuration = configuration;
        _otpService = otpService;
        _emailService = emailService;
    }

    [HttpPost("register-send-otp")]
    public async Task<IActionResult> RegisterSendOtp([FromBody] RegistrationModel model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var userByUsername = await _userManager.FindByNameAsync(model.Username);
        if (userByUsername != null)
            return BadRequest(new { status = false, message = "Tên đăng nhập đã tồn tại trong hệ thống" });

        var userByEmail = await _userManager.FindByEmailAsync(model.Email);
        if (userByEmail != null)
            return BadRequest(new { status = false, message = "Địa chỉ email này đã được sử dụng" });

        var otpCode = _otpService.GenerateOtp(model);
        await _emailService.SendOtpEmailAsync(model.Email, model.Username, otpCode);

        var isDev = string.IsNullOrWhiteSpace(_configuration.GetSection("EmailSettings")["AppPassword"]);

        return Ok(new
        {
            status = true,
            message = $"Mã OTP đã được gửi đến email {model.Email}. Vui lòng nhập mã để hoàn tất đăng ký.",
            devOtp = isDev ? otpCode : null
        });
    }

    [HttpPost("verify-register-otp")]
    public async Task<IActionResult> VerifyRegisterOtp([FromBody] VerifyOtpModel model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var verifyResult = _otpService.VerifyOtp(model.Email, model.Otp);
        if (!verifyResult.Success || verifyResult.Data == null)
        {
            return BadRequest(new { status = false, message = verifyResult.Message });
        }

        var regData = verifyResult.Data;

        // Double check username/email hasn't been taken in between
        if (await _userManager.FindByNameAsync(regData.Username) != null)
            return BadRequest(new { status = false, message = "Tên đăng nhập đã tồn tại" });

        var user = new User
        {
            UserName = regData.Username,
            Email = regData.Email,
            Initials = regData.Initials,
            EmailConfirmed = true
        };

        var result = await _userManager.CreateAsync(user, regData.Password);
        if (!result.Succeeded)
            return StatusCode(StatusCodes.Status500InternalServerError,
                new { status = false, message = string.Join("; ", result.Errors.Select(e => e.Description)) });

        var targetRole = string.IsNullOrWhiteSpace(regData.Role) ? "User" : regData.Role;
        if (!await _roleManager.RoleExistsAsync(targetRole))
        {
            await _roleManager.CreateAsync(new IdentityRole(targetRole));
        }
        await _userManager.AddToRoleAsync(user, targetRole);

        return Ok(new
        {
            status = true,
            message = "Xác thực email và tạo tài khoản thành công! Bạn có thể đăng nhập ngay bây giờ."
        });
    }

    [HttpPost("resend-otp")]
    public async Task<IActionResult> ResendOtp([FromBody] ResendOtpModel model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var result = _otpService.ResendOtp(model.Email);
        if (!result.Success || result.NewOtp == null)
        {
            return BadRequest(new { status = false, message = result.Message });
        }

        await _emailService.SendOtpEmailAsync(model.Email, "Người dùng", result.NewOtp);

        var isDev = string.IsNullOrWhiteSpace(_configuration.GetSection("EmailSettings")["AppPassword"]);

        return Ok(new
        {
            status = true,
            message = "Đã gửi lại mã xác thực OTP mới về Gmail của bạn.",
            devOtp = isDev ? result.NewOtp : null
        });
    }

    // Direct registration (vẫn giữ tương thích ngược với bài lab cũ nếu cần)
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
        var primaryRole = userRoles.Contains("Admin") ? "Admin" : (userRoles.FirstOrDefault() ?? "User");

        return Ok(new
        {
            status = true,
            message = "Đăng nhập thành công",
            token = token,
            role = primaryRole,
            username = user.UserName
        });
    }

    [HttpPost("login-request-otp")]
    public async Task<IActionResult> LoginRequestOtp([FromBody] LoginModel model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var user = await _userManager.FindByNameAsync(model.Username);
        if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
            return Unauthorized(new { status = false, message = "Tên đăng nhập hoặc mật khẩu không chính xác" });

        var email = user.Email ?? $"{user.UserName}@workpulse.vn";
        var dummyReg = new RegistrationModel { Email = email, Username = user.UserName ?? "" };
        var otpCode = _otpService.GenerateOtp(dummyReg);

        if (!string.IsNullOrEmpty(user.Email))
        {
            await _emailService.SendOtpEmailAsync(user.Email, user.UserName ?? "Người dùng", otpCode);
        }

        var isDev = string.IsNullOrWhiteSpace(_configuration.GetSection("EmailSettings")["AppPassword"]);

        return Ok(new
        {
            status = true,
            message = $"Đã gửi mã OTP xác thực đăng nhập đến email {email}.",
            email = email,
            devOtp = isDev ? otpCode : null
        });
    }

    [HttpPost("login-verify-otp")]
    public async Task<IActionResult> LoginVerifyOtp([FromBody] VerifyOtpModel model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var verifyResult = _otpService.VerifyOtp(model.Email, model.Otp);
        if (!verifyResult.Success)
        {
            return BadRequest(new { status = false, message = verifyResult.Message });
        }

        var user = await _userManager.FindByEmailAsync(model.Email) ?? await _userManager.FindByNameAsync(model.Email);
        if (user == null) return NotFound(new { status = false, message = "Không tìm thấy người dùng" });

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
        var primaryRole = userRoles.Contains("Admin") ? "Admin" : (userRoles.FirstOrDefault() ?? "User");

        return Ok(new
        {
            status = true,
            message = "Đăng nhập và xác thực OTP thành công!",
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
