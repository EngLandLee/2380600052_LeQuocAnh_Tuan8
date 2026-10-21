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
public class MeetingController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<User> _userManager;

    public MeetingController(ApplicationDbContext context, UserManager<User> userManager)
    {
        _context = context;
        _userManager = userManager;
    }

    private string? GetCurrentUsername() => User.FindFirst(ClaimTypes.Name)?.Value;

    [HttpGet("rooms")]
    public async Task<IActionResult> GetActiveRooms()
    {
        var rooms = await _context.MeetingRooms
            .Include(m => m.HostUser)
            .Where(m => m.IsActive)
            .OrderByDescending(m => m.CreatedAt)
            .Select(m => new
            {
                m.Id,
                m.RoomCode,
                m.Title,
                m.Description,
                HostName = m.HostUser != null ? m.HostUser.UserName : "Admin",
                CreatedAt = m.CreatedAt.ToLocalTime().ToString("yyyy-MM-dd HH:mm"),
                m.MaxParticipants
            })
            .ToListAsync();

        return Ok(new { status = true, data = rooms });
    }

    [HttpPost("create-room")]
    public async Task<IActionResult> CreateRoom([FromBody] CreateRoomDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var username = GetCurrentUsername();
        var user = await _userManager.FindByNameAsync(username ?? "");
        if (user == null) return Unauthorized();

        var roomCode = string.IsNullOrWhiteSpace(dto.RoomCode)
            ? $"STANDUP-{Random.Shared.Next(100, 999)}"
            : dto.RoomCode.Trim().ToUpper();

        var room = new MeetingRoom
        {
            RoomCode = roomCode,
            Title = dto.Title,
            Description = dto.Description,
            HostUserId = user.Id,
            CreatedAt = DateTime.UtcNow,
            IsActive = true
        };

        _context.MeetingRooms.Add(room);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            status = true,
            message = "Đã khởi tạo phòng họp video nhóm thành công!",
            data = new
            {
                room.Id,
                room.RoomCode,
                room.Title,
                room.Description,
                Host = user.UserName
            }
        });
    }

    [HttpPost("close-room/{id}")]
    public async Task<IActionResult> CloseRoom(int id)
    {
        var room = await _context.MeetingRooms.FindAsync(id);
        if (room == null) return NotFound("Không tìm thấy phòng họp");

        room.IsActive = false;
        await _context.SaveChangesAsync();

        return Ok(new { status = true, message = "Đã kết thúc phòng họp nhóm" });
    }
}
