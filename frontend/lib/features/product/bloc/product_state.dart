part of 'product_bloc.dart';

class ProductState {
  final int quantity;
  final bool isFavorite;
  final bool isLoadingFavorite;
  final bool isLoadingCart;
  final String? errorMessage;

  const ProductState({
    this.quantity = 0,
    this.isFavorite = false,
    this.isLoadingFavorite = false,
    this.isLoadingCart = false,
    this.errorMessage,
  });

  ProductState copyWith({
    int? quantity,
    bool? isFavorite,
    bool? isLoadingFavorite,
    bool? isLoadingCart,
    String? errorMessage,
  }) {
    return ProductState(
      quantity: quantity ?? this.quantity,
      isFavorite: isFavorite ?? this.isFavorite,
      isLoadingFavorite: isLoadingFavorite ?? this.isLoadingFavorite,
      isLoadingCart: isLoadingCart ?? this.isLoadingCart,
      errorMessage: errorMessage,
    );
  }
}