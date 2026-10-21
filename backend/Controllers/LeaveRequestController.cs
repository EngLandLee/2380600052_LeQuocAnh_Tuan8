using backend.Data;
using backend.Models;
using backend.Models.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class LeaveRequestController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<User> _userManager;

    public LeaveRequestController(ApplicationDbContext context, UserManager<User> userManager)
    {
        _context = context;
        _userManager = userManager;
    }

    private string? GetCurrentUsername() => User.FindFirst(ClaimTypes.Name)?.Value;

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var username = GetCurrentUsername();
        var user = await _userManager.FindByNameAsync(username ?? "");
        if (user == null) return Unauthorized();

        var roles = await _userManager.GetRolesAsync(user);
        var isAdmin = roles.Contains("Admin");

        var query = _context.LeaveRequests
            .Include(l => l.User)
            .AsQueryable();

        // Nếu là nhân viên thường, chỉ xem đơn của chính mình
        if (!isAdmin)
        {
            query = query.Where(l => l.UserId == user.Id);
        }

        var list = await query
            .OrderByDescending(l => l.CreatedAt)
            .Select(l => new
            {
                l.Id,
                l.UserId,
                EmployeeName = l.User != null ? (l.User.Initials ?? l.User.UserName) : "Nhân viên",
                Department = l.User != null ? l.User.Department : "",
                l.LeaveType,
                StartDate = l.StartDate.ToString("yyyy-MM-dd"),
                EndDate = l.EndDate.ToString("yyyy-MM-dd"),
                l.Reason,
                l.Status,
                CreatedAt = l.CreatedAt.ToLocalTime().ToString("yyyy-MM-dd HH:mm"),
                l.ReviewedBy,
                l.ReviewNote
            })
            .ToListAsync();

        return Ok(new { status = true, data = list, isAdmin });
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateLeaveRequestDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var username = GetCurrentUsername();
        var user = await _userManager.FindByNameAsync(username ?? "");
        if (user == null) return Unauthorized();

        if (dto.EndDate < dto.StartDate)
        {
            return BadRequest(new { status = false, message = "Ngày kết thúc không thể trước ngày bắt đầu" });
        }

        var request = new LeaveRequest
        {
            UserId = user.Id,
            LeaveType = dto.LeaveType,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            Reason = dto.Reason,
            Status = "Chờ duyệt",
            CreatedAt = DateTime.UtcNow
        };

        _context.LeaveRequests.Add(request);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            status = true,
            message = "Tạo đơn xin nghỉ phép / đổi ca thành công!",
            data = new { request.Id, request.LeaveType, request.Status }
        });
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateLeaveRequestDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var request = await _context.LeaveRequests.FindAsync(id);
        if (request == null) return NotFound(new { status = false, message = "Không tìm thấy đơn" });

        var username = GetCurrentUsername();
        var user = await _userManager.FindByNameAsync(username ?? "");
        if (user == null) return Unauthorized();

        var roles = await _userManager.GetRolesAsync(user);
        if (request.UserId != user.Id && !roles.Contains("Admin"))
            return Forbid();

        if (request.Status != "Chờ duyệt" && !roles.Contains("Admin"))
        {
            return BadRequest(new { status = false, message = "Đơn đã được phê duyệt, không thể chỉnh sửa" });
        }

        request.LeaveType = dto.LeaveType;
        request.StartDate = dto.StartDate;
        request.EndDate = dto.EndDate;
        request.Reason = dto.Reason;

        await _context.SaveChangesAsync();

        return Ok(new { status = true, message = "Cập nhật đơn thành công!", data = request });
    }

    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateLeaveStatusDto dto)
    {
        var request = await _context.LeaveRequests.Include(l => l.User).FirstOrDefaultAsync(l => l.Id == id);
        if (request == null) return NotFound(new { status = false, message = "Không tìm thấy đơn" });

        var username = GetCurrentUsername();
        request.Status = dto.Status;
        request.ReviewedBy = username ?? "Admin";
        request.ReviewNote = dto.ReviewNote ?? (dto.Status == "Đã duyệt" ? "Đã phê duyệt ca nghỉ" : "Từ chối");

        await _context.SaveChangesAsync();

        return Ok(new
        {
            status = true,
            message = $"Đã {dto.Status.ToLower()} đơn của nhân viên thành công!",
            data = request
        });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var request = await _context.LeaveRequests.FindAsync(id);
        if (request == null) return NotFound(new { status = false, message = "Không tìm thấy đơn" });

        var username = GetCurrentUsername();
        var user = await _userManager.FindByNameAsync(username ?? "");
        var roles = user != null ? await _userManager.GetRolesAsync(user) : new List<string>();

        if (request.UserId != user?.Id && !roles.Contains("Admin"))
            return Forbid();

        _context.LeaveRequests.Remove(request);
        await _context.SaveChangesAsync();

        return Ok(new { status = true, message = "Đã hủy đơn thành công" });
    }

    [HttpPost("seed-sample")]
    public async Task<IActionResult> SeedSample()
    {
        if (await _context.LeaveRequests.AnyAsync())
        {
            return Ok(new { status = true, message = "Dữ liệu đơn xin nghỉ đã có sẵn." });
        }

        var users = await _userManager.Users.Take(3).ToListAsync();
        if (!users.Any()) return BadRequest(new { status = false, message = "Chưa có nhân viên nào trong hệ thống" });

        var sample = new List<LeaveRequest>
        {
            new()
            {
                UserId = users.First().Id,
                LeaveType = "Nghỉ phép năm",
                StartDate = DateTime.UtcNow.AddDays(2),
                EndDate = DateTime.UtcNow.AddDays(4),
                Reason = "Đi công việc gia đình ở quê Đắk Lắk",
                Status = "Chờ duyệt",
                CreatedAt = DateTime.UtcNow.AddHours(-5)
            },
            new()
            {
                UserId = users.Last().Id,
                LeaveType = "Nghỉ ốm hưởng BHXH",
                StartDate = DateTime.UtcNow.AddDays(-2),
                EndDate = DateTime.UtcNow.AddDays(-1),
                Reason = "Bị sốt xuất huyết có giấy xác nhận của Bệnh viện",
                Status = "Đã duyệt",
                ReviewedBy = "admin",
                ReviewNote = "Đã nhận giấy khám bệnh, chúc bạn sớm bình phục.",
                CreatedAt = DateTime.UtcNow.AddDays(-3)
            }
        };

        _context.LeaveRequests.AddRange(sample);
        await _context.SaveChangesAsync();

        return Ok(new { status = true, message = "Đã nạp 2 đơn nghỉ phép mẫu thành công!", count = sample.Count });
    }
}
