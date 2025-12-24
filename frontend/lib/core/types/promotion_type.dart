// promotion_type.dart
enum PromotionType {
  percentage('percentage', 'Процентная скидка'),
  fixed('fixed', 'Фиксированная скидка'),
  gift('gift', 'Подарок'),
  bundle('bundle', 'Набор'),
  freeShipping('free_shipping', 'Бесплатная доставка');

  final String value;
  final String displayName;

  const PromotionType(this.value, this.displayName);

  static PromotionType fromString(String value) {
    return PromotionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PromotionType.percentage,
    );
  }

  String get description {
    switch (this) {
      case PromotionType.percentage:
        return 'Скидка в процентах от суммы заказа';
      case PromotionType.fixed:
        return 'Фиксированная сумма скидки';
      case PromotionType.gift:
        return 'Бесплатный подарок при выполнении условий';
      case PromotionType.bundle:
        return 'Специальная цена на набор товаров';
      case PromotionType.freeShipping:
        return 'Бесплатная доставка';
    }
  }
}