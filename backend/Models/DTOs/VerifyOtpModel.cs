using System.ComponentModel.DataAnnotations;

namespace backend.Models.DTOs;

public class VerifyOtpModel
{
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required, StringLength(6, MinimumLength = 6)]
    public string Otp { get; set; } = string.Empty;
}

public class ResendOtpModel
{
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;
}
