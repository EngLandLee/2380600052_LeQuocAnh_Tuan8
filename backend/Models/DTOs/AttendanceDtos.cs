using System.ComponentModel.DataAnnotations;

namespace backend.Models.DTOs;

public class CheckInRequestDto
{
    public string Method { get; set; } = "FaceID"; // "FaceID", "Dual_NFC_Face", "Manual"
    public double EnergyScore { get; set; } = 80.0;
    public string MoodLabel { get; set; } = "Tươi tắn, sẵn sàng";
    public bool IsLivenessVerified { get; set; } = true;
    public string? NfcCardId { get; set; }
    public string? DeviceInfo { get; set; }
    public string? Notes { get; set; }
}

public class NfcCheckInDto
{
    [Required]
    public string NfcCardId { get; set; } = string.Empty;
    public string? DeviceInfo { get; set; }
}

public class CheckOutRequestDto
{
    public string? Notes { get; set; }
}

public class RegisterNfcCardDto
{
    [Required]
    public string NfcCardId { get; set; } = string.Empty;
    public string? TargetUserId { get; set; } // Nếu Admin gán cho nhân viên
}

public class CreateRoomDto
{
    [Required, MaxLength(150)]
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? RoomCode { get; set; }
}
