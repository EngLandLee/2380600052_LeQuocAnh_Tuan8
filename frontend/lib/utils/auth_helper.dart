import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static const String tokenKey = 'jwt_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    try {
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }

  static Future<String> getRole() async {
    final token = await getToken();
    if (token == null) return 'User';
    try {
      final decoded = JwtDecoder.decode(token);
      final role = decoded['role'] ??
          decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      return role?.toString() ?? 'User';
    } catch (_) {
      return 'User';
    }
  }

  static Future<String> getUsername() async {
    final token = await getToken();
    if (token == null) return '';
    try {
      final decoded = JwtDecoder.decode(token);
      final name = decoded['unique_name'] ??
          decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
          decoded['name'];
      return name?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }
}
