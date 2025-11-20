part of 'main_bloc.dart';

abstract class MainEvent extends Equatable {
  const MainEvent();

  @override
  List<Object> get props => [];
}

class MainTabChanged extends MainEvent {
  final int tabIndex;

  const MainTabChanged(this.tabIndex);

  @override
  List<Object> get props => [tabIndex];
}

class PromotionsLoaded extends MainEvent {
  const PromotionsLoaded();
}

class CategoriesLoaded extends MainEvent {
  const CategoriesLoaded();
}

class CategoriesExpandedToggled extends MainEvent {
  final bool isExpanded;

  const CategoriesExpandedToggled(this.isExpanded);

  @override
  List<Object> get props => [isExpanded];
}

class CategorySelected extends MainEvent {
  final String categoryId;

  const CategorySelected(this.categoryId);

  @override
  List<Object> get props => [categoryId];
}

class SearchQueryChanged extends MainEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

class ProductsLoaded extends MainEvent {
  const ProductsLoaded();
}

class MoreProductsLoaded extends MainEvent {
  const MoreProductsLoaded();
}