part of 'cart_bloc.dart';

sealed class CartEvent {
  const CartEvent();
}

class CartLoaded extends CartEvent {
  const CartLoaded();
}

class CartItemAdded extends CartEvent {
  final CartItemEntity item;

  const CartItemAdded(this.item);
}

class CartItemUpdated extends CartEvent {
  final CartItemEntity item;

  const CartItemUpdated(this.item);
}

class CartItemRemoved extends CartEvent {
  final int productId;

  const CartItemRemoved(this.productId);
}

class CartSyncedWithServer extends CartEvent {
  const CartSyncedWithServer();
}