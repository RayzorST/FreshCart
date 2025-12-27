import 'dart:io';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/entities/category_entity.dart';
import 'package:client/domain/entities/tag_entity.dart';
import 'package:client/domain/repositories/product_management_repository.dart';

class ProductManagementRepositoryImpl implements ProductManagementRepository {
  @override
  Future<Either<String, Map<String, dynamic>>> loadProductData() async {
    try {
      final [productsResponse, categoriesResponse, tagsResponse] = await Future.wait([
        ApiClient.getAdminProducts(includeInactive: true),
        ApiClient.getAdminCategories(),
        ApiClient.getAdminTags(),
      ]);
      final products = (productsResponse)
          .map((json) => ProductEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final categories = (categoriesResponse)
          .map((json) => CategoryEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final tags = (tagsResponse)
          .map((json) => TagEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return Right({
        'products': products,
        'categories': categories,
        'tags': tags,
      });
    } catch (e) {
      return Left('Ошибка загрузки данных: $e');
    }
  }

  @override
  Future<Either<String, ProductEntity>> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await ApiClient.createAdminProduct(productData);
      final product = ProductEntity.fromJson(response);
      return Right(product);
    } catch (e) {
      return Left('Ошибка создания товара: $e');
    }
  }

  @override
  Future<Either<String, ProductEntity>> updateProduct(int productId, Map<String, dynamic> productData) async {
    try {
      final response = await ApiClient.updateAdminProduct(productId, productData);
      final product = ProductEntity.fromJson(response);
      return Right(product);
    } catch (e) {
      return Left('Ошибка обновления товара: $e');
    }
  }

  @override
  Future<Either<String, void>> uploadProductImage(
    int productId, 
    File? imageFile,
    String? base64Image,
  ) async {
    try {
      if (base64Image != null) {
        await ApiClient.uploadProductImageBase64(
          productId, 
          base64Image,
        );
        return Right(null);
      } else {
        return Left('Не выбрано изображение');
      }
    } catch (e) {
      return Left('Ошибка загрузки изображения товара: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteProduct(int productId) async {
    try {
      await ApiClient.deleteAdminProduct(productId);
      return Right(null);
    } catch (e) {
      return Left('Ошибка удаления товара: $e');
    }
  }

  @override
  Future<Either<String, ProductEntity>> toggleProductActive(int productId, bool isActive) async {
    try {
      final response = await ApiClient.updateAdminProduct(productId, {
        'is_active': isActive,
      });
      final product = ProductEntity.fromJson(response);
      return Right(product);
    } catch (e) {
      return Left('Ошибка изменения статуса товара: $e');
    }
  }

  @override
  Future<Either<String, CategoryEntity>> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final response = await ApiClient.createAdminCategory(categoryData);
      final category = CategoryEntity.fromJson(response);
      return Right(category);
    } catch (e) {
      return Left('Ошибка создания категории: $e');
    }
  }

  @override
  Future<Either<String, CategoryEntity>> updateCategory(int categoryId, Map<String, dynamic> categoryData) async {
    try {
      final response = await ApiClient.updateAdminCategory(categoryId, categoryData);
      final category = CategoryEntity.fromJson(response);
      return Right(category);
    } catch (e) {
      return Left('Ошибка обновления категории: $e');
    }
  }

  @override
  Future<Either<String, void>> uploadCategoryImage(
    int categoryId, 
    File? imageFile,
    String? base64Image,
  ) async {
    try {
      if (base64Image != null) {
        await ApiClient.uploadCategoryImageBase64(
          categoryId, 
          base64Image,
        );
        return Right(null);
      } else if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        await ApiClient.uploadCategoryImageBase64(
          categoryId, 
          base64String,
        );
        return Right(null);
      } else {
        return Left('Не выбрано изображение');
      }
    } catch (e) {
      return Left('Ошибка загрузки изображения: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteCategory(int categoryId) async {
    try {
      await ApiClient.deleteAdminCategory(categoryId);
      return Right(null);
    } catch (e) {
      return Left('Ошибка удаления категории: $e');
    }
  }

  @override
  Future<Either<String, TagEntity>> createTag(Map<String, dynamic> tagData) async {
    try {
      final response = await ApiClient.createAdminTag(tagData);
      final tag = TagEntity.fromJson(response);
      return Right(tag);
    } catch (e) {
      return Left('Ошибка создания тега: $e');
    }
  }

  @override
  Future<Either<String, TagEntity>> updateTag(int tagId, Map<String, dynamic> tagData) async {
    try {
      final response = await ApiClient.updateAdminTag(tagId, tagData);
      final tag = TagEntity.fromJson(response);
      return Right(tag);
    } catch (e) {
      return Left('Ошибка обновления тега: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteTag(int tagId) async {
    try {
      await ApiClient.deleteAdminTag(tagId);
      return Right(null);
    } catch (e) {
      return Left('Ошибка удаления тега: $e');
    }
  }
}