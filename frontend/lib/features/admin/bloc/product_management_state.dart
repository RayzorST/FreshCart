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
  final List<dynamic> products;
  final List<dynamic> categories;
  final List<dynamic> tags;

  const ProductManagementLoaded({
    required this.products,
    required this.categories,
    required this.tags,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ProductManagementLoaded &&
      listEquals(other.products, products) &&
      listEquals(other.categories, categories) &&
      listEquals(other.tags, tags);
  }

  @override
  int get hashCode => products.hashCode ^ categories.hashCode ^ tags.hashCode;
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