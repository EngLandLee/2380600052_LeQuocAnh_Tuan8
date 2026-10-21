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
}
