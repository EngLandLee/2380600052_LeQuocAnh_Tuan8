import 'dart:convert';
import '../models/category.dart';
import 'api_client.dart';

class CategoryService {
  final ApiClient _api = ApiClient();

  Future<List<Category>> getAll() async {
    try {
      final response = await _api.get('Category');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List;
        return list.map((e) => Category.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> create(String name, String? description) async {
    try {
      final response = await _api.post('Category', {
        'name': name,
        'description': description,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(int id, String name, String? description) async {
    try {
      final response = await _api.put('Category/$id', {
        'name': name,
        'description': description,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      final response = await _api.delete('Category/$id');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
