import 'dart:convert';
import 'api_client.dart';
import '../models/attendance_record.dart';
import '../models/energy_analytics.dart';

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
}
