// promotion_management_repository.dart
import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/promotion_entity.dart';

abstract class PromotionManagementRepository {
  Future<Either<String, List<PromotionEntity>>> getPromotions();
  Future<Either<String, PromotionEntity>> createPromotion(Map<String, dynamic> promotionData);
  Future<Either<String, void>> deletePromotion(int promotionId);
  Future<Either<String, PromotionEntity>> updatePromotion(int promotionId, Map<String, dynamic> promotionData);
}