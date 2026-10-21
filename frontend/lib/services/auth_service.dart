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

  // Gửi OTP qua Gmail khi đăng ký
  Future<Map<String, dynamic>> registerSendOtp({
    required String username,
    required String email,
    required String password,
    String? initials,
    String? role,
  }) async {
    try {
      final response = await _api.post('Authenticate/register-send-otp', {
        'username': username,
        'email': email,
        'password': password,
        'initials': initials,
        'role': role ?? 'User',
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mã OTP đã được gửi về Gmail của bạn',
          'devOtp': data['devOtp'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gửi OTP thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Xác thực OTP để hoàn tất tạo tài khoản
  Future<Map<String, dynamic>> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _api.post('Authenticate/verify-register-otp', {
        'email': email,
        'otp': otp,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Xác thực tài khoản thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Mã OTP không hợp lệ',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Gửi lại mã OTP
  Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      final response = await _api.post('Authenticate/resend-otp', {
        'email': email,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã gửi lại mã OTP mới',
          'devOtp': data['devOtp'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gửi lại OTP thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Giữ phương thức đăng ký trực tiếp tương thích ngược
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
