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
  final List<dynamic> promotions;

  const PromotionManagementLoaded(this.promotions);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PromotionManagementLoaded &&
      listEquals(other.promotions, promotions);
  }

  @override
  int get hashCode => promotions.hashCode;
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