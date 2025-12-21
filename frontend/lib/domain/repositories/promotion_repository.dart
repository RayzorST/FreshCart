import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/promotion_entity.dart';

abstract class PromotionRepository {
  Future<Either<String, List<PromotionEntity>>> getPromotions();
  Future<Either<String, PromotionEntity>> getPromotionById(int id);
  Future<Either<String, List<PromotionEntity>>> getActivePromotions();
}