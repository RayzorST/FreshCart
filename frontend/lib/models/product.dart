class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final int? categoryId;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    this.imageUrl,
    this.categoryId,
    required this.isActive,
  });

  String get fullImageUrl {
    if (imageUrl == null) return '';
    return 'http://localhost:8000$imageUrl';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stock_quantity'],
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
      isActive: json['is_active'],
    );
  }
}