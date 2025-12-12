import 'product_entity.dart';

class CartItemEntity {
  final int? id;
  final ProductEntity product;
  final int quantity;
  final double? appliedPrice;
  final bool isSynced;
  final DateTime addedAt;

  CartItemEntity({
    this.id,
    required this.product,
    this.quantity = 1,
    this.appliedPrice,
    this.isSynced = false,
    required this.addedAt,
  });

  double get totalPrice => (appliedPrice ?? product.price) * quantity;
  
  double get discountAmount {
    if (appliedPrice == null || appliedPrice! >= product.price) return 0.0;
    return (product.price - appliedPrice!) * quantity;
  }
  
  bool get hasDiscount => appliedPrice != null && appliedPrice! < product.price;

  CartItemEntity copyWith({
    int? id,
    ProductEntity? product,
    int? quantity,
    double? appliedPrice,
    bool? isSynced,
    DateTime? addedAt,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      appliedPrice: appliedPrice ?? this.appliedPrice,
      isSynced: isSynced ?? this.isSynced,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': product.id,
      'quantity': quantity,
      if (appliedPrice != null) 'applied_price': appliedPrice,
      'is_synced': isSynced,
      'added_at': addedAt.toIso8601String(),
    };
  }
}