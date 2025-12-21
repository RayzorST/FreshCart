import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/category_entity.dart';

abstract class CategoryRepository {
  Future<Either<String, List<CategoryEntity>>> getCategories();
  Future<Either<String, List<CategoryEntity>>> getPopularCategories({int limit = 5});
}