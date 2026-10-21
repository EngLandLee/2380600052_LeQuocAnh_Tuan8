using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models;

public class LeaveRequest
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;

    [ForeignKey("UserId")]
    public virtual User? User { get; set; }

    [Required, MaxLength(100)]
    public string LeaveType { get; set; } = "Nghỉ phép năm"; // Nghỉ phép năm, Nghỉ ốm, Đi công tác, Việc riêng

    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime EndDate { get; set; }

    [Required, MaxLength(500)]
    public string Reason { get; set; } = string.Empty;

    [Required, MaxLength(50)]
    public string Status { get; set; } = "Chờ duyệt"; // Chờ duyệt, Đã duyệt, Từ chối

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public string? ReviewedBy { get; set; }

    public string? ReviewNote { get; set; }
}
