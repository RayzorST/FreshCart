import 'product_entity.dart';

class CartItemEntity {
  final int id;
  final ProductEntity product;
  final int quantity;
  final double? discountPrice;
  final List<Map<String, dynamic>>? appliedPromotions;
  final DateTime addedAt;

  CartItemEntity({
    required this.id,
    required this.product,
    required this.quantity,
    this.discountPrice,
    this.appliedPromotions,
    required this.addedAt,
  });

  double get totalPrice => (discountPrice ?? product.price) * quantity;
  
  double get discountAmount {
    if (discountPrice == null || discountPrice! >= product.price) return 0.0;
    return (product.price - discountPrice!) * quantity;
  }
  
  bool get hasDiscount => discountPrice != null && discountPrice! < product.price;

  factory CartItemEntity.fromJson(Map<String, dynamic> json) {
    final appliedPromotionsRaw = json['applied_promotions'] as List<dynamic>?;
    final List<Map<String, dynamic>>? appliedPromotions;
    
    if (appliedPromotionsRaw != null && appliedPromotionsRaw.isNotEmpty) {
      // Если есть промоции, пытаемся преобразовать
      appliedPromotions = appliedPromotionsRaw
          .whereType<Map<String, dynamic>>()
          .toList();
    } else {
      appliedPromotions = null;
    }
    
    return CartItemEntity(
      id: json['id'] as int,
      product: ProductEntity.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      discountPrice: json['discount_price'] as double?,
      appliedPromotions: appliedPromotions,
      addedAt: DateTime.parse(json['created_at'] as String),
    );
  }
}