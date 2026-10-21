namespace backend.Services;

public interface IEmailService
{
    Task<bool> SendOtpEmailAsync(string toEmail, string username, string otpCode);
}
