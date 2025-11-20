part of 'cart_bloc.dart';

enum CartStatus {
  initial,
  loading,
  loaded,
  error,
  creatingOrder,
  orderCreated,
}

class CartState {
  final CartStatus status;
  final List<dynamic> cartItems;
  final double totalAmount;
  final double originalTotalAmount;
  final String? error;
  final CartStatus addressesStatus;
  final List<dynamic> addresses;
  final String? addressesError;
  final Map<String, dynamic>? selectedAddress;
  final bool isAddressExpanded;
  final bool showAddressDialog;
  final Set<int> updatingProducts; 

  const CartState({
    required this.status,
    required this.cartItems,
    required this.totalAmount,
    required this.originalTotalAmount,
    this.error,
    required this.addressesStatus,
    required this.addresses,
    this.addressesError,
    this.selectedAddress,
    required this.isAddressExpanded,
    required this.showAddressDialog,
    required this.updatingProducts,
  });

  const CartState.initial()
      : status = CartStatus.initial,
        cartItems = const [],
        totalAmount = 0.0,
        originalTotalAmount = 0.0,
        error = null,
        addressesStatus = CartStatus.initial,
        addresses = const [],
        addressesError = null,
        selectedAddress = null,
        isAddressExpanded = false,
        showAddressDialog = false,
        updatingProducts = const {};

  CartState copyWith({
    CartStatus? status,
    List<dynamic>? cartItems,
    double? totalAmount,
    double? originalTotalAmount,
    String? error,
    CartStatus? addressesStatus,
    List<dynamic>? addresses,
    String? addressesError,
    Map<String, dynamic>? selectedAddress,
    bool? isAddressExpanded,
    bool? showAddressDialog,
    Set<int>? updatingProducts,
  }) {
    return CartState(
      status: status ?? this.status,
      cartItems: cartItems ?? this.cartItems,
      totalAmount: totalAmount ?? this.totalAmount,
      originalTotalAmount: originalTotalAmount ?? this.originalTotalAmount,
      error: error ?? this.error,
      addressesStatus: addressesStatus ?? this.addressesStatus,
      addresses: addresses ?? this.addresses,
      addressesError: addressesError ?? this.addressesError,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isAddressExpanded: isAddressExpanded ?? this.isAddressExpanded,
      showAddressDialog: showAddressDialog ?? this.showAddressDialog,
      updatingProducts: updatingProducts ?? this.updatingProducts,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CartState &&
        other.status == status &&
        listEquals(other.cartItems, cartItems) &&
        other.totalAmount == totalAmount &&
        other.originalTotalAmount == originalTotalAmount &&
        other.error == error &&
        other.addressesStatus == addressesStatus &&
        listEquals(other.addresses, addresses) &&
        other.addressesError == addressesError &&
        other.selectedAddress == selectedAddress &&
        other.isAddressExpanded == isAddressExpanded &&
        other.showAddressDialog == showAddressDialog &&
        setEquals(other.updatingProducts, updatingProducts);
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      cartItems,
      totalAmount,
      originalTotalAmount,
      error,
      addressesStatus,
      addresses,
      addressesError,
      selectedAddress,
      isAddressExpanded,
      showAddressDialog,
      updatingProducts,
    );
  }
}