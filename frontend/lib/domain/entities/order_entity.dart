import 'package:client/domain/entities/product_entity.dart';

class OrderEntity {
  final int id;
  final String shippingAddress;
  final String? notes;
  final int userId;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemEntity> items;

  OrderEntity({
    required this.id,
    required this.shippingAddress,
    this.notes,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
        ?.map((item) => OrderItemEntity.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];

    return OrderEntity(
      id: json['id'] as int,
      shippingAddress: json['shipping_address'] as String? ?? '',
      notes: json['notes'] as String?,
      userId: json['user_id'] as int,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipping_address': shippingAddress,
      'notes': notes,
      'user_id': userId,
      'status': status,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderItemEntity {
  final int id;
  final int productId;
  final int quantity;
  final double price;
  final ProductEntity product;

  OrderItemEntity({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.product,
  });

  factory OrderItemEntity.fromJson(Map<String, dynamic> json) {
    return OrderItemEntity(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      product: ProductEntity.fromJson(json['product'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'product': product.toJson(),
    };
  }

  double get totalPrice => price * quantity;
}