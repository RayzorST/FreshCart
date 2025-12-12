import 'product_entity.dart';

class FavoriteItemEntity {
  final int? id;
  final ProductEntity product;
  final DateTime addedAt;

  FavoriteItemEntity({
    this.id,
    required this.product,
    required this.addedAt,
  });

  FavoriteItemEntity copyWith({
    int? id,
    ProductEntity? product,
    DateTime? addedAt,
  }) {
    return FavoriteItemEntity(
      id: id ?? this.id,
      product: product ?? this.product,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': product.id,
      'added_at': addedAt.toIso8601String(),
    };
  }
}