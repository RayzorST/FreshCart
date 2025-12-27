import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/entities/category_entity.dart';
import 'package:client/domain/entities/tag_entity.dart';

abstract class ProductManagementRepository {
  // Загрузка данных
  Future<Either<String, Map<String, dynamic>>> loadProductData();
  
  // Товары
  Future<Either<String, ProductEntity>> createProduct(Map<String, dynamic> productData);
  Future<Either<String, ProductEntity>> updateProduct(int productId, Map<String, dynamic> productData);
  Future<Either<String, void>> uploadProductImage(int productId, File? imageFile,String? base64Image,);
  Future<Either<String, void>> deleteProduct(int productId);
  Future<Either<String, ProductEntity>> toggleProductActive(int productId, bool isActive);
  
  // Категории
  Future<Either<String, CategoryEntity>> createCategory(Map<String, dynamic> categoryData);
  Future<Either<String, CategoryEntity>> updateCategory(int categoryId, Map<String, dynamic> categoryData);
  Future<Either<String, void>> uploadCategoryImage(int categoryId, File? imageFile, String? base64Image,);
  Future<Either<String, void>> deleteCategory(int categoryId);
  
  // Теги
  Future<Either<String, TagEntity>> createTag(Map<String, dynamic> tagData);
  Future<Either<String, TagEntity>> updateTag(int tagId, Map<String, dynamic> tagData);
  Future<Either<String, void>> deleteTag(int tagId);
}