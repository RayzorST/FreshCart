part of 'cart_bloc.dart';

sealed class CartEvent {
  const CartEvent();
}

class CartLoaded extends CartEvent {
  const CartLoaded();
}

class CartItemUpdated extends CartEvent {
  final int productId;
  final int quantity;

  const CartItemUpdated(this.productId, this.quantity);
}

class CartItemRemoved extends CartEvent {
  final int productId;

  const CartItemRemoved(this.productId);
}