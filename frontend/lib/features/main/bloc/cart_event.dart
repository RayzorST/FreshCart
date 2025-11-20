part of 'cart_bloc.dart';

sealed class CartEvent {
  const CartEvent();
}

class CartLoaded extends CartEvent {
  const CartLoaded();
}

class CartReloaded extends CartEvent {
  const CartReloaded();
}

class CartItemQuantityUpdated extends CartEvent {
  final int productId;
  final int quantity;

  const CartItemQuantityUpdated(this.productId, this.quantity);
}

class CartItemQuantityUpdatedLocally extends CartEvent {
  final int productId;
  final int quantity;

  const CartItemQuantityUpdatedLocally(this.productId, this.quantity);
}

class CartItemRemoved extends CartEvent {
  final int productId;

  const CartItemRemoved(this.productId);
}

class CartOrderCreated extends CartEvent {
  final String? notes;

  const CartOrderCreated([this.notes]);
}

class AddressSelected extends CartEvent {
  final Map<String, dynamic> address;

  const AddressSelected(this.address);
}

class AddressExpandedToggled extends CartEvent {
  final bool isExpanded;

  const AddressExpandedToggled(this.isExpanded);
}

class AddressesLoaded extends CartEvent {
  const AddressesLoaded();
}

class AddressDialogDismissed extends CartEvent {
  const AddressDialogDismissed();
}