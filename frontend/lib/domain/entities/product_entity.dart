import 'package:client/api/client.dart';

class ProductEntity {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final String? category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get imageUrl => '${ApiClient.baseUrl}/images/products/$id/image';

  factory ProductEntity.fromJson(Map<String, dynamic> json) {
    return ProductEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      category: json['category'] != null 
          ? json['category'] is String 
              ? json['category'] as String
              : (json['category'] as Map)['name'] as String?
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock_quantity': stockQuantity,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}