// product_management_state.dart
part of 'product_management_bloc.dart';

abstract class ProductManagementState {
  const ProductManagementState();
}

class ProductManagementInitial extends ProductManagementState {
  const ProductManagementInitial();
}

class ProductManagementLoading extends ProductManagementState {
  const ProductManagementLoading();
}

class ProductManagementLoaded extends ProductManagementState {
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;
  final List<TagEntity> tags;

  const ProductManagementLoaded({
    required this.products,
    required this.categories,
    required this.tags,
  });

  // Вспомогательные методы
  List<ProductEntity> get activeProducts => products.where((p) => p.isActive).toList();
  List<ProductEntity> get inactiveProducts => products.where((p) => !p.isActive).toList();
  
  CategoryEntity? getCategoryById(int? id) {
    if (id == null) return null;
    return categories.firstWhere((c) => c.id == id, orElse: () => CategoryEntity(id: -1, name: 'Неизвестно'));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ProductManagementLoaded &&
      _listsEqual(other.products, products) &&
      _listsEqual(other.categories, categories) &&
      _listsEqual(other.tags, tags);
  }

  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    products.length,
    categories.length,
    tags.length,
  );
}

class ProductManagementError extends ProductManagementState {
  final String message;

  const ProductManagementError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ProductManagementError &&
      other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class ProductManagementOperationSuccess extends ProductManagementState {
  final String message;

  const ProductManagementOperationSuccess(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ProductManagementOperationSuccess &&
      other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}