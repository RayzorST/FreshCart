import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/repositories/product_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'main_event.dart';
part 'main_state.dart';

@injectable
class MainBloc extends Bloc<MainEvent, MainState> {
  final ProductRepository _productRepository;

  MainBloc(this._productRepository) : super(const MainState.initial()) {
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
        //promotions: promotions,
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
      // Используем API напрямую для первоначальной загрузки
      final products = await ApiClient.getProducts(
        categoryId: state.selectedCategoryId == '0' ? null : int.tryParse(state.selectedCategoryId),
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      
      // Конвертируем Map в ProductEntity
      final productEntities = products
          .map((json) => ProductEntity.fromJson(json))
          .toList();
      
      // Кэшируем через репозиторий
      await _productRepository.cacheProducts(productEntities);
      
      emit(state.copyWith(
        productsStatus: MainStatus.loaded,
        products: productEntities,
        hasMoreProducts: productEntities.length >= 20,
      ));
    } catch (e) {
      // Если API недоступен, используем репозиторий
      final result = await _productRepository.getAllProducts();
      
      result.fold(
        (error) {
          emit(state.copyWith(
            productsStatus: MainStatus.error,
            productsError: 'Ошибка загрузки товаров: $e',
          ));
        },
        (cachedProducts) {
          // Фильтруем кэшированные продукты
          List<ProductEntity> filteredProducts = cachedProducts;
          
          if (state.selectedCategoryId != '0') {
            filteredProducts = filteredProducts.where(
              (product) => product.category == state.selectedCategoryId,
            ).toList();
          }
          
          if (state.searchQuery.isNotEmpty) {
            filteredProducts = filteredProducts.where(
              (product) => product.name.toLowerCase().contains(
                state.searchQuery.toLowerCase(),
              ),
            ).toList();
          }
          
          emit(state.copyWith(
            productsStatus: MainStatus.loaded,
            products: filteredProducts,
            hasMoreProducts: false,
          ));
        },
      );
    }
  }

  Future<void> _onMoreProductsLoaded(
    MoreProductsLoaded event,
    Emitter<MainState> emit,
  ) async {
    if (!state.hasMoreProducts || state.productsStatus == MainStatus.loadingMore) return;

    emit(state.copyWith(productsStatus: MainStatus.loadingMore));
    
    try {
      final moreProducts = await ApiClient.searchProducts(
        categoryId: state.selectedCategoryId == '0' ? null : int.tryParse(state.selectedCategoryId),
        name: state.searchQuery.isEmpty ? null : state.searchQuery,
        offset: state.products.length,
      );
      
      final newProducts = moreProducts
          .map((json) => ProductEntity.fromJson(json))
          .toList();
      
      await _productRepository.cacheProducts(newProducts);
      
      emit(state.copyWith(
        productsStatus: MainStatus.loaded,
        products: [...state.products, ...newProducts],
        hasMoreProducts: newProducts.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        productsStatus: MainStatus.error,
        productsError: 'Ошибка загрузки дополнительных товаров: $e',
      ));
    }
  }
}