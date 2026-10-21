using backend.Models;
using backend.Models.DTOs;

namespace backend.Services;

public interface IOtpService
{
    string GenerateOtp(RegistrationModel registrationData);
    (bool Success, string Message, RegistrationModel? Data) VerifyOtp(string email, string otp);
    (bool Success, string Message, string? NewOtp) ResendOtp(string email);
}
