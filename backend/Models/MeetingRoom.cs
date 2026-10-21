using System.ComponentModel.DataAnnotations;

namespace backend.Models;

public class MeetingRoom
{
    public int Id { get; set; }

    [Required, MaxLength(50)]
    public string RoomCode { get; set; } = string.Empty;

    [Required, MaxLength(150)]
    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    [Required]
    public string HostUserId { get; set; } = string.Empty;

    public User? HostUser { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public bool IsActive { get; set; } = true;

    public int MaxParticipants { get; set; } = 20;
}
