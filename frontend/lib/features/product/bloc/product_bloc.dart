// [file name]: product_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:client/features/main/bloc/cart_bloc.dart';
import 'package:client/features/main/bloc/favorites_bloc.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/repositories/cart_repository.dart';
import 'package:client/domain/repositories/favorite_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductEntity product;
  final CartRepository cartRepository;
  final FavoriteRepository favoriteRepository;
  final CartBloc cartBloc;
  final FavoritesBloc favoritesBloc;

  ProductBloc({
    required this.product,
    required this.cartRepository,
    required this.favoriteRepository,
    required this.cartBloc,
    required this.favoritesBloc,
  }) : super(const ProductState()) {
    on<ProductLoadFavoriteStatus>(_onLoadFavoriteStatus);
    on<ProductLoadCartQuantity>(_onLoadCartQuantity);
    on<ProductToggleFavorite>(_onToggleFavorite);
    on<ProductUpdateCartQuantity>(_onUpdateCartQuantity);
  }

  Future<void> _onLoadFavoriteStatus(
    ProductLoadFavoriteStatus event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingFavorite: true));

      final favoritesState = favoritesBloc.state;
      final isProductInFavorites = favoritesState.favorites.any(
        (fav) => fav.product.id == product.id
      );

      emit(state.copyWith(
        isFavorite: isProductInFavorites,
        isLoadingFavorite: false,
      ));

    } catch (e) {
      emit(state.copyWith(
        isLoadingFavorite: false,
        errorMessage: 'Ошибка загрузки статуса избранного',
      ));
    }
  }

  Future<void> _onLoadCartQuantity(
    ProductLoadCartQuantity event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingCart: true));
      
      final result = await cartRepository.getCartItems();
      
      result.fold(
        (error) {
          emit(state.copyWith(
            quantity: 0,
            isLoadingCart: false,
            errorMessage: error,
          ));
        },
        (cartItems) {
          final cartItem = cartItems.firstWhere(
            (item) => item.product.id == product.id,
          );
          
          emit(state.copyWith(
            quantity: cartItem.quantity,
            isLoadingCart: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        quantity: 0,
        isLoadingCart: false,
      ));
    }
  }

  Future<void> _onToggleFavorite(
    ProductToggleFavorite event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingFavorite: true));
      
      if (state.isFavorite) {
        favoritesBloc.add(FavoriteRemoved(product.id));
        
        emit(state.copyWith(
          isFavorite: false,
          isLoadingFavorite: false,
        ));
      } else {
        favoritesBloc.add(FavoriteToggled(
          productId: product.id,
          isFavorite: true,
          product: product,
        ));
        
        emit(state.copyWith(
          isFavorite: true,
          isLoadingFavorite: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoadingFavorite: false,
        errorMessage: 'Ошибка при обновлении избранного: $e',
      ));
    }
  }

  Future<void> _onUpdateCartQuantity(
    ProductUpdateCartQuantity event,
    Emitter<ProductState> emit,
  ) async {
    if (state.isLoadingCart || event.quantity < 0) return;
    
    try {
      emit(state.copyWith(isLoadingCart: true));
      
      if (event.quantity == 0){
        cartBloc.add(CartItemRemoved(product.id));
      }
      else{
        cartBloc.add(CartItemUpdated(product.id, event.quantity));
      }
      
      emit(state.copyWith(
        quantity: event.quantity,
        isLoadingCart: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingCart: false,
        errorMessage: 'Ошибка при обновлении корзины: $e',
      ));
    }
  }
}