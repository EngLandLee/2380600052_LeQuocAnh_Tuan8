using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace backend.Models;

public class AttendanceRecord
{
    public int Id { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;

    public User? User { get; set; }

    public DateTime CheckInTime { get; set; } = DateTime.UtcNow;

    public DateTime? CheckOutTime { get; set; }

    [Required, MaxLength(30)]
    public string Method { get; set; } = "FaceID"; // "FaceID", "NFC", "Dual_NFC_Face", "Manual"

    public double EnergyScore { get; set; } = 80.0; // 0 - 100%

    [MaxLength(50)]
    public string MoodLabel { get; set; } = "Tươi tắn, sẵn sàng";

    public bool IsLivenessVerified { get; set; } = true;

    [MaxLength(100)]
    public string? DeviceInfo { get; set; }

    [MaxLength(250)]
    public string? Notes { get; set; }
}
