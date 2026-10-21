using System.Net;
using System.Net.Mail;

namespace backend.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<bool> SendOtpEmailAsync(string toEmail, string username, string otpCode)
    {
        var settings = _configuration.GetSection("EmailSettings");
        var senderEmail = settings["SenderEmail"];
        var appPassword = settings["AppPassword"];
        var smtpServer = settings["SmtpServer"] ?? "smtp.gmail.com";
        var port = int.TryParse(settings["Port"], out var p) ? p : 587;
        var senderName = settings["SenderName"] ?? "LTDD Hutech App";

        // Console Dev Banner always prints for easy test/debug
        Console.WriteLine("\n=======================================================");
        Console.WriteLine($"[EMAIL SERVICE] GỬI MÃ OTP TỚI: {toEmail}");
        Console.WriteLine($"[EMAIL SERVICE] NGƯỜI DÙNG: {username}");
        Console.WriteLine($"[EMAIL SERVICE] >>> MÃ XÁC THỰC OTP: [ {otpCode} ] <<<");
        Console.WriteLine($"[EMAIL SERVICE] HẾT HẠN SAU: 5 PHÚT");
        Console.WriteLine("=======================================================\n");

        if (string.IsNullOrWhiteSpace(senderEmail) || string.IsNullOrWhiteSpace(appPassword))
        {
            _logger.LogInformation("Chế độ Dev: Chưa cấu hình SenderEmail/AppPassword trong appsettings.json. Mã OTP đã được in ra console.");
            return true;
        }

        try
        {
            using var client = new SmtpClient(smtpServer, port)
            {
                Credentials = new NetworkCredential(senderEmail, appPassword),
                EnableSsl = true,
                Timeout = 10000
            };

            var mail = new MailMessage
            {
                From = new MailAddress(senderEmail, senderName),
                Subject = $"[{otpCode}] Mã xác thực OTP đăng ký tài khoản",
                IsBodyHtml = true,
                Body = $@"
                    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;'>
                        <h2 style='color: #1a73e8; text-align: center;'>Xác Thực Đăng Ký Tài Khoản</h2>
                        <p>Xin chào <strong>{username}</strong>,</p>
                        <p>Bạn đang thực hiện đăng ký tài khoản trên ứng dụng <strong>LTDD App</strong>. Dưới đây là mã xác thực OTP của bạn:</p>
                        <div style='text-align: center; margin: 30px 0;'>
                            <span style='font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1a73e8; background: #e8f0fe; padding: 12px 24px; border-radius: 8px; display: inline-block;'>{otpCode}</span>
                        </div>
                        <p style='color: #555;'>Mã xác thực này có hiệu lực trong vòng <strong>5 phút</strong>. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
                        <hr style='border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;' />
                        <p style='font-size: 12px; color: #888; text-align: center;'>Nếu bạn không yêu cầu đăng ký tài khoản, vui lòng bỏ qua email này.</p>
                    </div>"
            };
            mail.To.Add(toEmail);

            await client.SendMailAsync(mail);
            _logger.LogInformation("Đã gửi email OTP thành công tới {ToEmail} qua Gmail SMTP", toEmail);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi gửi email qua SMTP tới {ToEmail}. Fallback dùng mã đã in ra console.", toEmail);
            return true; // Return true so registration flow is not blocked when testing without network/app password
        }
    }
}
