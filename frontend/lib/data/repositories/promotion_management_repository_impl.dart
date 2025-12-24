// promotion_management_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/promotion_entity.dart';
import 'package:client/domain/repositories/promotion_management_repository.dart';

class PromotionManagementRepositoryImpl implements PromotionManagementRepository {
  @override
  Future<Either<String, List<PromotionEntity>>> getPromotions() async {
    try {
      final response = await ApiClient.getAdminPromotions();
      
      final promotions = (response as List)
          .map((json) => PromotionEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return Right(promotions);
    } catch (e) {
      return Left('Ошибка загрузки акций: $e');
    }
  }

  @override
  Future<Either<String, PromotionEntity>> createPromotion(Map<String, dynamic> promotionData) async {
    try {
      final response = await ApiClient.createAdminPromotion(promotionData);
      final promotion = PromotionEntity.fromJson(response as Map<String, dynamic>);
      return Right(promotion);
    } catch (e) {
      return Left('Ошибка создания акции: $e');
    }
  }

  @override
  Future<Either<String, void>> deletePromotion(int promotionId) async {
    try {
      await ApiClient.deleteAdminPromotion(promotionId);
      return const Right(null);
    } catch (e) {
      return Left('Ошибка удаления акции: $e');
    }
  }

  @override
  Future<Either<String, PromotionEntity>> updatePromotion(
    int promotionId, 
    Map<String, dynamic> promotionData
  ) async {
    try {
      final response = await ApiClient.updateAdminPromotion(promotionId, promotionData);
      final promotion = PromotionEntity.fromJson(response as Map<String, dynamic>);
      return Right(promotion);
    } catch (e) {
      return Left('Ошибка обновления акции: $e');
    }
  }
}