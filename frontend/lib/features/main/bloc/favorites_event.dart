part of 'favorites_bloc.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object> get props => [];
}

class FavoritesLoaded extends FavoritesEvent {
  const FavoritesLoaded();
}

class FavoritesSearchChanged extends FavoritesEvent {
  final String query;

  const FavoritesSearchChanged(this.query);

  @override
  List<Object> get props => [query];
}

class FavoritesSearchCleared extends FavoritesEvent {
  const FavoritesSearchCleared();
}

class FavoriteToggled extends FavoritesEvent {
  final int productId;
  final bool isFavorite;
  final ProductEntity? product; // Добавляем product для добавления

  const FavoriteToggled({
    required this.productId,
    required this.isFavorite,
    this.product, // Может быть null при удалении
  });

  @override
  List<Object> get props => [productId, isFavorite];
}

class FavoriteRemoved extends FavoritesEvent {
  final int productId;

  const FavoriteRemoved(this.productId);

  @override
  List<Object> get props => [productId];
}