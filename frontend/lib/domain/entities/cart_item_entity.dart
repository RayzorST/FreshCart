import 'dart:convert';

class CartItemEntity {
  final int? id;
  final int productId;
  final String productName;
  final String productCategory;
  final double price;
  final double? originalPrice;
  final int quantity;
  final String? imageUrl;
  final List<Map<String, dynamic>> promotions;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartItemEntity({
    this.id,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.price,
    this.originalPrice,
    required this.quantity,
    this.imageUrl,
    List<Map<String, dynamic>>? promotions,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  }) : promotions = promotions ?? [];

  double get totalPrice => price * quantity;
  
  double get totalOriginalPrice => (originalPrice ?? price) * quantity;
  
  double get discountAmount => totalOriginalPrice - totalPrice;
  
  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  
  bool get hasPromotions => promotions.isNotEmpty;

  CartItemEntity copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productCategory,
    double? price,
    double? originalPrice,
    int? quantity,
    String? imageUrl,
    List<Map<String, dynamic>>? promotions,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCategory: productCategory ?? this.productCategory,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      promotions: promotions ?? this.promotions,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_category': productCategory,
      'price': price,
      if (originalPrice != null) 'original_price': originalPrice,
      'quantity': quantity,
      if (imageUrl != null) 'image_url': imageUrl,
      'promotions': jsonEncode(promotions),
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CartItemEntity.fromJson(Map<String, dynamic> json) {
    return CartItemEntity(
      id: json['id'],
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      productCategory: json['product_category'] as String,
      price: (json['price'] as num).toDouble(),
      originalPrice: json['original_price'] != null 
          ? (json['original_price'] as num).toDouble()
          : null,
      quantity: json['quantity'] as int,
      imageUrl: json['image_url'] as String?,
      promotions: json['promotions'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(json['promotions'] as String))
          : [],
      isSynced: json['is_synced'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}