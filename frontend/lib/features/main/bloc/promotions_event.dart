part of 'promotions_bloc.dart';

abstract class PromotionsEvent extends Equatable {
  const PromotionsEvent();

  @override
  List<Object> get props => [];
}

class PromotionLoaded extends PromotionsEvent {
  final int? promotionId;

  const PromotionLoaded(this.promotionId);

  //@override
  //List<Object?> get props => [promotionId];
}

class PromotionsListLoaded extends PromotionsEvent {
  const PromotionsListLoaded();
}

class PromotionRefreshed extends PromotionsEvent {
  final int? promotionId;

  const PromotionRefreshed(this.promotionId);

  //@override
  //List<Object?> get props => [promotionId];
}