part of 'promotions_bloc.dart';

enum PromotionsStatus {
  initial,
  loading,
  loaded,
  error,
}

class PromotionsState extends Equatable {
  final PromotionsStatus status;
  final Map<String, dynamic>? currentPromotion;
  final List<dynamic> promotionsList;
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
    Map<String, dynamic>? currentPromotion,
    List<dynamic>? promotionsList,
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