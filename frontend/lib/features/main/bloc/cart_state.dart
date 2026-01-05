part of 'cart_bloc.dart';

enum CartStatus {
  initial,
  loading,
  loaded,
  error,
  syncing,
  creatingOrder,
  orderCreated,
}

class CartState {
  final CartStatus status;
  final List<CartItemEntity> cartItems;
  final double totalAmount;
  final double originalTotalAmount;
  final String? error;
  final Map<String, dynamic>? createdOrder;

  const CartState({
    required this.status,
    required this.cartItems,
    required this.totalAmount,
    required this.originalTotalAmount,
    this.error,
    this.createdOrder,
  });

  const CartState.initial()
      : status = CartStatus.initial,
        cartItems = const [],
        totalAmount = 0.0,
        originalTotalAmount = 0.0,
        error = null,
        createdOrder = null;

  CartState copyWith({
    CartStatus? status,
    List<CartItemEntity>? cartItems,
    double? totalAmount,
    double? originalTotalAmount,
    String? error,
    Map<String, dynamic>? createdOrder,
  }) {
    return CartState(
      status: status ?? this.status,
      cartItems: cartItems ?? this.cartItems,
      totalAmount: totalAmount ?? this.totalAmount,
      originalTotalAmount: originalTotalAmount ?? this.originalTotalAmount,
      error: error ?? this.error,
      createdOrder: createdOrder ?? this.createdOrder,
    );
  }
}