import 'category.dart';

class Product {
  final int id;
  final String name;
  final double price;
  final String? description;
  final int? categoryId;
  final Category? category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.categoryId,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int?,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }
}
