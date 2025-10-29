import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Map<int, bool>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Map<int, bool>> {
  FavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await ApiClient.getFavorites();
      final favoritesMap = <int, bool>{};
      for (var favorite in favorites) {
        favoritesMap[favorite['product_id']] = true;
      }
      state = favoritesMap;
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(int productId, bool isFavorite) async {
    try {
      if (isFavorite) {
        await ApiClient.addToFavorites(productId);
        state = {...state, productId: true};
      } else {
        await ApiClient.removeFromFavorites(productId);
        final newState = {...state};
        newState.remove(productId);
        state = newState;
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Метод для проверки, есть ли товар в избранном
  bool isFavorite(int productId) {
    return state[productId] ?? false;
  }
}