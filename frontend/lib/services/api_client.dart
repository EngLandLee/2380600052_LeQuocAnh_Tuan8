import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../utils/auth_helper.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ConfigUrl.baseUrl;

  Future<Map<String, String>> _buildHeaders([Map<String, String>? extra]) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await AuthHelper.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _buildHeaders();
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  Future<http.Response> post(String endpoint, dynamic body) async {
    final headers = await _buildHeaders();
    return http.post(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String endpoint, dynamic body) async {
    final headers = await _buildHeaders();
    return http.put(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _buildHeaders();
    return http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }
}
