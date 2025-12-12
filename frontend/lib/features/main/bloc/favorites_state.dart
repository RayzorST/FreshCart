part of 'favorites_bloc.dart';

enum FavoritesStatus {
  initial,
  loading,
  loaded,
  error,
}

class FavoritesState extends Equatable {
  final FavoritesStatus status;
  final List<FavoriteItemEntity> favorites;
  final List<FavoriteItemEntity> filteredFavorites;
  final String searchQuery;
  final bool isSearching;
  final String? error;

  const FavoritesState({
    required this.status,
    required this.favorites,
    required this.filteredFavorites,
    required this.searchQuery,
    required this.isSearching,
    this.error,
  });

  const FavoritesState.initial()
      : status = FavoritesStatus.initial,
        favorites = const [],
        filteredFavorites = const [],
        searchQuery = '',
        isSearching = false,
        error = null;

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<FavoriteItemEntity>? favorites,
    List<FavoriteItemEntity>? filteredFavorites,
    String? searchQuery,
    bool? isSearching,
    String? error,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      favorites: favorites ?? this.favorites,
      filteredFavorites: filteredFavorites ?? this.filteredFavorites,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        favorites,
        filteredFavorites,
        searchQuery,
        isSearching,
        error,
      ];
}