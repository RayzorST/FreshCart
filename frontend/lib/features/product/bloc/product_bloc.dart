// [file name]: product_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:client/features/main/bloc/cart_bloc.dart';
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

  ProductBloc({
    required this.product,
    required this.cartRepository,
    required this.favoriteRepository,
    required this.cartBloc
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
      
      // Используем репозиторий вместо прямого вызова ApiClient
      final result = await favoriteRepository.isFavorite(product.id);
      
      result.fold(
        (error) {
          emit(state.copyWith(
            isLoadingFavorite: false,
            errorMessage: error,
          ));
        },
        (isFavorite) {
          emit(state.copyWith(
            isFavorite: isFavorite,
            isLoadingFavorite: false,
          ));
        },
      );
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
      
      // Получаем корзину с сервера через репозиторий
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
        // Удаляем из избранного
        final result = await favoriteRepository.removeFromFavorites(product.id);
        
        result.fold(
          (error) {
            emit(state.copyWith(
              isLoadingFavorite: false,
              errorMessage: error,
            ));
          },
          (_) {
            emit(state.copyWith(
              isFavorite: false,
              isLoadingFavorite: false,
            ));
          },
        );
      } else {
        final result = await favoriteRepository.addToFavorites(product.id);
        
        result.fold(
          (error) {
            emit(state.copyWith(
              isLoadingFavorite: false,
              errorMessage: error,
            ));
          },
          (_) {
            emit(state.copyWith(
              isFavorite: true,
              isLoadingFavorite: false,
            ));
          },
        );
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
      
      // Просто отправляем CartItemUpdated - CartBloc сам разберется
      cartBloc.add(CartItemUpdated(product.id, event.quantity));
      
      // Обновляем локальное состояние
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