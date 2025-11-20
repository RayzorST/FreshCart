import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final Map<String, dynamic> product;

  ProductBloc(this.product) : super(const ProductState()) {
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
      final response = await ApiClient.checkFavorite(product['id']);
      emit(state.copyWith(
        isFavorite: response['is_favorite'] ?? false,
        isLoadingFavorite: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingFavorite: false));
    }
  }

  Future<void> _onLoadCartQuantity(
    ProductLoadCartQuantity event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final cartResponse = await ApiClient.getCart();
      final cartItems = cartResponse['items'] ?? [];
      
      final cartItem = cartItems.firstWhere(
        (item) => item['product_id'] == product['id'],
        orElse: () => null,
      );
      
      if (cartItem != null) {
        emit(state.copyWith(quantity: cartItem['quantity'] ?? 0));
      }
    } catch (e) {
      // Ignore error for cart loading
    }
  }

  Future<void> _onToggleFavorite(
    ProductToggleFavorite event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingFavorite: true));
      
      if (state.isFavorite) {
        await ApiClient.removeFromFavorites(product['id']);
        emit(state.copyWith(isFavorite: false, isLoadingFavorite: false));
      } else {
        await ApiClient.addToFavorites(product['id']);
        emit(state.copyWith(isFavorite: true, isLoadingFavorite: false));
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
    if (state.isLoadingCart) return;
    
    try {
      emit(state.copyWith(isLoadingCart: true));
      
      if (event.newQuantity == 0) {
        await ApiClient.removeFromCart(product['id']);
      } else if (state.quantity == 0) {
        await ApiClient.addToCart(product['id'], event.newQuantity);
      } else {
        await ApiClient.updateCartItem(product['id'], event.newQuantity);
      }
      
      emit(state.copyWith(quantity: event.newQuantity, isLoadingCart: false));
    } catch (e) {
      emit(state.copyWith(
        isLoadingCart: false,
        errorMessage: 'Ошибка при обновлении корзины',
      ));
    }
  }
}