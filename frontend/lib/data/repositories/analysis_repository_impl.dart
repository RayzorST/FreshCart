// lib/data/repositories/analysis_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/repositories/analysis_repository.dart';
import 'package:client/domain/entities/analysis_entity.dart';
import 'package:client/domain/entities/analysis_result_entity.dart';

@LazySingleton(as: AnalysisRepository)
class AnalysisRepositoryImpl implements AnalysisRepository {
  @override
  Future<Either<String, AnalysisResultEntity>> analyzeFoodImage(String imageData) async {
    try {
      final response = await ApiClient.analyzeFoodImage(imageData);
      final result = AnalysisResultEntity.fromJson(response);
      return Right(result);
    } catch (e) {
      return Left('Ошибка анализа изображения: $e');
    }
  }

  @override
  Future<Either<String, List<AnalysisEntity>>> getMyAnalysisHistory({
    int skip = 0,
    int limit = 20,
    double? minConfidence,
  }) async {
    try {
      final response = await ApiClient.getMyAnalysisHistory(
        skip: skip,
        limit: limit,
        minConfidence: minConfidence,
      );
      final history = (response)
          .map((json) => AnalysisEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(history);
    } catch (e) {
      return Left('Ошибка загрузки истории анализов: $e');
    }
  }

  @override
  Future<Either<String, List<AnalysisEntity>>> getAllAnalysisHistory({
    int skip = 0,
    int limit = 20,
    int? userId,
    double? minConfidence,
  }) async {
    try {
      final response = await ApiClient.getAllAnalysisHistory(
        skip: skip,
        limit: limit,
        userId: userId,
        minConfidence: minConfidence,
      );
      final history = (response)
          .map((json) => AnalysisEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(history);
    } catch (e) {
      return Left('Ошибка загрузки всей истории анализов: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteAnalysisRecord(int analysisId) async {
    try {
      // TODO: Нужно добавить метод deleteAnalysisRecord в ApiClient
      // await ApiClient.deleteAnalysisRecord(analysisId);
      // Пока просто возвращаем успех
      return const Right(null);
    } catch (e) {
      return Left('Ошибка удаления записи анализа: $e');
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> getAnalysisStats() async {
    try {
      final response = await ApiClient.getAnalysisStats();
      return Right(response);
    } catch (e) {
      return Left('Ошибка загрузки статистики анализов: $e');
    }
  }
}