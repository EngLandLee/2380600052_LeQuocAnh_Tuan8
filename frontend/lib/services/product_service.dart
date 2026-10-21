import 'dart:convert';
import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient _api = ApiClient();

  Future<List<Product>> getAll() async {
    try {
      final response = await _api.get('Product');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List;
        return list.map((e) => Product.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> create(String name, double price, String? description, int? categoryId) async {
    try {
      final response = await _api.post('Product', {
        'name': name,
        'price': price,
        'description': description,
        'categoryId': categoryId,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(int id, String name, double price, String? description, int? categoryId) async {
    try {
      final response = await _api.put('Product/$id', {
        'name': name,
        'price': price,
        'description': description,
        'categoryId': categoryId,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      final response = await _api.delete('Product/$id');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> seedSampleData() async {
    try {
      final response = await _api.post('Product/seed-sample-data', {});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
