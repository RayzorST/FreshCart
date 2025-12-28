class AnalysisResultEntity {
  final bool success;
  final int userId;
  final String detectedDish;
  final double confidence;
  final String message;
  final List<String> basicIngredients;
  final List<String> additionalIngredients;
  final List<Map<String, dynamic>> basicAlternatives;
  final List<Map<String, dynamic>> additionalAlternatives;
  final List<String> recommendations;

  AnalysisResultEntity({
    required this.success,
    required this.userId,
    required this.detectedDish,
    required this.confidence,
    required this.message,
    required this.basicIngredients,
    required this.additionalIngredients,
    required this.basicAlternatives,
    required this.additionalAlternatives,
    required this.recommendations,
  });

  factory AnalysisResultEntity.fromJson(Map<String, dynamic> json) {
    return AnalysisResultEntity(
      success: json['success'] ?? false,
      userId: json['user_id'] ?? 0,
      detectedDish: json['detected_dish'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      message: json['message'] ?? '',
      basicIngredients: List<String>.from(json['basic_ingredients'] ?? []),
      additionalIngredients: List<String>.from(json['additional_ingredients'] ?? []),
      basicAlternatives: List<Map<String, dynamic>>.from(json['basic_alternatives'] ?? []),
      additionalAlternatives: List<Map<String, dynamic>>.from(json['additional_alternatives'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user_id': userId,
      'detected_dish': detectedDish,
      'confidence': confidence,
      'message': message,
      'basic_ingredients': basicIngredients,
      'additional_ingredients': additionalIngredients,
      'basic_alternatives': basicAlternatives,
      'additional_alternatives': additionalAlternatives,
      'recommendations': recommendations,
    };
  }

  bool get hasAvailableProducts {
    for (final alt in [...basicAlternatives, ...additionalAlternatives]) {
      final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
      for (final product in products) {
        final stockQuantity = (product['stock_quantity'] ?? 1).toInt();
        if (stockQuantity > 0) {
          return true;
        }
      }
    }
    return false;
  }
}

class SelectedProduct {
  final int productId;
  final String ingredient;
  final bool isBasic;
  final Map<String, dynamic> productData;

  SelectedProduct({
    required this.productId,
    required this.ingredient,
    required this.isBasic,
    required this.productData,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedProduct && 
           other.productId == productId && 
           other.ingredient == ingredient &&
           other.isBasic == isBasic;
  }

  @override
  int get hashCode => productId.hashCode ^ ingredient.hashCode ^ isBasic.hashCode;
}