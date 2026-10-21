import 'dart:convert';
import '../models/leave_request.dart';
import 'api_client.dart';

class LeaveRequestService {
  final ApiClient _api = ApiClient();

  Future<List<LeaveRequest>> getAll() async {
    try {
      final response = await _api.get('LeaveRequest');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List;
        return list.map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> create({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      final response = await _api.post('LeaveRequest', {
        'leaveType': leaveType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(
    int id, {
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      final response = await _api.put('LeaveRequest/$id', {
        'leaveType': leaveType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus(int id, String status, {String? reviewNote}) async {
    try {
      final response = await _api.put('LeaveRequest/$id/status', {
        'status': status,
        'reviewNote': reviewNote,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      final response = await _api.delete('LeaveRequest/$id');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> seedSample() async {
    try {
      final response = await _api.post('LeaveRequest/seed-sample', {});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
