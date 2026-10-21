using backend.Models.DTOs;

namespace backend.Models;

public class PendingRegistration
{
    public RegistrationModel RegistrationData { get; set; } = null!;
    public string OtpCode { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiryTime { get; set; } = DateTime.UtcNow.AddMinutes(5);
    public int FailedAttempts { get; set; } = 0;
}
