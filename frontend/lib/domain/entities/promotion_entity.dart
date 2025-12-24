import 'package:client/core/types/promotion_type.dart';

class PromotionEntity {
  final int id;
  final String title; // name в JSON
  final String? description;
  final String? imageUrl;
  final double? discountPercent; // value для percentage
  final double? fixedDiscount; // value для fixed
  final double? minimumAmount; // min_order_amount
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PromotionType promotionType; // promotion_type
  final int? value; // значение акции
  final int? giftProductId; // gift_product_id
  final int? minQuantity; // min_quantity
  final int? priority; // priority
  final List<int>? categoryIds; // IDs категорий
  final List<int>? productIds; // IDs товаров

  PromotionEntity({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.discountPercent,
    this.fixedDiscount,
    this.minimumAmount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    required this.promotionType,
    this.value,
    this.giftProductId,
    this.minQuantity,
    this.priority,
    this.categoryIds,
    this.productIds,
  });

  factory PromotionEntity.fromJson(Map<String, dynamic> json) {
    // Обязательные поля
    final id = json['id'] as int? ?? 0;
    final title = json['name'] as String? ?? 'Акция';
    final promotionType = PromotionType.fromString(json['promotion_type'] as String? ?? 'percentage');
    
    // Опциональные строки
    final description = json['description'] as String?;
    final imageUrl = json['image_url'] as String?;
    
    // Обработка value в зависимости от типа акции
    double? discountPercent;
    double? fixedDiscount;
    final dynamic value = json['value'];
    
    if (value != null) {
      if (promotionType == PromotionType.percentage && value is int) {
        discountPercent = value.toDouble();
      } else if (promotionType == PromotionType.fixed && value is int) {
        fixedDiscount = value.toDouble();
      } else if (value is double) {
        if (promotionType == PromotionType.percentage) {
          discountPercent = value;
        } else if (promotionType == PromotionType.fixed) {
          fixedDiscount = value;
        }
      } else if (value is String) {
        final doubleValue = double.tryParse(value);
        if (doubleValue != null) {
          if (promotionType == PromotionType.percentage) {
            discountPercent = doubleValue;
          } else if (promotionType == PromotionType.fixed) {
            fixedDiscount = doubleValue;
          }
        }
      }
    }
    
    // Числовые поля
    final minimumAmount = _parseDouble(json['min_order_amount']);
    final giftProductId = json['gift_product_id'] as int?;
    final minQuantity = json['min_quantity'] as int?;
    final priority = json['priority'] as int?;
    
    // Даты
    final startDate = _parseDateTime(json['start_date']) ?? DateTime.now();
    final endDate = _parseDateTime(json['end_date']) ?? DateTime.now().add(const Duration(days: 30));
    
    // Списки ID
    final categoryIds = _parseIdList(json['category_ids']);
    final productIds = _parseIdList(json['product_ids']);
    
    // Булево значение
    final isActive = json['is_active'] as bool? ?? true;
    
    // Даты создания/обновления
    final createdAt = _parseDateTime(json['created_at']);
    final updatedAt = _parseDateTime(json['updated_at']);
    
    return PromotionEntity(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      discountPercent: discountPercent,
      fixedDiscount: fixedDiscount,
      minimumAmount: minimumAmount,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      promotionType: promotionType,
      value: value is int ? value : (value is double ? value.toInt() : null),
      giftProductId: giftProductId,
      minQuantity: minQuantity,
      priority: priority,
      categoryIds: categoryIds,
      productIds: productIds,
    );
  }

  // Вспомогательные методы для безопасного парсинга
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static List<int>? _parseIdList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.whereType<int>().toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'description': description,
      'image_url': imageUrl,
      'promotion_type': promotionType.value,
      'value': promotionType == PromotionType.percentage 
          ? discountPercent?.toInt() 
          : promotionType == PromotionType.fixed 
              ? fixedDiscount?.toInt() 
              : value,
      'discount_percent': discountPercent,
      'fixed_discount': fixedDiscount,
      'minimum_amount': minimumAmount,
      'gift_product_id': giftProductId,
      'min_quantity': minQuantity,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'priority': priority,
      'category_ids': categoryIds,
      'product_ids': productIds,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isValid {
    final now = DateTime.now();
    return isActive && startDate.isBefore(now) && endDate.isAfter(now);
  }

  String get discountText {
    switch (promotionType) {
      case PromotionType.percentage:
        return '${discountPercent?.toStringAsFixed(0)}%';
      case PromotionType.fixed:
        return '${fixedDiscount?.toStringAsFixed(0)} ₽';
      case PromotionType.gift:
        return 'Подарок';
      case PromotionType.bundle:
        return 'Набор';
      case PromotionType.freeShipping:
        return 'Бесплатная доставка';
    }
  }
}