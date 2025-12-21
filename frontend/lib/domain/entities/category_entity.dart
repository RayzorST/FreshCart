class CategoryEntity {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int? parentId;
  final int? productCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CategoryEntity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.parentId,
    this.productCount,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryEntity.fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      parentId: json['parent_id'] as int?,
      productCount: json['product_count'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'parent_id': parentId,
      'product_count': productCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}