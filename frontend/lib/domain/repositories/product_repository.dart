import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/product_entity.dart';

abstract class ProductRepository {
  Future<Either<String, List<ProductEntity>>> getProducts({int? categoryId, String? search});
  Future<Either<String, ProductEntity>> getProductById(int id);
  Future<Either<String, List<ProductEntity>>> getProductsByCategory(String category);
  Future<Either<String, List<ProductEntity>>> searchProducts(String query);
}