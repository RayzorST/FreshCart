import 'product_entity.dart';

class FavoriteItemEntity {
  final int id;
  final ProductEntity product;
  final DateTime addedAt;

  FavoriteItemEntity({
    required this.id,
    required this.product,
    required this.addedAt,
  });

  factory FavoriteItemEntity.fromJson(Map<String, dynamic> json) {
    return FavoriteItemEntity(
      id: json['id'] as int,
      product: ProductEntity.fromJson(json['product'] as Map<String, dynamic>),
      addedAt: DateTime.parse(json['created_at'] as String),
    );
  }
}