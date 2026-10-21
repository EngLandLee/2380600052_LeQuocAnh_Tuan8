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
      return {
        'success': true,
        'message': data['message'] ?? 'Check-in thành công!',
        'record': AttendanceRecord.fromJson(data['record']),
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
      return {
        'success': true,
        'message': data['message'] ?? 'Chấm công thẻ NFC thành công!',
        'record': AttendanceRecord.fromJson(data['record']),
        'user': data['user'],
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Không nhận diện được thẻ NFC ($nfcCardId)',
      };
    }
  }

  /// Check-out cuối ca
  Future<Map<String, dynamic>> checkOut() async {
    final response = await _client.post('attendance/check-out', {});
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'] ?? 'Check-out thành công!',
        'record': AttendanceRecord.fromJson(data['record']),
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
    final response = await _client.get('attendance/today-status');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'hasCheckedIn': data['hasCheckedIn'] as bool? ?? false,
        'hasCheckedOut': data['hasCheckedOut'] as bool? ?? false,
        'todayRecord': data['todayRecord'] != null
            ? AttendanceRecord.fromJson(data['todayRecord'])
            : null,
      };
    }
    return {'hasCheckedIn': false, 'hasCheckedOut': false, 'todayRecord': null};
  }

  /// Lịch sử chấm công của tôi
  Future<List<AttendanceRecord>> getMyHistory({int days = 30}) async {
    final response = await _client.get('attendance/my-history?days=$days');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => AttendanceRecord.fromJson(item)).toList();
    }
    return [];
  }

  /// Danh sách tất cả nhân viên check-in hôm nay (Dành cho Quản lý / Admin)
  Future<List<AttendanceRecord>> getAllTodayRecords() async {
    final response = await _client.get('attendance/all-today');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => AttendanceRecord.fromJson(item)).toList();
    }
    return [];
  }

  /// Báo cáo Phân tích Năng lượng & Cảnh báo Kiệt sức (Admin / Quản lý)
  Future<EnergyAnalytics?> getEnergyAnalytics() async {
    final response = await _client.get('attendance/energy-analytics');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EnergyAnalytics.fromJson(data);
    }
    return null;
  }

  /// Gán thẻ NFC cho nhân viên (Admin)
  Future<bool> registerNfcCard(String userId, String nfcCardId) async {
    final response = await _client.post('attendance/register-nfc', {
      'userId': userId,
      'nfcCardId': nfcCardId,
    });
    return response.statusCode == 200;
  }
}
