import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/category_entity.dart';
import 'package:client/domain/repositories/category_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  @override
  Future<Either<String, List<CategoryEntity>>> getCategories() async {
    try {
      final response = await ApiClient.getCategories();
      final categories = response
          .map((category) => CategoryEntity.fromJson(category as Map<String, dynamic>))
          .toList();
      return Right(categories);
    } catch (e) {
      return Left('Ошибка загрузки категорий: $e');
    }
  }

  @override
  Future<Either<String, List<CategoryEntity>>> getPopularCategories({int limit = 5}) async {
    try {
      final response = await ApiClient.getCategories();
      final categories = response
          .map((category) => CategoryEntity.fromJson(category as Map<String, dynamic>))
          .toList()
          .take(limit)
          .toList();
      return Right(categories);
    } catch (e) {
      return Left('Ошибка загрузки популярных категорий: $e');
    }
  }
}