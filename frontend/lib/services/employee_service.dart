import 'dart:convert';
import '../models/employee.dart';
import 'api_client.dart';

class EmployeeService {
  final ApiClient _api = ApiClient();

  Future<List<Employee>> getAll() async {
    try {
      final response = await _api.get('Employee');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List;
        return list.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> create({
    required String username,
    required String email,
    required String fullName,
    required String password,
    required String department,
    String? phoneNumber,
    String? nfcCardId,
    String role = 'User',
  }) async {
    try {
      final response = await _api.post('Employee', {
        'username': username,
        'email': email,
        'fullName': fullName,
        'password': password,
        'department': department,
        'phoneNumber': phoneNumber,
        'nfcCardId': nfcCardId,
        'role': role,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(
    String id, {
    String? email,
    String? fullName,
    String? department,
    String? phoneNumber,
    String? nfcCardId,
    String? role,
  }) async {
    try {
      final response = await _api.put('Employee/$id', {
        'email': email,
        'fullName': fullName,
        'department': department,
        'phoneNumber': phoneNumber,
        'nfcCardId': nfcCardId,
        'role': role,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final response = await _api.delete('Employee/$id');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> seedSample() async {
    try {
      final response = await _api.post('Employee/seed-sample-employees', {});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
