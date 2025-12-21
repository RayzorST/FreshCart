import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/promotion_entity.dart';
import 'package:client/domain/repositories/promotion_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PromotionRepository)
class PromotionRepositoryImpl implements PromotionRepository {
  @override
  Future<Either<String, List<PromotionEntity>>> getPromotions() async {
    try {
      final response = await ApiClient.getPromotions();
      final promotions = response
          .map((promotion) => PromotionEntity.fromJson(promotion as Map<String, dynamic>))
          .toList();
      return Right(promotions);
    } catch (e) {
      return Left('Ошибка загрузки акций: $e');
    }
  }

  @override
  Future<Either<String, PromotionEntity>> getPromotionById(int id) async {
    try {
      final response = await ApiClient.getPromotion(id);
      return Right(PromotionEntity.fromJson(response));
    } catch (e) {
      return Left('Ошибка загрузки акции: $e');
    }
  }

  @override
  Future<Either<String, List<PromotionEntity>>> getActivePromotions() async {
    try {
      final response = await ApiClient.getPromotions();
      final now = DateTime.now();
      final promotions = response
          .map((promotion) => PromotionEntity.fromJson(promotion as Map<String, dynamic>))
          .where((promo) => 
              (promo.startDate == null || promo.startDate!.isBefore(now)) &&
              (promo.endDate == null || promo.endDate!.isAfter(now)))
          .toList();
      return Right(promotions);
    } catch (e) {
      return Left('Ошибка загрузки активных акций: $e');
    }
  }
}