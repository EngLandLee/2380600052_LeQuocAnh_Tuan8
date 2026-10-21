using System.ComponentModel.DataAnnotations;

namespace backend.Models.DTOs;

public class CreateLeaveRequestDto
{
    [Required]
    public string LeaveType { get; set; } = "Nghỉ phép năm";

    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime EndDate { get; set; }

    [Required, MaxLength(500)]
    public string Reason { get; set; } = string.Empty;
}

public class UpdateLeaveStatusDto
{
    [Required]
    public string Status { get; set; } = "Đã duyệt"; // Đã duyệt, Từ chối

    public string? ReviewNote { get; set; }
}
