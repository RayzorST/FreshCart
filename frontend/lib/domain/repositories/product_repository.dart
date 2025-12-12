import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/product_entity.dart';

abstract class ProductRepository {
  Future<Either<String, List<ProductEntity>>> getAllProducts();
  Future<Either<String, ProductEntity>> getProductById(int id);
  Future<Either<String, List<ProductEntity>>> getProductsByCategory(String category);
  Future<Either<String, List<ProductEntity>>> syncProducts(); // ИЗМЕНЕНО С void НА List<ProductEntity>
  Future<Either<String, void>> cacheProducts(List<ProductEntity> products);
}