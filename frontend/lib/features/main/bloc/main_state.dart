part of 'main_bloc.dart';

enum MainStatus {
  initial,
  loading,
  loaded,
  error,
  loadingMore,
}

class MainState extends Equatable {
  final int currentTabIndex;
  final MainStatus promotionsStatus;
  final List<Map<String, dynamic>> promotions;
  final String? promotionsError;
  final MainStatus categoriesStatus;
  final List<dynamic> categories;
  final String? categoriesError;
  final bool isCategoriesExpanded;
  final String selectedCategoryId;
  final String searchQuery;
  final MainStatus productsStatus;
  final List<ProductEntity> products; // Изменено на List<Product>
  final String? productsError;
  final bool hasMoreProducts;

  const MainState({
    required this.currentTabIndex,
    required this.promotionsStatus,
    required this.promotions,
    this.promotionsError,
    required this.categoriesStatus,
    required this.categories,
    this.categoriesError,
    required this.isCategoriesExpanded,
    required this.selectedCategoryId,
    required this.searchQuery,
    required this.productsStatus,
    required this.products,
    this.productsError,
    required this.hasMoreProducts,
  });

  const MainState.initial()
      : currentTabIndex = 0,
        promotionsStatus = MainStatus.initial,
        promotions = const [],
        promotionsError = null,
        categoriesStatus = MainStatus.initial,
        categories = const [],
        categoriesError = null,
        isCategoriesExpanded = false,
        selectedCategoryId = '0',
        searchQuery = '',
        productsStatus = MainStatus.initial,
        products = const [], // Пустой список Product
        productsError = null,
        hasMoreProducts = false;

  MainState copyWith({
    int? currentTabIndex,
    MainStatus? promotionsStatus,
    List<Map<String, dynamic>>? promotions,
    String? promotionsError,
    MainStatus? categoriesStatus,
    List<dynamic>? categories,
    String? categoriesError,
    bool? isCategoriesExpanded,
    String? selectedCategoryId,
    String? searchQuery,
    MainStatus? productsStatus,
    List<ProductEntity>? products, // Изменено на List<Product>
    String? productsError,
    bool? hasMoreProducts,
  }) {
    return MainState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      promotionsStatus: promotionsStatus ?? this.promotionsStatus,
      promotions: promotions ?? this.promotions,
      promotionsError: promotionsError ?? this.promotionsError,
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      categories: categories ?? this.categories,
      categoriesError: categoriesError ?? this.categoriesError,
      isCategoriesExpanded: isCategoriesExpanded ?? this.isCategoriesExpanded,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      productsStatus: productsStatus ?? this.productsStatus,
      products: products ?? this.products,
      productsError: productsError ?? this.productsError,
      hasMoreProducts: hasMoreProducts ?? this.hasMoreProducts,
    );
  }

  @override
  List<Object?> get props => [
        currentTabIndex,
        promotionsStatus,
        promotions,
        promotionsError,
        categoriesStatus,
        categories,
        categoriesError,
        isCategoriesExpanded,
        selectedCategoryId,
        searchQuery,
        productsStatus,
        products,
        productsError,
        hasMoreProducts,
      ];
}