class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final Map<String, dynamic>? category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    this.imageUrl,
    this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullImageUrl {
    if (imageUrl == null) return '';

    if (imageUrl!.startsWith('http')) {
      return imageUrl!;
    } else if (imageUrl!.startsWith('/')) {
      return 'https://freshcart.cloudpub.ru/$imageUrl';
    } else {
      return 'https://freshcart.cloudpub.ru/$imageUrl';
    }
  }

  int? get categoryId => category?['id'];

  String? get categoryName => category?['name'];

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      category: json['category'] != null 
          ? Map<String, dynamic>.from(json['category'] as Map)
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
      'image_url': imageUrl,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    String? imageUrl,
    Map<String, dynamic>? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, category: ${category?['name']})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}