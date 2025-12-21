part of 'promotions_bloc.dart';

enum PromotionsStatus {
  initial,
  loading,
  loaded,
  error,
}

class PromotionsState extends Equatable {
  final PromotionsStatus status;
  final PromotionEntity? currentPromotion;
  final List<PromotionEntity> promotionsList;
  final String? error;

  const PromotionsState({
    required this.status,
    this.currentPromotion,
    required this.promotionsList,
    this.error,
  });

  const PromotionsState.initial()
      : status = PromotionsStatus.initial,
        currentPromotion = null,
        promotionsList = const [],
        error = null;

  PromotionsState copyWith({
    PromotionsStatus? status,
    PromotionEntity? currentPromotion,
    List<PromotionEntity>? promotionsList,
    String? error,
  }) {
    return PromotionsState(
      status: status ?? this.status,
      currentPromotion: currentPromotion ?? this.currentPromotion,
      promotionsList: promotionsList ?? this.promotionsList,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentPromotion,
        promotionsList,
        error,
      ];
}