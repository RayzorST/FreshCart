import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';
import 'package:equatable/equatable.dart';

part 'main_event.dart';
part 'main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  MainBloc() : super(const MainState.initial()) {
    on<MainTabChanged>(_onTabChanged);
    on<PromotionsLoaded>(_onPromotionsLoaded);
    on<CategoriesLoaded>(_onCategoriesLoaded);
    on<CategoriesExpandedToggled>(_onCategoriesExpandedToggled);
    on<CategorySelected>(_onCategorySelected);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ProductsLoaded>(_onProductsLoaded);
    on<MoreProductsLoaded>(_onMoreProductsLoaded);
  }

  void _onTabChanged(
    MainTabChanged event,
    Emitter<MainState> emit,
  ) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  Future<void> _onPromotionsLoaded(
    PromotionsLoaded event,
    Emitter<MainState> emit,
  ) async {
    emit(state.copyWith(promotionsStatus: MainStatus.loading));
    
    try {
      final promotions = await ApiClient.getPromotions();
      emit(state.copyWith(
        promotionsStatus: MainStatus.loaded,
        promotions: promotions,
      ));
    } catch (e) {
      emit(state.copyWith(
        promotionsStatus: MainStatus.error,
        promotionsError: 'Ошибка загрузки акций: $e',
      ));
    }
  }

  Future<void> _onCategoriesLoaded(
    CategoriesLoaded event,
    Emitter<MainState> emit,
  ) async {
    emit(state.copyWith(categoriesStatus: MainStatus.loading));
    
    try {
      final categories = await ApiClient.getCategories();
      emit(state.copyWith(
        categoriesStatus: MainStatus.loaded,
        categories: categories,
      ));
    } catch (e) {
      emit(state.copyWith(
        categoriesStatus: MainStatus.error,
        categoriesError: 'Ошибка загрузки категорий: $e',
      ));
    }
  }

  void _onCategoriesExpandedToggled(
    CategoriesExpandedToggled event,
    Emitter<MainState> emit,
  ) {
    emit(state.copyWith(isCategoriesExpanded: event.isExpanded));
  }

  void _onCategorySelected(
    CategorySelected event,
    Emitter<MainState> emit,
  ) {
    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      searchQuery: '',
    ));
    add(const ProductsLoaded());
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<MainState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    add(const ProductsLoaded());
  }

  Future<void> _onProductsLoaded(
    ProductsLoaded event,
    Emitter<MainState> emit,
  ) async {
    emit(state.copyWith(productsStatus: MainStatus.loading));
    
    try {
      final products = await ApiClient.getProducts(
        categoryId: state.selectedCategoryId == '0' ? null : int.tryParse(state.selectedCategoryId),
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      
      emit(state.copyWith(
        productsStatus: MainStatus.loaded,
        products: products,
        hasMoreProducts: products.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        productsStatus: MainStatus.error,
        productsError: 'Ошибка загрузки товаров: $e',
      ));
    }
  }

  Future<void> _onMoreProductsLoaded(
    MoreProductsLoaded event,
    Emitter<MainState> emit,
  ) async {
    if (!state.hasMoreProducts || state.productsStatus == MainStatus.loadingMore) return;

    emit(state.copyWith(productsStatus: MainStatus.loadingMore));
    
    try {
      final currentProducts = state.products;
      final moreProducts = await ApiClient.searchProducts(
        categoryId: state.selectedCategoryId == '0' ? null : int.tryParse(state.selectedCategoryId),
        name: state.searchQuery.isEmpty ? null : state.searchQuery,
        offset: currentProducts.length,
      );
      
      emit(state.copyWith(
        productsStatus: MainStatus.loaded,
        products: [...currentProducts, ...moreProducts],
        hasMoreProducts: moreProducts.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        productsStatus: MainStatus.error,
        productsError: 'Ошибка загрузки дополнительных товаров: $e',
      ));
    }
  }
}