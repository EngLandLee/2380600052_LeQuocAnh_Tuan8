import 'dart:convert';
import 'api_client.dart';
import '../utils/auth_helper.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _api.post('Authenticate/login', {
        'username': username,
        'password': password,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final token = data['token'] as String;
        await AuthHelper.saveToken(token);
        final role = await AuthHelper.getRole();
        return {
          'success': true,
          'token': token,
          'role': role,
          'message': data['message'] ?? 'Đăng nhập thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? initials,
    String? role,
  }) async {
    try {
      final response = await _api.post('Authenticate/register', {
        'username': username,
        'email': email,
        'password': password,
        'initials': initials,
        'role': role ?? 'User',
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Đăng ký thành công'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng ký thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
