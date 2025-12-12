import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/entities/favorite_item_entity.dart';
import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:client/domain/repositories/cart_repository.dart';
import 'package:client/domain/repositories/favorite_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductEntity product;
  final CartRepository cartRepository;
  final FavoriteRepository favoriteRepository;

  ProductBloc(
    this.product,
    this.cartRepository,
    this.favoriteRepository,
  ) : super(const ProductState()) {
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
      
      // Проверяем в локальном репозитории
      final favoriteResult = await favoriteRepository.isFavorite(product.id);
      
      // Если нужно, можно также проверить на сервере
      try {
        final response = await ApiClient.checkFavorite(product.id);
        final serverIsFavorite = response['is_favorite'] ?? false;
        
        // Синхронизируем состояния
        if (serverIsFavorite != favoriteResult) {
          if (serverIsFavorite) {
            await favoriteRepository.addToFavorites(FavoriteItemEntity(
              product: product,
              addedAt: DateTime.now(),
            ));
          } else {
            await favoriteRepository.removeFromFavorites(product.id);
          }
        }
        
        emit(state.copyWith(
          isFavorite: serverIsFavorite,
          isLoadingFavorite: false,
        ));
      } catch (e) {
        // Если сервер недоступен, используем локальное значение
        emit(state.copyWith(
          isFavorite: favoriteResult,
          isLoadingFavorite: false,
        ));
      }
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
      // Получаем из локальной корзины
      final cartResult = await cartRepository.getCartItems();
      
      cartResult.fold(
        (error) {
          // Ошибка при получении корзины
          emit(state.copyWith(quantity: 0));
        },
        (cartItems) {
          try {
            final cartItem = cartItems.firstWhere(
              (item) => item.product.id == product.id,
              orElse: () => CartItemEntity(
                product: product,
                quantity: 0,
                addedAt: DateTime.now(),
              ),
            );
            
            emit(state.copyWith(quantity: cartItem.quantity));
          } catch (e) {
            emit(state.copyWith(quantity: 0));
          }
        },
      );
    } catch (e) {
      // Игнорируем ошибку загрузки корзины
      emit(state.copyWith(quantity: 0));
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
          (_) async {
            // Синхронизируем с сервером
            try {
              await ApiClient.removeFromFavorites(product.id);
            } catch (e) {
              // Сервер недоступен, но локально уже удалили
            }
            
            emit(state.copyWith(
              isFavorite: false,
              isLoadingFavorite: false,
            ));
          },
        );
      } else {
        // Добавляем в избранное
        final favoriteItem = FavoriteItemEntity(
          product: product,
          addedAt: DateTime.now(),
        );
        
        final result = await favoriteRepository.addToFavorites(favoriteItem);
        
        result.fold(
          (error) {
            emit(state.copyWith(
              isLoadingFavorite: false,
              errorMessage: error,
            ));
          },
          (_) async {
            // Синхронизируем с сервером
            try {
              await ApiClient.addToFavorites(product.id);
            } catch (e) {
              // Сервер недоступен, но локально уже добавили
            }
            
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
        errorMessage: 'Ошибка при обновлении избранного',
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
      
      final quantity = event.quantity;
      
      // Работаем с локальной корзиной
      if (quantity == 0) {
        // Удаляем из корзины
        final result = await cartRepository.removeFromCart(product.id);
        
        result.fold(
          (error) {
            emit(state.copyWith(
              isLoadingCart: false,
              errorMessage: error,
            ));
          },
          (_) async {
            // Синхронизируем с сервером
            try {
              await ApiClient.removeFromCart(product.id);
            } catch (e) {
              // Сервер недоступен, но локально уже удалили
            }
            
            emit(state.copyWith(
              quantity: quantity,
              isLoadingCart: false,
            ));
          },
        );
      } else {
        // Сначала получаем текущую корзину
        final cartResult = await cartRepository.getCartItems();
        
        cartResult.fold(
          (error) {
            emit(state.copyWith(
              isLoadingCart: false,
              errorMessage: error,
            ));
          },
          (cartItems) async {
            final cartItem = CartItemEntity(
              product: product,
              quantity: quantity,
              addedAt: DateTime.now(),
            );
            
            try {
              // Проверяем, есть ли уже товар в корзине
              final existingItem = cartItems.firstWhere(
                (item) => item.product.id == product.id,
                orElse: () => cartItem,
              );
              
              Either<String, CartItemEntity> operationResult;
              
              if (existingItem.id != null) {
                // Обновляем существующий
                operationResult = await cartRepository.updateCartItem(
                  cartItem.copyWith(id: existingItem.id),
                );
              } else {
                // Добавляем новый
                operationResult = await cartRepository.addToCart(cartItem);
              }
              
              operationResult.fold(
                (error) {
                  emit(state.copyWith(
                    isLoadingCart: false,
                    errorMessage: error,
                  ));
                },
                (_) async {
                  // Синхронизируем с сервером
                  try {
                    await ApiClient.addToCart(product.id, quantity);
                  } catch (e) {
                    // Сервер недоступен, но локально уже обновили
                  }
                  
                  emit(state.copyWith(
                    quantity: quantity,
                    isLoadingCart: false,
                  ));
                },
              );
            } catch (e) {
              emit(state.copyWith(
                isLoadingCart: false,
                errorMessage: 'Ошибка при поиске товара в корзине',
              ));
            }
          },
        );
      }
    } catch (e) {
      emit(state.copyWith(
        isLoadingCart: false,
        errorMessage: 'Ошибка при обновлении корзины',
      ));
    }
  }
}