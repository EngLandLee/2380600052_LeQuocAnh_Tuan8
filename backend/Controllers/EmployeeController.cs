using backend.Data;
using backend.Models;
using backend.Models.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class EmployeeController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<User> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;

    public EmployeeController(
        ApplicationDbContext context,
        UserManager<User> userManager,
        RoleManager<IdentityRole> roleManager)
    {
        _context = context;
        _userManager = userManager;
        _roleManager = roleManager;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var users = await _userManager.Users.ToListAsync();
        var result = new List<object>();

        foreach (var user in users)
        {
            var roles = await _userManager.GetRolesAsync(user);
            var lastAttendance = await _context.AttendanceRecords
                .Where(a => a.UserId == user.Id)
                .OrderByDescending(a => a.CheckInTime)
                .FirstOrDefaultAsync();

            result.Add(new
            {
                user.Id,
                user.UserName,
                user.Email,
                FullName = !string.IsNullOrEmpty(user.Initials) ? user.Initials : user.UserName,
                user.Department,
                user.PhoneNumber,
                user.NfcCardId,
                Role = roles.FirstOrDefault() ?? "User",
                LastCheckIn = lastAttendance != null ? lastAttendance.CheckInTime.ToLocalTime().ToString("yyyy-MM-dd HH:mm") : null,
                LastEnergyScore = lastAttendance?.EnergyScore ?? 85.0,
                LastMood = lastAttendance?.MoodLabel ?? "Bình thường"
            });
        }

        return Ok(new { status = true, data = result });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { status = false, message = "Không tìm thấy nhân viên" });

        var roles = await _userManager.GetRolesAsync(user);
        return Ok(new
        {
            status = true,
            data = new
            {
                user.Id,
                user.UserName,
                user.Email,
                FullName = user.Initials,
                user.Department,
                user.PhoneNumber,
                user.NfcCardId,
                Role = roles.FirstOrDefault() ?? "User"
            }
        });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateEmployeeDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var existingUser = await _userManager.FindByNameAsync(dto.Username);
        if (existingUser != null)
            return BadRequest(new { status = false, message = "Tên đăng nhập đã tồn tại" });

        var user = new User
        {
            UserName = dto.Username,
            Email = dto.Email,
            Initials = dto.FullName ?? dto.Username,
            Department = dto.Department ?? "Công Nghệ & Kỹ Thuật",
            PhoneNumber = dto.PhoneNumber,
            NfcCardId = dto.NfcCardId,
            EmailConfirmed = true
        };

        var result = await _userManager.CreateAsync(user, dto.Password);
        if (!result.Succeeded)
            return BadRequest(new { status = false, message = string.Join("; ", result.Errors.Select(e => e.Description)) });

        var role = string.IsNullOrWhiteSpace(dto.Role) ? "User" : dto.Role;
        if (!await _roleManager.RoleExistsAsync(role))
        {
            await _roleManager.CreateAsync(new IdentityRole(role));
        }
        await _userManager.AddToRoleAsync(user, role);

        return Ok(new
        {
            status = true,
            message = "Tạo hồ sơ nhân viên thành công!",
            data = new { user.Id, user.UserName, user.Email, user.Department, Role = role }
        });
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] UpdateEmployeeDto dto)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { status = false, message = "Không tìm thấy nhân viên" });

        if (!string.IsNullOrEmpty(dto.Email)) user.Email = dto.Email;
        if (!string.IsNullOrEmpty(dto.FullName)) user.Initials = dto.FullName;
        if (!string.IsNullOrEmpty(dto.Department)) user.Department = dto.Department;
        if (dto.PhoneNumber != null) user.PhoneNumber = dto.PhoneNumber;
        if (dto.NfcCardId != null) user.NfcCardId = string.IsNullOrWhiteSpace(dto.NfcCardId) ? null : dto.NfcCardId.Trim().ToUpper();

        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
            return BadRequest(new { status = false, message = string.Join("; ", result.Errors.Select(e => e.Description)) });

        if (!string.IsNullOrEmpty(dto.Role))
        {
            var currentRoles = await _userManager.GetRolesAsync(user);
            await _userManager.RemoveFromRolesAsync(user, currentRoles);
            if (!await _roleManager.RoleExistsAsync(dto.Role))
            {
                await _roleManager.CreateAsync(new IdentityRole(dto.Role));
            }
            await _userManager.AddToRoleAsync(user, dto.Role);
        }

        return Ok(new
        {
            status = true,
            message = "Cập nhật thông tin nhân viên thành công!",
            data = new { user.Id, user.UserName, user.Department, user.NfcCardId }
        });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { status = false, message = "Không tìm thấy nhân viên" });

        if (user.UserName?.ToLower() == "admin")
            return BadRequest(new { status = false, message = "Không thể xóa tài khoản Quản trị viên gốc (Admin)" });

        // Xóa các bản ghi chấm công liên quan trước
        var attendances = await _context.AttendanceRecords.Where(a => a.UserId == user.Id).ToListAsync();
        _context.AttendanceRecords.RemoveRange(attendances);

        var result = await _userManager.DeleteAsync(user);
        if (!result.Succeeded)
            return BadRequest(new { status = false, message = "Không thể xóa nhân viên này" });

        return Ok(new { status = true, message = $"Đã xóa nhân viên {user.UserName} thành công" });
    }

    [HttpPost("seed-sample-employees")]
    public async Task<IActionResult> SeedSampleEmployees()
    {
        var sampleEmployees = new[]
        {
            new { Username = "nguyenvanan", FullName = "Nguyễn Văn An", Email = "an.nguyen@workpulse.vn", Dept = "Kỹ Thuật & Vận Hành", Nfc = "NFC_AN_01", Role = "User" },
            new { Username = "tranminhquan", FullName = "Trần Minh Quân", Email = "quan.tran@workpulse.vn", Dept = "Công Nghệ & Kỹ Thuật", Nfc = "NFC_QUAN_02", Role = "User" },
            new { Username = "lethimai", FullName = "Lê Thị Mai", Email = "mai.le@workpulse.vn", Dept = "Hành Chính & Nhân Sự", Nfc = "NFC_MAI_03", Role = "User" },
            new { Username = "phamhoanglong", FullName = "Phạm Hoàng Long", Email = "long.pham@workpulse.vn", Dept = "Tài Chính & Kế Toán", Nfc = "NFC_LONG_04", Role = "User" },
        };

        int added = 0;
        foreach (var emp in sampleEmployees)
        {
            if (await _userManager.FindByNameAsync(emp.Username) == null)
            {
                var user = new User
                {
                    UserName = emp.Username,
                    Email = emp.Email,
                    Initials = emp.FullName,
                    Department = emp.Dept,
                    NfcCardId = emp.Nfc,
                    EmailConfirmed = true
                };
                await _userManager.CreateAsync(user, "Admin@123");
                await _userManager.AddToRoleAsync(user, emp.Role);
                added++;
            }
        }

        return Ok(new { status = true, message = $"Đã nạp {added} nhân viên mẫu vào hệ thống!", count = added });
    }
}
