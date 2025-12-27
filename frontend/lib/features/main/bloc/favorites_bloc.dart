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
    if (state.status == FavoritesStatus.loaded && state.favorites.isNotEmpty) {
      return;
    }

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
          final filteredFavorites = _performLocalSearch(favorites, state.searchQuery);
          
          emit(state.copyWith(
            status: FavoritesStatus.loaded,
            favorites: favorites,
            filteredFavorites: filteredFavorites,
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

  Future<void> _onFavoritesSearchChanged(
    FavoritesSearchChanged event,
    Emitter<FavoritesState> emit,
  ) async {
    _searchDebounce?.cancel();

    final query = event.query.trim();
    
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isNotEmpty) {
        // Ищем на сервере
        final result = await _favoriteRepository.getFavorites(search: query);
        
        result.fold(
          (error) {
            emit(state.copyWith(
              searchQuery: query,
              error: error,
            ));
          },
          (filteredFavorites) {
            emit(state.copyWith(
              searchQuery: query,
              filteredFavorites: filteredFavorites,
              isSearching: true,
            ));
          },
        );
      } else {
        // Локальный поиск если query пустой
        final filteredFavorites = _performLocalSearch(state.favorites, query);
        
        emit(state.copyWith(
          searchQuery: query,
          filteredFavorites: filteredFavorites,
          isSearching: false,
        ));
      }
    });
  }

  Future<void> _onFavoritesSearchCleared(
    FavoritesSearchCleared event,
    Emitter<FavoritesState> emit,
  ) async {
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
        final result = await _favoriteRepository.addToFavorites(event.productId);
        
        result.fold(
          (error) {
            emit(state.copyWith(error: error));
          },
          (favoriteItem) {
            final updatedFavorites = List<FavoriteItemEntity>.from(state.favorites)
              ..add(favoriteItem);
            
            final filteredFavorites = _performLocalSearch(updatedFavorites, state.searchQuery);
            
            emit(state.copyWith(
              favorites: updatedFavorites,
              filteredFavorites: filteredFavorites,
            ));
          },
        );
      } else {
        final result = await _favoriteRepository.removeFromFavorites(event.productId);
        
        result.fold(
          (error) {
            emit(state.copyWith(error: error));
          },
          (_) {
            final updatedFavorites = List<FavoriteItemEntity>.from(state.favorites)
              ..removeWhere((fav) => fav.product.id == event.productId);
            
            final updatedFiltered = _performLocalSearch(updatedFavorites, state.searchQuery);

            emit(state.copyWith(
              favorites: updatedFavorites,
              filteredFavorites: updatedFiltered,
            ));
          },
        );
      }
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
      final result = await _favoriteRepository.removeFromFavorites(event.productId);
      
      result.fold(
        (error) {
          emit(state.copyWith(error: error));
        },
        (_) {
          final updatedFavorites = List<FavoriteItemEntity>.from(state.favorites)
            ..removeWhere((fav) => fav.product.id == event.productId);
          
          final updatedFiltered = _performLocalSearch(updatedFavorites, state.searchQuery);

          emit(state.copyWith(
            favorites: updatedFavorites,
            filteredFavorites: updatedFiltered,
          ));
        },
      );
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

    // Ищем только по названию продукта, так как у нас нет доступа к названиям категорий
    // В FavoriteItemEntity хранится только ProductEntity с categoryId
    return favorites.where((favorite) {
      final productName = favorite.product.name.toLowerCase();
      // Убираем поиск по категории, т.к. нет доступа к названию категории
      return productName.contains(query.toLowerCase());
    }).toList();
  }
}