import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';
import 'package:equatable/equatable.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  Timer? _searchDebounce;

  FavoritesBloc() : super(const FavoritesState.initial()) {
    on<FavoritesLoaded>(_onFavoritesLoaded);
    on<FavoritesSearchChanged>(_onFavoritesSearchChanged);
    on<FavoritesSearchPerformed>(_onFavoritesSearchPerformed);
    on<FavoriteToggled>(_onFavoriteToggled);
    on<FavoritesSearchCleared>(_onFavoritesSearchCleared);
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> _onFavoritesLoaded(
    FavoritesLoaded event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(state.copyWith(status: FavoritesStatus.loading));
    
    try {
      final favorites = await ApiClient.getFavorites();
      emit(state.copyWith(
        status: FavoritesStatus.loaded,
        favorites: favorites,
        filteredFavorites: favorites,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FavoritesStatus.error,
        error: 'Ошибка загрузки избранного: $e',
      ));
    }
  }

  void _onFavoritesSearchChanged(
    FavoritesSearchChanged event,
    Emitter<FavoritesState> emit,
  ) {
    _searchDebounce?.cancel();

    final query = event.query.trim();
    
    if (query.isEmpty) {
      emit(state.copyWith(
        searchQuery: query,
        filteredFavorites: state.favorites,
        isSearching: false,
      ));
      return;
    }

    final localResults = _performLocalSearch(state.favorites, query);
    emit(state.copyWith(
      searchQuery: query,
      filteredFavorites: localResults,
      isSearching: true,
    ));

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      add(FavoritesSearchPerformed(query: query));
    });
  }

  Future<void> _onFavoritesSearchPerformed(
    FavoritesSearchPerformed event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final searchResults = await ApiClient.getFavorites(search: event.query);
      emit(state.copyWith(
        filteredFavorites: searchResults,
        isSearching: true,
      ));
    } catch (e) {
      print('Server search error: $e');
    }
  }

  Future<void> _onFavoriteToggled(
    FavoriteToggled event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      if (event.isFavorite) {
        await ApiClient.addToFavorites(event.productId);
      } else {
        await ApiClient.removeFromFavorites(event.productId);
      }

      final updatedFavorites = List<dynamic>.from(state.favorites);
      if (!event.isFavorite) {
        updatedFavorites.removeWhere((fav) => fav['product_id'] == event.productId);
      } else {
        final products = await ApiClient.getProducts();
        final product = products.firstWhere(
          (p) => p['id'] == event.productId,
          orElse: () => {'id': event.productId},
        );
        updatedFavorites.add({
          'product_id': event.productId,
          'product': product,
        });
      }

      final updatedFiltered = _performLocalSearch(updatedFavorites, state.searchQuery);

      emit(state.copyWith(
        favorites: updatedFavorites,
        filteredFavorites: updatedFiltered,
      ));

    } catch (e) {
      emit(state.copyWith(
        error: 'Ошибка обновления избранного: $e',
      ));
      rethrow;
    }
  }

  void _onFavoritesSearchCleared(
    FavoritesSearchCleared event,
    Emitter<FavoritesState> emit,
  ) {
    _searchDebounce?.cancel();
    emit(state.copyWith(
      searchQuery: '',
      filteredFavorites: state.favorites,
      isSearching: false,
    ));
  }

  List<dynamic> _performLocalSearch(List<dynamic> favorites, String query) {
    if (query.isEmpty) return favorites;

    return favorites.where((favorite) {
      final product = favorite['product'];
      final productName = product['name']?.toString().toLowerCase() ?? '';
      return productName.contains(query.toLowerCase());
    }).toList();
  }
}