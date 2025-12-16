import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:client/api/client.dart';
import 'package:client/data/datasources/local/app_database.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/repositories/product_repository.dart';

@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  final AppDatabase _database;

  ProductRepositoryImpl(this._database);

  @override
  Future<Either<String, List<ProductEntity>>> getAllProducts() async {
    try {
      final dbProducts = await _database.getAllProducts();
      if (dbProducts.isNotEmpty) {
        final products = dbProducts.map(_fromDbModel).toList();
        return Right(products);
      }

      return await syncProducts();
    } catch (e) {
      return Left('Ошибка загрузки продуктов: $e');
    }
  }

  @override
  Future<Either<String, ProductEntity>> getProductById(int id) async {
    try {
      final dbProduct = await _database.getProductById(id);
      if (dbProduct != null) {
        return Right(_fromDbModel(dbProduct));
      }

      final response = await ApiClient.getProducts();
      final product = ProductEntity.fromJson(response[0]);

      await _database.insertProduct(_toDbCompanion(product));
      
      return Right(product);
    } catch (e) {
      return Left('Ошибка загрузки продукта: $e');
    }
  }

  @override
  Future<Either<String, List<ProductEntity>>> getProductsByCategory(String category) async {
    try {
      final allProducts = await getAllProducts();
      return allProducts.fold(
        (error) => Left(error),
        (products) {
          final filtered = products.where((p) => p.category == category).toList();
          return Right(filtered);
        },
      );
    } catch (e) {
      return Left('Ошибка фильтрации продуктов: $e');
    }
  }

  @override
  Future<Either<String, List<ProductEntity>>> syncProducts() async {
    try {
      final response = await ApiClient.getProducts();
      final products = response.map((json) => ProductEntity.fromJson(json)).toList();
      
      final companions = products.map(_toDbCompanion).toList();
      await _database.insertProducts(companions);
      
      return Right(products);
    } catch (e) {
      return Left('Ошибка синхронизации продуктов: $e');
    }
  }

  @override
  Future<Either<String, void>> cacheProducts(List<ProductEntity> products) async {
    try {
      final companions = products.map(_toDbCompanion).toList();
      await _database.insertProducts(companions);
      return const Right(null);
    } catch (e) {
      return Left('Ошибка кэширования продуктов: $e');
    }
  }

  ProductEntity _fromDbModel(Product dbProduct) {
    return ProductEntity(
      id: dbProduct.id,
      name: dbProduct.name,
      description: dbProduct.description,
      price: dbProduct.price,
      stockQuantity: dbProduct.stockQuantity,
      category: dbProduct.category,
      isActive: dbProduct.isActive,
      createdAt: dbProduct.createdAt,
      updatedAt: dbProduct.updatedAt,
    );
  }

  ProductsCompanion _toDbCompanion(ProductEntity product) {
    return ProductsCompanion(
      id: Value(product.id),
      name: Value(product.name),
      description: Value(product.description),
      price: Value(product.price),
      stockQuantity: Value(product.stockQuantity),
      category: Value(product.category),
      isActive: Value(product.isActive),
      createdAt: Value(product.createdAt),
      updatedAt: Value(product.updatedAt),
    );
  }
}