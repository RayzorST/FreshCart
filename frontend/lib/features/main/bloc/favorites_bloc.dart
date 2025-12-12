import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/entities/favorite_item_entity.dart';
import 'package:client/domain/repositories/favorite_repository.dart';
import 'package:client/domain/entities/product_entity.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

@injectable
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoriteRepository _favoriteRepository;
  Timer? _searchDebounce;

  FavoritesBloc(this._favoriteRepository) : super(const FavoritesState.initial()) {
    on<FavoritesLoaded>(_onFavoritesLoaded);
    on<FavoritesSearchChanged>(_onFavoritesSearchChanged);
    on<FavoritesSearchCleared>(_onFavoritesSearchCleared);
    on<FavoriteToggled>(_onFavoriteToggled);
    on<FavoriteRemoved>(_onFavoriteRemoved);
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
      final result = await _favoriteRepository.getFavorites();
      
      result.fold(
        (error) {
          emit(state.copyWith(
            status: FavoritesStatus.error,
            error: error,
          ));
        },
        (favorites) {
          emit(state.copyWith(
            status: FavoritesStatus.loaded,
            favorites: favorites,
            filteredFavorites: favorites,
          ));
        },
      );
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
      // Для серверного поиска можно добавить отдельное событие
      // если API поддерживает поиск в избранном
      // add(FavoritesSearchPerformed(query: query));
    });
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

  Future<void> _onFavoriteToggled(
    FavoriteToggled event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      if (event.isFavorite) {
        // Добавляем в избранное
        final productEntity = _findProductById(event.productId);
        if (productEntity != null) {
          final favoriteItem = FavoriteItemEntity(
            product: productEntity,
            addedAt: DateTime.now(),
          );
          await _favoriteRepository.addToFavorites(favoriteItem);
        }
      } else {
        // Удаляем из избранного
        await _favoriteRepository.removeFromFavorites(event.productId);
      }

      // Обновляем список
      add(const FavoritesLoaded());
      
    } catch (e) {
      emit(state.copyWith(
        error: 'Ошибка обновления избранного: $e',
      ));
    }
  }

  Future<void> _onFavoriteRemoved(
    FavoriteRemoved event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _favoriteRepository.removeFromFavorites(event.productId);
      
      // Обновляем локальный список
      final updatedFavorites = List<FavoriteItemEntity>.from(state.favorites)
        ..removeWhere((fav) => fav.product.id == event.productId);
      
      final updatedFiltered = _performLocalSearch(updatedFavorites, state.searchQuery);

      emit(state.copyWith(
        favorites: updatedFavorites,
        filteredFavorites: updatedFiltered,
      ));
      
    } catch (e) {
      emit(state.copyWith(
        error: 'Ошибка удаления из избранного: $e',
      ));
    }
  }

  List<FavoriteItemEntity> _performLocalSearch(
    List<FavoriteItemEntity> favorites, 
    String query
  ) {
    if (query.isEmpty) return favorites;

    return favorites.where((favorite) {
      final productName = favorite.product.name.toLowerCase();
      final category = favorite.product.category?.toLowerCase() ?? '';
      return productName.contains(query.toLowerCase()) || 
             category.contains(query.toLowerCase());
    }).toList();
  }

  // Вспомогательный метод для нахождения продукта
  ProductEntity? _findProductById(int productId) {
    for (final favorite in state.favorites) {
      if (favorite.product.id == productId) {
        return favorite.product;
      }
    }
    return null;
  }
}