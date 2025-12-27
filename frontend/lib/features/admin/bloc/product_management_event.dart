part of 'product_management_bloc.dart';

abstract class ProductManagementEvent {
  const ProductManagementEvent();
}

class LoadProductData extends ProductManagementEvent {
  const LoadProductData();
}

class CreateProduct extends ProductManagementEvent {
  final Map<String, dynamic> productData;

  const CreateProduct(this.productData);
}

class UpdateProduct extends ProductManagementEvent {
  final int productId;
  final Map<String, dynamic> productData;

  const UpdateProduct({
    required this.productId,
    required this.productData,
  });
}

class UploadProductImage extends ProductManagementEvent {
  final int productId;
  final String? base64Image;

  const UploadProductImage({
    required this.productId,
    this.base64Image,
  });
}

class DeleteProduct extends ProductManagementEvent {
  final int productId;

  const DeleteProduct(this.productId);
}

class ToggleProductActive extends ProductManagementEvent {
  final int productId;
  final bool isActive;

  const ToggleProductActive({
    required this.productId,
    required this.isActive,
  });
}

class CreateCategory extends ProductManagementEvent {
  final Map<String, dynamic> categoryData;

  const CreateCategory(this.categoryData);
}

class UpdateCategory extends ProductManagementEvent {
  final int categoryId;
  final Map<String, dynamic> categoryData;

  const UpdateCategory({
    required this.categoryId,
    required this.categoryData,
  });
}

class UploadCategoryImage extends ProductManagementEvent {
  final int categoryId;
  final String? base64Image;

  const UploadCategoryImage({
    required this.categoryId,
    this.base64Image,
  });
}

class DeleteCategory extends ProductManagementEvent {
  final int categoryId;

  const DeleteCategory(this.categoryId);
}

class CreateTag extends ProductManagementEvent {
  final Map<String, dynamic> tagData;

  const CreateTag(this.tagData);
}

class UpdateTag extends ProductManagementEvent {
  final int tagId;
  final Map<String, dynamic> tagData;

  const UpdateTag({
    required this.tagId,
    required this.tagData,
  });
}

class DeleteTag extends ProductManagementEvent {
  final int tagId;

  const DeleteTag(this.tagId);
}