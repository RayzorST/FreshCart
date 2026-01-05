import 'package:client/api/client.dart';
import 'package:client/domain/entities/category_entity.dart';
import 'package:client/domain/entities/tag_entity.dart';

class ProductEntity {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int? stockQuantity;
  final int? categoryId;
  final CategoryEntity? category;
  final List<TagEntity> tags; 
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.stockQuantity,
    this.categoryId,
    this.category,
    required this.tags,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get imageUrl => '${ApiClient.baseUrl}/images/products/$id/image';

  factory ProductEntity.fromJson(Map<String, dynamic> json) {
    try {
      CategoryEntity? category;
      if (json['category'] != null && json['category'] is Map<String, dynamic>) {
        category = CategoryEntity.fromJson(json['category'] as Map<String, dynamic>);
      }
      
      List<TagEntity> tags = [];
      if (json['tags'] != null && json['tags'] is List) {
        final tagsList = json['tags'] as List;
        for (var tag in tagsList) {
          if (tag is Map<String, dynamic>) {
            tags.add(TagEntity.fromJson(tag));
          }
        }
      }
      
      return ProductEntity(
        id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
        name: json['name'].toString(),
        description: json['description']?.toString(),
        price: (json['price'] is num ? json['price'] as num : 
                double.tryParse(json['price'].toString()) ?? 0.0).toDouble(),
        stockQuantity: json['stock_quantity'] is int ? 
            json['stock_quantity'] as int : 
            int.tryParse(json['stock_quantity'].toString()),
        categoryId: json['category_id'] is int ? 
            json['category_id'] as int : 
            int.tryParse(json['category_id'].toString()),
        category: category,
        tags: tags,
        isActive: json['is_active'] is bool ? 
            json['is_active'] as bool : 
            (json['is_active']?.toString().toLowerCase() == 'true'),
        createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
        updatedAt: json['updated_at'] != null ? 
            DateTime.tryParse(json['updated_at'].toString()) : 
            null,
      );
    } catch (e) {

      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock_quantity': stockQuantity,
      'category_id': categoryId,
      'category': category?.toJson(),
      'tags': tags.map((tag) => tag.toJson()).toList(),
      'is_active': isActive,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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