import 'dart:convert';
import 'api_client.dart';
import '../models/attendance_record.dart';
import '../models/citizen_card_info.dart';
import '../models/energy_analytics.dart';
import '../utils/auth_helper.dart';

class AttendanceService {
  final ApiClient _client;

  AttendanceService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Check-in bằng Face ID hoặc Dual-Factor
  Future<Map<String, dynamic>> checkInFace({
    required String photoBase64,
    required double energyScore,
    required String mood,
    required bool detectedBlink,
    String? deviceInfo,
    String method = 'FaceID',
  }) async {
    final response = await _client.post('attendance/check-in', {
      'method': method,
      'photoBase64': photoBase64,
      'energyScore': energyScore,
      'mood': mood,
      'detectedBlink': detectedBlink,
      'deviceInfo': deviceInfo ?? 'Flutter Android Client',
    });

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final rawRec = data['record'] ?? data['data'];
      return {
        'success': true,
        'message': data['message'] ?? 'Check-in thành công!',
        'record': rawRec != null ? AttendanceRecord.fromJson(rawRec) : null,
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Check-in thất bại: ${response.statusCode}',
      };
    }
  }

  /// Check-in 1 chạm bằng thẻ NFC
  Future<Map<String, dynamic>> checkInNfc(String nfcCardId) async {
    final response = await _client.post('attendance/check-in-nfc', {
      'nfcCardId': nfcCardId,
    });

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final rawRec = data['record'] ?? data['data'];
      return {
        'success': true,
        'message': data['message'] ?? 'Chấm công thẻ NFC thành công!',
        'record': rawRec != null ? AttendanceRecord.fromJson(rawRec) : null,
        'user': data['user'],
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Không nhận diện được thẻ NFC ($nfcCardId)',
      };
    }
  }

  /// Check-out cuối ca (Hỗ trợ xác thực Face ID hoặc Thẻ NFC/CCCD)
  Future<Map<String, dynamic>> checkOut({
    String method = 'FaceID',
    double? energyScore,
    String? mood,
    bool? detectedBlink,
    String? photoBase64,
    String? nfcCardId,
  }) async {
    final response = await _client.post('attendance/check-out', {
      'method': method,
      'energyScore': energyScore,
      'mood': mood,
      'detectedBlink': detectedBlink ?? true,
      'photoBase64': photoBase64,
      'nfcCardId': nfcCardId,
    });
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final rawRec = data['record'] ?? data['data'];
      return {
        'success': true,
        'message': data['message'] ?? 'Check-out thành công!',
        'record': rawRec != null ? AttendanceRecord.fromJson(rawRec) : null,
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Check-out thất bại: ${response.statusCode}',
      };
    }
  }

  /// Trạng thái chấm công hôm nay
  Future<Map<String, dynamic>> getTodayStatus() async {
    try {
      final response = await _client.get('attendance/today-status');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawRecord = data['todayRecord'] ?? data['record'];
        return {
          'hasCheckedIn': data['hasCheckedIn'] as bool? ?? false,
          'hasCheckedOut': data['hasCheckedOut'] as bool? ?? false,
          'todayRecord': rawRecord != null
              ? AttendanceRecord.fromJson(rawRecord as Map<String, dynamic>)
              : null,
        };
      }
    } catch (_) {}
    return {'hasCheckedIn': false, 'hasCheckedOut': false, 'todayRecord': null};
  }

  /// Lịch sử chấm công của tôi
  Future<List<AttendanceRecord>> getMyHistory({int days = 30}) async {
    try {
      final response = await _client.get('attendance/my-history?days=$days');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List
            ? decoded
            : (decoded['data'] as List<dynamic>? ?? []);
        return data.map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Danh sách tất cả nhân viên check-in hôm nay (Dành cho Quản lý / Admin)
  Future<List<AttendanceRecord>> getAllTodayRecords() async {
    try {
      final response = await _client.get('attendance/all-today');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List
            ? decoded
            : (decoded['data'] as List<dynamic>? ?? []);
        return data.map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Báo cáo Phân tích Năng lượng & Cảnh báo Kiệt sức (Admin / Quản lý)
  Future<EnergyAnalytics?> getEnergyAnalytics() async {
    try {
      final response = await _client.get('attendance/energy-analytics');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EnergyAnalytics.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Lấy thông tin hồ sơ nhân viên và trạng thái liên kết thẻ CCCD/NFC
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final response = await _client.get('attendance/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  /// Gán thẻ NFC cho nhân viên (Admin)
  Future<bool> registerNfcCard(String userId, String nfcCardId) async {
    try {
      final response = await _client.post('attendance/register-nfc', {
        'targetUserId': userId,
        'userId': userId,
        'nfcCardId': nfcCardId,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Trích xuất toàn bộ thông tin cá nhân từ con chip CCCD (eKYC Reader)
  Future<CitizenCardInfo?> readCccdInfo(String nfcCardId) async {
    try {
      final response = await _client.post('attendance/read-cccd-info', {
        'nfcCardId': nfcCardId,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return CitizenCardInfo.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Nhân viên tự liên kết thẻ CCCD của mình lúc mới vào công ty (CCCD Onboarding)
  Future<Map<String, dynamic>> linkMyCccd(String nfcCardId) async {
    try {
      final response = await _client.post('attendance/register-nfc', {
        'nfcCardId': nfcCardId,
      });
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Liên kết thẻ thành công!',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  /// Đăng ký toàn bộ góc mặt 3D cho nhân viên mới (Face Enrollment)
  Future<Map<String, dynamic>> registerFace({
    required String photoBase64,
    String? faceAngleSummary,
    String? username,
  }) async {
    try {
      final uname = username ?? await AuthHelper.getUsername();
      // Giới hạn kích thước payload ảnh Base64 nếu quá lớn để tránh nghẽn mạng
      final safePhoto = photoBase64.length > 50000 ? photoBase64.substring(0, 50000) : photoBase64;
      final response = await _client.post('attendance/register-face', {
        'username': uname,
        'photoBase64': safePhoto,
        'faceAngleSummary': faceAngleSummary ?? '3D Face Scanned: Front, Left, Right, Smile',
        'deviceInfo': 'WorkPulse 3D Biometric Camera',
      });

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'message': data['message'] ?? 'Đăng ký khuôn mặt 3D thành công!',
          };
        }
        return {'success': true, 'message': 'Đăng ký khuôn mặt 3D thành công!'};
      } else {
        String msg = 'Đăng ký không thành công (${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            msg = data['message'] ?? data['title'] ?? msg;
          } catch (_) {}
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }
}
