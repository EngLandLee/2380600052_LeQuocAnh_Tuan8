import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigUrl {
  static const String defaultCloudflareUrl = "https://blocked-betting-adsl-opens.trycloudflare.com/api/";
  static const String defaultLanUrl = "http://192.168.1.14:5000/api/";

  static String? _customBaseUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBaseUrl = prefs.getString('custom_base_url');
      // Nếu bộ nhớ đệm lưu localhost thì tự động xóa để tránh lỗi trên thiết bị thật
      if (_customBaseUrl != null &&
          (_customBaseUrl!.contains('localhost') || _customBaseUrl!.contains('127.0.0.1'))) {
        _customBaseUrl = null;
        await prefs.remove('custom_base_url');
      }
    } catch (_) {}
  }

  static Future<void> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    var cleanUrl = url.trim();
    if (!cleanUrl.endsWith('/')) {
      cleanUrl = '$cleanUrl/';
    }
    if (!cleanUrl.endsWith('api/')) {
      cleanUrl = '${cleanUrl}api/';
    }
    await prefs.setString('custom_base_url', cleanUrl);
    _customBaseUrl = cleanUrl;
  }

  static String get baseUrl {
    if (_customBaseUrl != null &&
        _customBaseUrl!.isNotEmpty &&
        !_customBaseUrl!.contains('localhost') &&
        !_customBaseUrl!.contains('127.0.0.1')) {
      return _customBaseUrl!;
    }
    if (dotenv.isInitialized) {
      final raw = dotenv.env['BASE_URL'] ?? dotenv.env['API_BASE_URL'];
      if (raw != null &&
          raw.isNotEmpty &&
          !raw.contains('localhost') &&
          !raw.contains('127.0.0.1')) {
        var clean = raw.trim();
        if (!clean.endsWith('/')) clean = '$clean/';
        if (!clean.endsWith('api/')) clean = '${clean}api/';
        return clean;
      }
    }
    // Mặc định kết nối Cloudflare Tunnel (Hoạt động trên cả Wi-Fi và 4G/Internet)
    return defaultCloudflareUrl;
  }

  static String get currentDisplayUrl => baseUrl;
}
