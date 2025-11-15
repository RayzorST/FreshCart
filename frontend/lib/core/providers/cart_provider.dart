import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';

final selectedAddressProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final isAddressExpandedProvider = StateProvider<bool>((ref) => false);
final addressesListProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiClient.getAddresses();
});

final cartProvider = StateNotifierProvider<CartNotifier, Map<int, int>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<Map<int, int>> {
  CartNotifier() : super({}) {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final cartData = await ApiClient.getCart();
      final cartMap = <int, int>{};
      
      for (var item in cartData['items'] ?? []) {
        cartMap[item['product_id']] = item['quantity'];
      }
      
      state = cartMap;
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<void> addToCart(int productId) async {
    try {
      final currentQuantity = state[productId] ?? 0;
      if (currentQuantity == 0) {
        await ApiClient.addToCart(productId, 1);
      } else {
        await ApiClient.updateCartItem(productId, currentQuantity + 1);
      }
      
      state = {...state, productId: currentQuantity + 1};
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    try {
      if (quantity == 0) {
        await ApiClient.removeFromCart(productId);
        final newState = {...state};
        newState.remove(productId);
        state = newState;
      } else {
        await ApiClient.updateCartItem(productId, quantity);
        state = {...state, productId: quantity};
      }
    } catch (e) {
      print('Error updating cart quantity: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(int productId) async {
    await updateQuantity(productId, 0);
  }

  int getQuantity(int productId) {
    return state[productId] ?? 0;
  }
}