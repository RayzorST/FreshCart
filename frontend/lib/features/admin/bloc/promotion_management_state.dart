// promotion_management_state.dart
part of 'promotion_management_bloc.dart';

abstract class PromotionManagementState {
  const PromotionManagementState();
}

class PromotionManagementInitial extends PromotionManagementState {
  const PromotionManagementInitial();
}

class PromotionManagementLoading extends PromotionManagementState {
  const PromotionManagementLoading();
}

class PromotionManagementLoaded extends PromotionManagementState {
  final List<PromotionEntity> promotions;

  const PromotionManagementLoaded(this.promotions);

  // Вспомогательные методы для фильтрации
  List<PromotionEntity> get activePromotions => promotions.where((p) => p.isValid).toList();
  List<PromotionEntity> get inactivePromotions => promotions.where((p) => !p.isValid).toList();
  
  List<PromotionEntity> get percentagePromotions => 
      promotions.where((p) => p.promotionType == 'percentage').toList();
  
  List<PromotionEntity> get fixedPromotions => 
      promotions.where((p) => p.promotionType == 'fixed').toList();
  
  List<PromotionEntity> get giftPromotions => 
      promotions.where((p) => p.promotionType == 'gift').toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PromotionManagementLoaded &&
      _listsEqual(other.promotions, promotions);
  }

  bool _listsEqual(List<PromotionEntity> list1, List<PromotionEntity> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  @override
  int get hashCode => promotions.length;
}

class PromotionManagementError extends PromotionManagementState {
  final String message;

  const PromotionManagementError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PromotionManagementError &&
      other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class PromotionManagementOperationSuccess extends PromotionManagementState {
  final String message;

  const PromotionManagementOperationSuccess(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PromotionManagementOperationSuccess &&
      other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}