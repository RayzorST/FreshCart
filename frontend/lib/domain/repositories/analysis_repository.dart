import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:client/domain/entities/analysis_entity.dart';
import 'package:client/domain/entities/analysis_result_entity.dart';

abstract class AnalysisRepository {
  Future<Either<String, AnalysisResultEntity>> analyzeFoodImage(String imageData);
  Future<Either<String, List<AnalysisEntity>>> getMyAnalysisHistory({
    int skip = 0,
    int limit = 20,
    double? minConfidence,
  });
  Future<Either<String, List<AnalysisEntity>>> getAllAnalysisHistory({
    int skip = 0,
    int limit = 20,
    int? userId,
    double? minConfidence,
  });
  Future<Either<String, void>> deleteAnalysisRecord(int analysisId);
  Future<Either<String, Map<String, dynamic>>> getAnalysisStats();
  Future<Either<String, AnalysisResultEntity>> analyzeFoodImageFile(XFile imageFile);
}