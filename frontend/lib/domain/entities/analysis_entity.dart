class AnalysisEntity {
  final int id;
  final int userId;
  final String detectedDish;
  final double confidence;
  final DateTime createdAt;
  final List<String> basicIngredients;
  final List<String> additionalIngredients;
  final Map<String, dynamic> alternatives;
  final String? imageUrl;

  AnalysisEntity({
    required this.id,
    required this.userId,
    required this.detectedDish,
    required this.confidence,
    required this.createdAt,
    required this.basicIngredients,
    required this.additionalIngredients,
    required this.alternatives,
    this.imageUrl,
  });

  factory AnalysisEntity.fromJson(Map<String, dynamic> json) {
    return AnalysisEntity(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      detectedDish: json['detected_dish'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      basicIngredients: List<String>.from(json['basic_ingredients'] ?? []),
      additionalIngredients: List<String>.from(json['additional_ingredients'] ?? []),
      alternatives: json['alternatives_found'] ?? {},
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'detected_dish': detectedDish,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
      'basic_ingredients': basicIngredients,
      'additional_ingredients': additionalIngredients,
      'alternatives_found': alternatives,
      'image_url': imageUrl,
    };
  }
}