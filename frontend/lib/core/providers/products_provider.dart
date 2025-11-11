import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final productsPageProvider = StateProvider<int>((ref) => 1);
final hasMoreProductsProvider = StateProvider<bool>((ref) => true);

final productsProvider = FutureProvider<List<dynamic>>((ref) async {
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final page = ref.watch(productsPageProvider);
  
  int? categoryId;
  if (selectedCategory != '0' && selectedCategory != 'Все') {
    categoryId = int.tryParse(selectedCategory);
  }
  
  final limit = 20; 
  final offset = (page - 1) * limit;
  
  final result = await ApiClient.searchProducts(
    name: searchQuery.isNotEmpty ? searchQuery : null,
    categoryId: categoryId,
    limit: limit,
    offset: offset,
  );
  
  if (result.length < limit) {
    ref.read(hasMoreProductsProvider.notifier).state = false;
  }
  
  return result;
});

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiClient.getCategories();
});

final selectedCategoryProvider = StateProvider<String>((ref) => '0');