using System.ComponentModel.DataAnnotations;

namespace backend.Models.DTOs;

public class CreateEmployeeDto
{
    [Required, MaxLength(50)]
    public string Username { get; set; } = string.Empty;

    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    public string? FullName { get; set; }

    [Required, MinLength(6)]
    public string Password { get; set; } = "Admin@123";

    public string? Department { get; set; } = "Công Nghệ & Kỹ Thuật";

    public string? PhoneNumber { get; set; }

    public string? NfcCardId { get; set; }

    public string Role { get; set; } = "User"; // Admin, User, Guest
}

public class UpdateEmployeeDto
{
    [EmailAddress]
    public string? Email { get; set; }

    public string? FullName { get; set; }

    public string? Department { get; set; }

    public string? PhoneNumber { get; set; }

    public string? NfcCardId { get; set; }

    public string? Role { get; set; }
}
