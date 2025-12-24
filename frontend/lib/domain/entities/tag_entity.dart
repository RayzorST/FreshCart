// tag_entity.dart
class TagEntity {
  final int id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? productCount;

  TagEntity({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.productCount,
  });

  factory TagEntity.fromJson(Map<String, dynamic> json) {
    return TagEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      productCount: json['product_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'product_count': productCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}