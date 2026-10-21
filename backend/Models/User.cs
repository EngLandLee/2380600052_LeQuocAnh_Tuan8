using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace backend.Models;

public class User : IdentityUser
{
    [MaxLength(5)]
    public string? Initials { get; set; }

    [MaxLength(50)]
    public string? NfcCardId { get; set; }

    [MaxLength(100)]
    public string? Department { get; set; } = "Công Nghệ & Kỹ Thuật";

    public string? AvatarUrl { get; set; }

    public bool IsFaceRegistered { get; set; } = false;

    public DateTime? FaceRegisteredAt { get; set; }

    public string? FaceData { get; set; }

    [JsonIgnore]
    public ICollection<AttendanceRecord> AttendanceRecords { get; set; } = new List<AttendanceRecord>();
}
