using backend.Models;
using backend.Models.DTOs;
using Microsoft.Extensions.Caching.Memory;

namespace backend.Services;

public class OtpService : IOtpService
{
    private readonly IMemoryCache _cache;
    private static readonly TimeSpan OtpLifetime = TimeSpan.FromMinutes(5);

    public OtpService(IMemoryCache cache)
    {
        _cache = cache;
    }

    private static string GetCacheKey(string email) => $"otp_reg_{email.ToLower().Trim()}";

    public string GenerateOtp(RegistrationModel registrationData)
    {
        var email = registrationData.Email.ToLower().Trim();
        var otpCode = Random.Shared.Next(100000, 999999).ToString();

        var pending = new PendingRegistration
        {
            RegistrationData = registrationData,
            OtpCode = otpCode,
            CreatedAt = DateTime.UtcNow,
            ExpiryTime = DateTime.UtcNow.Add(OtpLifetime),
            FailedAttempts = 0
        };

        _cache.Set(GetCacheKey(email), pending, OtpLifetime);
        return otpCode;
    }

    public (bool Success, string Message, RegistrationModel? Data) VerifyOtp(string email, string otp)
    {
        var key = GetCacheKey(email);
        if (!_cache.TryGetValue<PendingRegistration>(key, out var pending) || pending == null)
        {
            return (false, "Mã OTP đã hết hạn hoặc không tồn tại. Vui lòng gửi lại mã.", null);
        }

        if (DateTime.UtcNow > pending.ExpiryTime)
        {
            _cache.Remove(key);
            return (false, "Mã OTP đã hết hiệu lực (quá 5 phút). Vui lòng gửi lại mã.", null);
        }

        if (pending.FailedAttempts >= 5)
        {
            _cache.Remove(key);
            return (false, "Bạn đã nhập sai quá 5 lần. Mã OTP đã bị hủy, vui lòng đăng ký lại.", null);
        }

        if (pending.OtpCode != otp.Trim())
        {
            pending.FailedAttempts++;
            _cache.Set(key, pending, pending.ExpiryTime - DateTime.UtcNow);
            return (false, $"Mã OTP không chính xác. Bạn còn {5 - pending.FailedAttempts} lần thử.", null);
        }

        // Correct OTP -> remove from cache and return data
        _cache.Remove(key);
        return (true, "Xác thực thành công", pending.RegistrationData);
    }

    public (bool Success, string Message, string? NewOtp) ResendOtp(string email)
    {
        var key = GetCacheKey(email);
        if (!_cache.TryGetValue<PendingRegistration>(key, out var pending) || pending == null)
        {
            return (false, "Không tìm thấy yêu cầu đăng ký cho email này. Vui lòng đăng ký lại.", null);
        }

        var newOtp = Random.Shared.Next(100000, 999999).ToString();
        pending.OtpCode = newOtp;
        pending.ExpiryTime = DateTime.UtcNow.Add(OtpLifetime);
        pending.FailedAttempts = 0;

        _cache.Set(key, pending, OtpLifetime);
        return (true, "Đã tạo mã OTP mới thành công", newOtp);
    }
}
