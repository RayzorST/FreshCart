part of 'product_bloc.dart';

abstract class ProductEvent {}

class ProductLoadFavoriteStatus extends ProductEvent {}

class ProductLoadCartQuantity extends ProductEvent {}

class ProductToggleFavorite extends ProductEvent {}

class ProductUpdateCartQuantity extends ProductEvent {
  final int newQuantity;

  ProductUpdateCartQuantity(this.newQuantity);
}