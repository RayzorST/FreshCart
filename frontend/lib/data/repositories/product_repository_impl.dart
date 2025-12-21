import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/repositories/product_repository.dart';

@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<Either<String, List<ProductEntity>>> getProducts({int? categoryId, String? search}) async {
    try {
      final response = await ApiClient.getProducts(categoryId: categoryId, search: search);
      final products = response
          .map((json) => ProductEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(products);
    } catch (e) {
      return Left('Ошибка загрузки продуктов: $e');
    }
  }

  @override
  Future<Either<String, ProductEntity>> getProductById(int id) async {
    try {
      final response = await ApiClient.getProduct(id);
      final product = ProductEntity.fromJson(response as Map<String, dynamic>);
      return Right(product);
    } catch (e) {
      return Left('Ошибка загрузки продукта: $e');
    }
  }

  @override
  Future<Either<String, List<ProductEntity>>> getProductsByCategory(String category) async {
    try {
      // Сначала получаем все продукты, потом фильтруем
      final response = await ApiClient.getProducts();
      final allProducts = response
          .map((json) => ProductEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final filtered = allProducts
          .where((product) => product.category == category)
          .toList();
      
      return Right(filtered);
    } catch (e) {
      return Left('Ошибка фильтрации продуктов: $e');
    }
  }

  @override
  Future<Either<String, List<ProductEntity>>> searchProducts(String query) async {
    try {
      final response = await ApiClient.searchProducts(name: query);
      final products = response
          .map((json) => ProductEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(products);
    } catch (e) {
      return Left('Ошибка поиска продуктов: $e');
    }
  }
}