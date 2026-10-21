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
public class AttendanceController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<User> _userManager;

    public AttendanceController(ApplicationDbContext context, UserManager<User> userManager)
    {
        _context = context;
        _userManager = userManager;
    }

    private string? GetCurrentUsername() => User.FindFirst(ClaimTypes.Name)?.Value;

    // 1. Chấm công Face ID hoặc Chấm công Kép (Dual NFC + Face)
    [HttpPost("check-in")]
    public async Task<IActionResult> CheckIn([FromBody] CheckInRequestDto dto)
    {
        var username = GetCurrentUsername();
        if (string.IsNullOrEmpty(username)) return Unauthorized();

        var user = await _userManager.FindByNameAsync(username);
        if (user == null) return NotFound("Không tìm thấy người dùng");

        var today = DateTime.UtcNow.Date;
        var existingRecord = await _context.AttendanceRecords
            .FirstOrDefaultAsync(r => r.UserId == user.Id && r.CheckInTime.Date == today && r.CheckOutTime == null);

        if (existingRecord != null)
        {
            return BadRequest(new
            {
                status = false,
                message = $"Bạn đã chấm công vào ca lúc {existingRecord.CheckInTime.ToLocalTime():HH:mm}. Vui lòng check-out trước khi check-in lại."
            });
        }

        var record = new AttendanceRecord
        {
            UserId = user.Id,
            CheckInTime = DateTime.UtcNow,
            Method = dto.Method,
            EnergyScore = Math.Round(Math.Clamp(dto.EnergyScore, 0.0, 100.0), 1),
            MoodLabel = dto.MoodLabel,
            IsLivenessVerified = dto.IsLivenessVerified,
            DeviceInfo = dto.DeviceInfo,
            Notes = dto.Notes
        };

        _context.AttendanceRecords.Add(record);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            status = true,
            message = $"Chấm công vào ca thành công ({dto.Method})!",
            data = new
            {
                record.Id,
                CheckInTime = record.CheckInTime.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss"),
                record.Method,
                record.EnergyScore,
                record.MoodLabel,
                User = new { user.UserName, user.Email, user.Department }
            }
        });
    }

    // 2. Chấm công siêu tốc bằng thẻ NFC (NFC Badge Tap)
    [HttpPost("check-in-nfc")]
    public async Task<IActionResult> CheckInNfc([FromBody] NfcCheckInDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.NfcCardId))
            return BadRequest(new { status = false, message = "Mã thẻ NFC không được để trống" });

        var cardId = dto.NfcCardId.Trim().ToUpper();
        var user = await _userManager.Users.FirstOrDefaultAsync(u => u.NfcCardId == cardId);

        if (user == null)
        {
            return NotFound(new
            {
                status = false,
                message = $"Thẻ NFC [{cardId}] chưa được liên kết với nhân viên nào. Vui lòng liên hệ Admin để gán thẻ."
            });
        }

        var today = DateTime.UtcNow.Date;
        var existingRecord = await _context.AttendanceRecords
            .FirstOrDefaultAsync(r => r.UserId == user.Id && r.CheckInTime.Date == today && r.CheckOutTime == null);

        if (existingRecord != null)
        {
            // Tự động Check-out nếu đã check-in trước đó
            existingRecord.CheckOutTime = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            var workedHours = (existingRecord.CheckOutTime.Value - existingRecord.CheckInTime).TotalHours;
            return Ok(new
            {
                status = true,
                message = $"Tạm biệt {user.UserName}! Chấm công kết thúc ca thành công qua thẻ NFC.",
                type = "CHECK_OUT",
                workedHours = Math.Round(workedHours, 2),
                record = new
                {
                    existingRecord.Id,
                    CheckInTime = existingRecord.CheckInTime.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss"),
                    CheckOutTime = existingRecord.CheckOutTime.Value.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss"),
                    existingRecord.Method,
                    existingRecord.EnergyScore,
                    existingRecord.MoodLabel
                },
                user = new { user.UserName, user.Department }
            });
        }

        var record = new AttendanceRecord
        {
            UserId = user.Id,
            CheckInTime = DateTime.UtcNow,
            Method = "NFC",
            EnergyScore = 85.0,
            MoodLabel = "Sẵn sàng (NFC Tap)",
            IsLivenessVerified = true,
            DeviceInfo = dto.DeviceInfo,
            Notes = $"Chấm công qua thẻ NFC: {cardId}"
        };

        _context.AttendanceRecords.Add(record);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            status = true,
            message = $"Xin chào {user.UserName}! Chấm công vào ca thành công qua thẻ NFC.",
            type = "CHECK_IN",
            data = new
            {
                record.Id,
                CheckInTime = record.CheckInTime.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss"),
                User = new { user.UserName, user.Department }
            }
        });
    }

    // 3. Chấm công kết thúc ca (Check-out)
    [HttpPost("check-out")]
    public async Task<IActionResult> CheckOut([FromBody] CheckOutRequestDto? dto)
    {
        var username = GetCurrentUsername();
        if (string.IsNullOrEmpty(username)) return Unauthorized();

        var user = await _userManager.FindByNameAsync(username);
        if (user == null) return NotFound("Không tìm thấy người dùng");

        var today = DateTime.UtcNow.Date;
        var record = await _context.AttendanceRecords
            .Where(r => r.UserId == user.Id && r.CheckOutTime == null)
            .OrderByDescending(r => r.CheckInTime)
            .FirstOrDefaultAsync();

        if (record == null)
        {
            return BadRequest(new { status = false, message = "Bạn chưa chấm công vào ca hôm nay để có thể check-out." });
        }

        record.CheckOutTime = DateTime.UtcNow;
        if (dto != null)
        {
            if (!string.IsNullOrEmpty(dto.Method))
            {
                record.Notes = (record.Notes + $" | Check-out via: {dto.Method}").Trim();
            }
            if (dto.EnergyScore.HasValue)
            {
                record.Notes = (record.Notes + $" | Check-out Energy: {dto.EnergyScore.Value}% ({dto.Mood ?? "Bình thường"})").Trim();
            }
            if (!string.IsNullOrEmpty(dto.Notes))
            {
                record.Notes = (record.Notes + " | " + dto.Notes).Trim();
            }
        }

        await _context.SaveChangesAsync();

        var hours = (record.CheckOutTime.Value - record.CheckInTime).TotalHours;
        return Ok(new
        {
            status = true,
            message = $"Chấm công ra về thành công! Tổng thời gian làm việc ca này: {Math.Round(hours, 2)} giờ.",
            record = new
            {
                record.Id,
                CheckInTime = record.CheckInTime.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss"),
                CheckOutTime = record.CheckOutTime.Value.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss"),
                record.Method,
                record.EnergyScore,
                record.MoodLabel,
                TotalHours = Math.Round(hours, 2)
            }
        });
    }

    // 4. Lấy trạng thái chấm công hôm nay của User hiện tại
    [HttpGet("today-status")]
    public async Task<IActionResult> GetTodayStatus()
    {
        var username = GetCurrentUsername();
        if (string.IsNullOrEmpty(username)) return Unauthorized();

        var user = await _userManager.FindByNameAsync(username);
        if (user == null) return NotFound();

        var today = DateTime.UtcNow.Date;
        var record = await _context.AttendanceRecords
            .Where(r => r.UserId == user.Id && r.CheckInTime.Date == today)
            .OrderByDescending(r => r.CheckInTime)
            .FirstOrDefaultAsync();

        return Ok(new
        {
            status = true,
            hasCheckedIn = record != null,
            hasCheckedOut = record?.CheckOutTime != null,
            record = record == null ? null : new
            {
                record.Id,
                CheckInTime = record.CheckInTime.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss"),
                CheckOutTime = record.CheckOutTime?.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss"),
                record.Method,
                record.EnergyScore,
                record.MoodLabel
            }
        });
    }

    // 5. Lịch sử chấm công của User
    [HttpGet("my-history")]
    public async Task<IActionResult> GetMyHistory()
    {
        var username = GetCurrentUsername();
        if (string.IsNullOrEmpty(username)) return Unauthorized();

        var user = await _userManager.FindByNameAsync(username);
        if (user == null) return NotFound();

        var records = await _context.AttendanceRecords
            .Where(r => r.UserId == user.Id)
            .OrderByDescending(r => r.CheckInTime)
            .Take(30)
            .Select(r => new
            {
                r.Id,
                CheckInTime = r.CheckInTime.ToLocalTime().ToString("yyyy-MM-dd HH:mm"),
                CheckOutTime = r.CheckOutTime != null ? r.CheckOutTime.Value.ToLocalTime().ToString("yyyy-MM-dd HH:mm") : null,
                r.Method,
                r.EnergyScore,
                r.MoodLabel,
                r.IsLivenessVerified,
                r.Notes
            })
            .ToListAsync();

        return Ok(new { status = true, data = records });
    }

    // 6. Admin xem toàn bộ danh sách chấm công hôm nay
    [HttpGet("all-today")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllToday()
    {
        var today = DateTime.UtcNow.Date;
        var records = await _context.AttendanceRecords
            .Include(r => r.User)
            .Where(r => r.CheckInTime.Date == today)
            .OrderByDescending(r => r.CheckInTime)
            .Select(r => new
            {
                r.Id,
                r.UserId,
                UserName = r.User != null ? r.User.UserName : "Unknown",
                FullName = r.User != null ? r.User.UserName : "Nhân viên",
                Department = r.User != null ? r.User.Department : "",
                CheckInTime = r.CheckInTime.ToLocalTime().ToString("HH:mm:ss"),
                CheckOutTime = r.CheckOutTime != null ? r.CheckOutTime.Value.ToLocalTime().ToString("HH:mm:ss") : "Đang làm việc",
                r.Method,
                r.EnergyScore,
                Mood = r.MoodLabel,
                Status = r.CheckInTime.Hour <= 8 ? "OnTime" : "Late",
                DetectedBlink = r.IsLivenessVerified
            })
            .ToListAsync();

        return Ok(new { status = true, total = records.Count, data = records });
    }

    // 7. Admin xem biểu đồ phân tích năng lượng & sức khỏe nhân viên (AI Well-being)
    [HttpGet("energy-analytics")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetEnergyAnalytics()
    {
        var recentRecords = await _context.AttendanceRecords
            .Include(r => r.User)
            .Where(r => r.CheckInTime >= DateTime.UtcNow.AddDays(-7))
            .ToListAsync();

        var avgEnergy = recentRecords.Any() ? Math.Round(recentRecords.Average(r => r.EnergyScore), 1) : 75.0;

        var moodCounts = recentRecords
            .GroupBy(r => r.MoodLabel)
            .ToDictionary(g => g.Key, g => g.Count());

        // Nhân viên có năng lượng thấp (< 50%) cần lưu tâm
        var fatigueAlerts = recentRecords
            .Where(r => r.EnergyScore < 50.0 && r.User != null)
            .Select(r => new
            {
                r.User!.UserName,
                r.User.Department,
                Date = r.CheckInTime.ToLocalTime().ToString("yyyy-MM-dd"),
                r.EnergyScore,
                r.MoodLabel
            })
            .ToList();

        return Ok(new
        {
            status = true,
            averageEnergy = avgEnergy,
            totalCheckInsThisWeek = recentRecords.Count,
            moodDistribution = moodCounts,
            fatigueAlerts = fatigueAlerts
        });
    }

    // 8. Đăng ký / Gán thẻ từ NFC cho nhân viên
    [HttpPost("register-nfc")]
    public async Task<IActionResult> RegisterNfcCard([FromBody] RegisterNfcCardDto dto)
    {
        var username = GetCurrentUsername();
        var targetUser = await _userManager.FindByNameAsync(username ?? "");

        // Nếu Admin truyền TargetUserId thì tìm theo Id hoặc Username
        if (User.IsInRole("Admin") && !string.IsNullOrEmpty(dto.TargetUserId))
        {
            targetUser = await _userManager.FindByIdAsync(dto.TargetUserId)
                         ?? await _userManager.FindByNameAsync(dto.TargetUserId);
        }

        if (targetUser == null) return NotFound("Không tìm thấy người dùng");

        var cleanCardId = dto.NfcCardId.Trim().ToUpper();
        targetUser.NfcCardId = cleanCardId;
        await _userManager.UpdateAsync(targetUser);

        return Ok(new
        {
            status = true,
            message = $"Đã liên kết thành công thẻ NFC [{cleanCardId}] với tài khoản {targetUser.UserName}."
        });
    }

    // 9. Lấy thông tin hồ sơ nhân viên hiện tại (Kiểm tra đã liên kết thẻ CCCD hay chưa)
    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var username = GetCurrentUsername();
        if (string.IsNullOrEmpty(username)) return Unauthorized();

        var user = await _userManager.FindByNameAsync(username);
        if (user == null) return NotFound("Không tìm thấy người dùng");

        return Ok(new
        {
            status = true,
            data = new
            {
                user.Id,
                user.UserName,
                user.Email,
                user.Department,
                user.NfcCardId,
                HasLinkedNfc = !string.IsNullOrEmpty(user.NfcCardId)
            }
        });
    }
}
