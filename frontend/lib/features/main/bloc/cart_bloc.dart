import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:client/domain/repositories/cart_repository.dart';
import 'package:dartz/dartz.dart';

part 'cart_event.dart';
part 'cart_state.dart';

@injectable
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository;
  StreamSubscription? _subscription;

  CartBloc(this._cartRepository) : super(const CartState.initial()) {
    on<CartLoaded>(_onCartLoaded);
    on<CartItemUpdated>(_onCartItemUpdated);
    on<CartItemRemoved>(_onCartItemRemoved);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Future<void> _onCartLoaded(
    CartLoaded event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.loading));
    
    try {
      final result = await _cartRepository.getCartItems();
      
      result.fold(
        (error) {
          emit(state.copyWith(
            status: CartStatus.error,
            error: error,
          ));
        },
        (cartItems) {
          final total = cartItems.fold<double>(
            0, (sum, item) => sum + item.totalPrice
          );
          
          final originalTotal = cartItems.fold<double>(
            0, (sum, item) => sum + (item.product.price * item.quantity)
          );
          
          emit(state.copyWith(
            status: CartStatus.loaded,
            cartItems: cartItems,
            totalAmount: total,
            originalTotalAmount: originalTotal,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: 'Ошибка загрузки корзины: $e',
      ));
    }
  }

  Future<void> _onCartItemUpdated(
    CartItemUpdated event,
    Emitter<CartState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CartStatus.syncing));

      CartItemEntity? existingItem;
      for (final item in state.cartItems) {
        if (item.product.id == event.productId) {
          existingItem = item;
          break;
        }
      }
      
      // Выбираем метод на основе наличия товара
      final Either<String, CartItemEntity> result;
      
      if (existingItem == null) {
        result = await _cartRepository.addToCart(event.productId, event.quantity);
      } else {
        result = await _cartRepository.updateCartItem(event.productId, event.quantity);
      }
      
      result.fold(
        (error) {
          emit(state.copyWith(
            status: CartStatus.loaded,
            error: error,
          ));
        },
        (_) {
          add(const CartLoaded());
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: 'Ошибка обновления корзины: $e',
      ));
    }
  }

  Future<void> _onCartItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    try {
      final result = await _cartRepository.removeFromCart(event.productId);
      
      result.fold(
        (error) {
          emit(state.copyWith(error: error));
        },
        (_) {
          final updatedItems = state.cartItems
              .where((item) => item.product.id != event.productId)
              .toList();
          
          final total = updatedItems.fold<double>(
            0, (sum, item) => sum + item.totalPrice
          );
          
          final originalTotal = updatedItems.fold<double>(
            0, (sum, item) => sum + (item.product.price * item.quantity)
          );
          
          emit(state.copyWith(
            cartItems: updatedItems,
            totalAmount: total,
            originalTotalAmount: originalTotal,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(error: 'Ошибка удаления из корзины: $e'));
    }
  }
}