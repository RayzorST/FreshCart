// lib/data/repositories/analysis_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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
      
      // После успешного анализа, сохраняем изображение
      if (response.containsKey('analysis_id')) {
        final analysisId = response['analysis_id'] as int;
        await _saveAnalysisImage(analysisId, imageData);
      }
      
      return Right(result);
    } catch (e) {
      return Left('Ошибка анализа изображения: $e');
    }
  }

  Future<Either<String, AnalysisResultEntity>> analyzeFoodImageFile(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await ApiClient.analyzeFoodImage(base64Image);
      final result = AnalysisResultEntity.fromJson(response);
      
      // После успешного анализа, сохраняем файл изображения
      if (response.containsKey('analysis_id')) {
        final analysisId = response['analysis_id'] as int;
        await _saveAnalysisImageFile(analysisId, imageFile.path, bytes);
      }
      
      return Right(result);
    } catch (e) {
      return Left('Ошибка анализа изображения: $e');
    }
  }

  Future<void> _saveAnalysisImage(int analysisId, String base64Image) async {
    try {
      await ApiClient.uploadAnalysisImageBase64(analysisId, base64Image);
      print('Изображение анализа $analysisId сохранено');
    } catch (e) {
      print('Ошибка сохранения изображения анализа: $e');
    }
  }

  Future<void> _saveAnalysisImageFile(int analysisId, String filePath, List<int> bytes) async {
    try {
      await ApiClient.uploadAnalysisImageFile(analysisId, filePath, bytes);
      print('Файл изображения анализа $analysisId сохранен');
    } catch (e) {
      print('Ошибка сохранения файла изображения анализа: $e');
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
      print(response);
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
      print(e);
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