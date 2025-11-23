part of 'promotion_management_bloc.dart';

abstract class PromotionManagementEvent {
  const PromotionManagementEvent();
}

class LoadPromotions extends PromotionManagementEvent {
  const LoadPromotions();
}

class CreatePromotion extends PromotionManagementEvent {
  final Map<String, dynamic> promotionData;

  const CreatePromotion(this.promotionData);
}

class DeletePromotion extends PromotionManagementEvent {
  final int promotionId;

  const DeletePromotion(this.promotionId);
}