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
  final List<UserChoiceEntity>? userChoices;

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
    this.userChoices,
  });

  factory AnalysisEntity.fromJson(Map<String, dynamic> json) {
    List<UserChoiceEntity>? choices;
    if (json['user_choices'] != null && json['user_choices'] is List) {
      choices = (json['user_choices'] as List)
          .whereType<Map<String, dynamic>>()
          .map((choice) => UserChoiceEntity.fromJson(choice))
          .toList();
    }
    
    Map<String, dynamic> ingredients = {};
    if (json['ingredients'] != null && json['ingredients'] is Map) {
      ingredients = Map<String, dynamic>.from(json['ingredients']);
    }
    
    final basicIngredients = ingredients['basic'] is List
        ? List<String>.from(ingredients['basic'])
        : <String>[];
    
    final additionalIngredients = ingredients['additional'] is List
        ? List<String>.from(ingredients['additional'])
        : <String>[];
    
    return AnalysisEntity(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      detectedDish: json['detected_dish'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      basicIngredients: basicIngredients,
      additionalIngredients: additionalIngredients,
      alternatives: json['alternatives_found'] is Map
          ? Map<String, dynamic>.from(json['alternatives_found'])
          : {},
      imageUrl: json['image_url'],
      userChoices: choices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'detected_dish': detectedDish,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
      'ingredients': {
        'basic': basicIngredients,
        'additional': additionalIngredients,
      },
      'alternatives_found': alternatives,
      'image_url': imageUrl,
      'user_choices': userChoices?.map((c) => c.toJson()).toList(),
    };
  }
  
  bool get hasUserChoices => userChoices != null && userChoices!.isNotEmpty;
}

class UserChoiceEntity {
  final int id;
  final DateTime createdAt;
  final List<SelectedProductEntity> selectedProducts;

  UserChoiceEntity({
    required this.id,
    required this.createdAt,
    required this.selectedProducts,
  });

  factory UserChoiceEntity.fromJson(Map<String, dynamic> json) {
    List<SelectedProductEntity> products = [];
    
    if (json['selected_products'] != null && json['selected_products'] is List) {
      products = (json['selected_products'] as List)
          .whereType<Map<String, dynamic>>()
          .map((p) => SelectedProductEntity.fromJson(p))
          .toList();
    }
    
    return UserChoiceEntity(
      id: json['id'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      selectedProducts: products,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'selected_products': selectedProducts.map((p) => p.toJson()).toList(),
    };
  }
}

class SelectedProductEntity {
  final int id;
  final int productId;
  final String originalIngredient;
  final String ingredientType;
  final int quantity;
  final DateTime createdAt;
  final Map<String, dynamic> product;

  SelectedProductEntity({
    required this.id,
    required this.productId,
    required this.originalIngredient,
    required this.ingredientType,
    required this.quantity,
    required this.createdAt,
    required this.product,
  });

  factory SelectedProductEntity.fromJson(Map<String, dynamic> json) {
    return SelectedProductEntity(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      originalIngredient: json['original_ingredient'] ?? '',
      ingredientType: json['ingredient_type'] ?? 'basic',
      quantity: json['quantity'] ?? 1,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      product: json['product'] is Map 
          ? Map<String, dynamic>.from(json['product']) 
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'original_ingredient': originalIngredient,
      'ingredient_type': ingredientType,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'product': product,
    };
  }
  
  bool get isBasic => ingredientType == 'basic';
}