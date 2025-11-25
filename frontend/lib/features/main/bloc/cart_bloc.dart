import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';
import 'package:flutter/foundation.dart';
part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState.initial()) {
    on<CartLoaded>(_onCartLoaded);
    on<CartItemQuantityUpdated>(_onCartItemQuantityUpdated);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartOrderCreated>(_onCartOrderCreated);
    on<CartReloaded>(_onCartReloaded);
    on<AddressSelected>(_onAddressSelected);
    on<AddressExpandedToggled>(_onAddressExpandedToggled);
    on<AddressesLoaded>(_onAddressesLoaded);
    on<CartItemQuantityUpdatedLocally>(_onCartItemQuantityUpdatedLocally);
  }

  Future<void> _onCartLoaded(
    CartLoaded event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.loading));
    
    try {
      final cartData = await ApiClient.getCart();
      final items = await _enrichCartItems(cartData['items'] ?? []);
      
      emit(state.copyWith(
        status: CartStatus.loaded,
        cartItems: items,
        totalAmount: (cartData['final_price'] as num?)?.toDouble() ?? 0.0,
        originalTotalAmount: (cartData['total_price'] as num?)?.toDouble() ?? 0.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: 'Ошибка загрузки корзины: $e',
      ));
    }
  }

  Future<void> _onCartReloaded(
    CartReloaded event,
    Emitter<CartState> emit,
  ) async {
    add(const CartLoaded());
  }

  Future<void> _onCartItemQuantityUpdated(
    CartItemQuantityUpdated event,
    Emitter<CartState> emit,
  ) async {
    final previousState = state;
    
    try {
      final updatedItems = _updateLocalQuantity(
        state.cartItems, 
        event.productId, 
        event.quantity
      );
      
      final newTotal = _calculateTotalAmount(updatedItems);
      final newOriginalTotal = _calculateOriginalTotalAmount(updatedItems);
      
      emit(state.copyWith(
        cartItems: updatedItems,
        totalAmount: newTotal,
        originalTotalAmount: newOriginalTotal,
      ));

      final isItemInCart = state.cartItems.any((item) => item['product_id'] == event.productId);
      
      if (event.quantity == 0) {
        await ApiClient.removeFromCart(event.productId);
      } else if (!isItemInCart) {
        await ApiClient.addToCart(event.productId, event.quantity);
      } else {
        await ApiClient.updateCartItem(event.productId, event.quantity);
      }

      add(const CartReloaded());
      
    } catch (e) {
      emit(previousState);
      
      emit(state.copyWith(
        error: 'Ошибка обновления корзины: $e',
      ));

      add(const CartReloaded());
    }
  }

  void _onCartItemQuantityUpdatedLocally(
    CartItemQuantityUpdatedLocally event,
    Emitter<CartState> emit,
  ) {
    final updatedItems = _updateLocalQuantity(
      state.cartItems, 
      event.productId, 
      event.quantity
    );
    
    final newTotal = _calculateTotalAmount(updatedItems);
    final newOriginalTotal = _calculateOriginalTotalAmount(updatedItems);
    
    emit(state.copyWith(
      cartItems: updatedItems,
      totalAmount: newTotal,
      originalTotalAmount: newOriginalTotal,
    ));
  }

  Future<void> _onCartItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    add(CartItemQuantityUpdated(event.productId, 0));
  }

  Future<void> _onCartOrderCreated(
    CartOrderCreated event,
    Emitter<CartState> emit,
  ) async {
    if (state.selectedAddress == null) {
      emit(state.copyWith(
        error: 'Не выбран адрес доставки',
        showAddressDialog: true,
      ));
      return;
    }

    emit(state.copyWith(status: CartStatus.creatingOrder));
    
    try {
      final orderItems = state.cartItems.map<Map<String, dynamic>>((item) {
        return {
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': (item['display_price'] as num).toDouble(),
        };
      }).toList();
      
      await ApiClient.createOrder(
        state.selectedAddress!['address_line'],
        event.notes ?? '',
        orderItems,
      );

      // Очищаем корзину после успешного заказа
      for (var item in state.cartItems) {
        await ApiClient.removeFromCart(item['product_id']);
      }

      emit(state.copyWith(
        status: CartStatus.orderCreated,
        cartItems: [],
        totalAmount: 0.0,
        originalTotalAmount: 0.0,
      ));
      
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: 'Ошибка создания заказа: $e',
      ));
      rethrow;
    }
  }

  Future<void> _onAddressSelected(
    AddressSelected event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(
      selectedAddress: event.address,
      isAddressExpanded: false,
    ));
  }

  void _onAddressExpandedToggled(
    AddressExpandedToggled event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(isAddressExpanded: event.isExpanded));
  }

  Future<void> _onAddressesLoaded(
    AddressesLoaded event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(addressesStatus: CartStatus.loading));
    
    try {
      final addresses = await ApiClient.getAddresses();
      
      // Автоматически выбираем адрес по умолчанию
      Map<String, dynamic>? selectedAddress;
      if (addresses.isNotEmpty) {
        selectedAddress = addresses.firstWhere(
          (addr) => addr['is_default'] == true,
          orElse: () => addresses.first,
        );
      }
      
      emit(state.copyWith(
        addressesStatus: CartStatus.loaded,
        addresses: addresses,
        selectedAddress: selectedAddress,
      ));
    } catch (e) {
      emit(state.copyWith(
        addressesStatus: CartStatus.error,
        addressesError: 'Ошибка загрузки адресов: $e',
      ));
    }
  }

  List<dynamic> _updateLocalQuantity(
    List<dynamic> items, 
    int productId, 
    int quantity
  ) {
    final updatedItems = List<dynamic>.from(items);
    final index = updatedItems.indexWhere(
      (item) => item['product_id'] == productId
    );
    
    if (index != -1) {
      if (quantity == 0) {
        updatedItems.removeAt(index);
      } else {
        final item = Map<String, dynamic>.from(updatedItems[index]);
        item['quantity'] = quantity;
        updatedItems[index] = item;
      }
    }
    
    return updatedItems;
  }

  double _calculateTotalAmount(List<dynamic> items) {
    double total = 0.0;
    for (var item in items) {
      final quantity = (item['quantity'] as num).toInt();
      final price = (item['display_price'] as num).toDouble();
      total += price * quantity;
    }
    return total;
  }

  double _calculateOriginalTotalAmount(List<dynamic> items) {
    double total = 0.0;
    for (var item in items) {
      final quantity = (item['quantity'] as num).toInt();
      final originalPrice = (item['original_price'] as num?)?.toDouble() ?? 
                           (item['display_price'] as num).toDouble();
      total += originalPrice * quantity;
    }
    return total;
  }

  Future<List<dynamic>> _enrichCartItems(List<dynamic> items) async {
    if (items.isEmpty) return [];

    try {
      final products = await ApiClient.getProducts();
      final enrichedItems = <dynamic>[];

      for (var item in items) {
        final itemMap = _convertToSafeMap(item);
        final productId = itemMap['product_id'];
        
        Map<String, dynamic>? foundProduct;
        for (var product in products) {
          final productMap = _convertToSafeMap(product);
          if (productMap['id'] == productId) {
            foundProduct = productMap;
            break;
          }
        }

        final originalPrice = foundProduct?['price'] ?? itemMap['price'] ?? 0.0;
        final discountedPrice = itemMap['discount_price'] ?? itemMap['display_price'] ?? originalPrice;
        final hasDiscount = discountedPrice < originalPrice;
        final appliedPromotions = itemMap['applied_promotions'] ?? [];

        enrichedItems.add({
          ...itemMap,
          'product': foundProduct,
          'display_price': discountedPrice,
          'original_price': originalPrice,
          'has_discount': hasDiscount,
          'discount_amount': originalPrice - discountedPrice,
          'applied_promotions': appliedPromotions,
        });
      }

      return enrichedItems;
    } catch (e) {
      return items.map((item) => _convertToSafeMap(item)).toList();
    }
  }

  Map<String, dynamic> _convertToSafeMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (e) {
        return {};
      }
    }
    return {};
  }
}