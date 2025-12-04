part of 'cart_bloc.dart';

enum CartStatus {
  initial,
  loading,
  loaded,
  error,
  syncing,
}

class CartState {
  final CartStatus status;
  final List<CartItemEntity> cartItems;
  final double totalAmount;
  final double originalTotalAmount;
  final String? error;

  const CartState({
    required this.status,
    required this.cartItems,
    required this.totalAmount,
    required this.originalTotalAmount,
    this.error,
  });

  const CartState.initial()
      : status = CartStatus.initial,
        cartItems = const [],
        totalAmount = 0.0,
        originalTotalAmount = 0.0,
        error = null;

  CartState copyWith({
    CartStatus? status,
    List<CartItemEntity>? cartItems,
    double? totalAmount,
    double? originalTotalAmount,
    String? error,
  }) {
    return CartState(
      status: status ?? this.status,
      cartItems: cartItems ?? this.cartItems,
      totalAmount: totalAmount ?? this.totalAmount,
      originalTotalAmount: originalTotalAmount ?? this.originalTotalAmount,
      error: error ?? this.error,
    );
  }
}