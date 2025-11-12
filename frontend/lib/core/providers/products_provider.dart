import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final isCategoriesExpandedProvider = StateProvider<bool>((ref) => false);

final productsPageProvider = StateProvider<int>((ref) => 1);
final hasMoreProductsProvider = StateProvider<bool>((ref) => true);
final productsLoadingMoreProvider = StateProvider<bool>((ref) => false);

// Провайдер для SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

class ProductsState {
  final List<dynamic> products;
  final bool isLoading;
  final String? error;

  ProductsState({
    required this.products,
    required this.isLoading,
    this.error,
  });

  ProductsState copyWith({
    List<dynamic>? products,
    bool? isLoading,
    String? error,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final Ref ref;
  
  ProductsNotifier(this.ref) : super(ProductsState(products: [], isLoading: true)) {
    loadInitial();
  }
  
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final products = await _fetchProducts(page: 1);
      state = state.copyWith(
        products: products,
        isLoading: false,
      );
      ref.read(productsPageProvider.notifier).state = 1;
      ref.read(hasMoreProductsProvider.notifier).state = products.length == 100;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> loadMore() async {
    print('🔄 loadMore called - isLoadingMore: ${ref.read(productsLoadingMoreProvider)}, hasMore: ${ref.read(hasMoreProductsProvider)}');
    if (ref.read(productsLoadingMoreProvider)){
      print('❌ Already loading more, skipping');
      return;
    }
    if (!ref.read(hasMoreProductsProvider)) {
      print('❌ No more products, skipping');
      return;
    }
    if (state.isLoading) {
      print('❌ Still loading initial, skipping');
      return;
    }
    
    ref.read(productsLoadingMoreProvider.notifier).state = true;
    print('✅ Starting to load more products...');
    
    try {
      final nextPage = ref.read(productsPageProvider) + 1;
      print('📄 Loading page: $nextPage');
      final newProducts = await _fetchProducts(page: nextPage);
      print('📦 Loaded ${newProducts.length} new products');
      
      if (newProducts.isEmpty) {
        print('🏁 No more products available');
        ref.read(hasMoreProductsProvider.notifier).state = false;
      } else {
        final allProducts = [...state.products, ...newProducts];
        state = state.copyWith(products: allProducts);
        ref.read(productsPageProvider.notifier).state = nextPage;
        ref.read(hasMoreProductsProvider.notifier).state = newProducts.length == 100;
      }
    } catch (e) {
      print('Error loading more products: $e');
    } finally {
      ref.read(productsLoadingMoreProvider.notifier).state = false;
      print('🔄 loadMore finished');
    }
  }
  
  Future<List<dynamic>> _fetchProducts({required int page}) async {
    final selectedCategory = ref.read(selectedCategoryProvider);
    final searchQuery = ref.read(searchQueryProvider);
    
    int? categoryId;
    if (selectedCategory != '0' && selectedCategory != 'Все') {
      categoryId = int.tryParse(selectedCategory);
    }
    
    final limit = 100; // Твой временный лимит
    final offset = (page - 1) * limit;
    
    return await ApiClient.searchProducts(
      name: searchQuery.isNotEmpty ? searchQuery : null,
      categoryId: categoryId,
      limit: limit,
      offset: offset,
    );
  }
  
  void refresh() {
    ref.read(productsPageProvider.notifier).state = 1;
    ref.read(hasMoreProductsProvider.notifier).state = true;
    loadInitial();
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier(ref);
});

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiClient.getCategories();
});

final selectedCategoryProvider = StateProvider<String>((ref) => '0');