import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:client/domain/repositories/cart_repository.dart';

part 'cart_event.dart';
part 'cart_state.dart';

@injectable
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository;

  CartBloc(this._cartRepository) : super(const CartState.initial()) {
    on<CartLoaded>(_onCartLoaded);
    on<CartItemAdded>(_onCartItemAdded);
    on<CartItemUpdated>(_onCartItemUpdated);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartSyncedWithServer>(_onCartSyncedWithServer);
  }

  Future<void> _onCartLoaded(
    CartLoaded event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.loading));
    
    final result = await _cartRepository.getCartItems();
    
    result.fold(
      (error) => emit(state.copyWith(status: CartStatus.error, error: error)),
      (items) {
        final total = _calculateTotal(items);
        final originalTotal = _calculateOriginalTotal(items);
        
        emit(state.copyWith(
          status: CartStatus.loaded,
          cartItems: items,
          totalAmount: total,
          originalTotalAmount: originalTotal,
        ));
      },
    );
  }

  Future<void> _onCartItemAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) async {
    final result = await _cartRepository.addToCart(event.item);
    
    result.fold(
      (error) => emit(state.copyWith(error: error)),
      (item) {
        // Проверяем, есть ли уже такой товар в корзине
        final existingIndex = state.cartItems.indexWhere(
          (cartItem) => cartItem.product.id == item.product.id
        );
        
        List<CartItemEntity> newItems;
        if (existingIndex >= 0) {
          // Обновляем существующий
          newItems = List<CartItemEntity>.from(state.cartItems);
          newItems[existingIndex] = item;
        } else {
          // Добавляем новый
          newItems = [...state.cartItems, item];
        }
        
        final total = _calculateTotal(newItems);
        final originalTotal = _calculateOriginalTotal(newItems);
        
        emit(state.copyWith(
          cartItems: newItems,
          totalAmount: total,
          originalTotalAmount: originalTotal,
        ));
      },
    );
  }

  Future<void> _onCartItemUpdated(
    CartItemUpdated event,
    Emitter<CartState> emit,
  ) async {
    final result = await _cartRepository.updateCartItem(event.item);
    
    result.fold(
      (error) => emit(state.copyWith(error: error)),
      (updatedItem) {
        final newItems = state.cartItems.map((item) {
          return item.product.id == updatedItem.product.id ? updatedItem : item;
        }).toList();
        
        final total = _calculateTotal(newItems);
        final originalTotal = _calculateOriginalTotal(newItems);
        
        emit(state.copyWith(
          cartItems: newItems,
          totalAmount: total,
          originalTotalAmount: originalTotal,
        ));
      },
    );
  }

  Future<void> _onCartItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    final result = await _cartRepository.removeFromCart(event.productId);
    
    result.fold(
      (error) => emit(state.copyWith(error: error)),
      (_) {
        final newItems = state.cartItems
            .where((item) => item.product.id != event.productId)
            .toList();
        
        final total = _calculateTotal(newItems);
        final originalTotal = _calculateOriginalTotal(newItems);
        
        emit(state.copyWith(
          cartItems: newItems,
          totalAmount: total,
          originalTotalAmount: originalTotal,
        ));
      },
    );
  }

  Future<void> _onCartSyncedWithServer(
    CartSyncedWithServer event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.syncing));
    
    final result = await _cartRepository.syncCartWithServer();
    
    result.fold(
      (error) => emit(state.copyWith(status: CartStatus.error, error: error)),
      (_) => add(const CartLoaded()),
    );
  }

  double _calculateTotal(List<CartItemEntity> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double _calculateOriginalTotal(List<CartItemEntity> items) {
    return items.fold(0.0, (sum, item) {
      final originalItemPrice = item.appliedPrice ?? item.product.price;
      return sum + (originalItemPrice * item.quantity);
    });
  }
}