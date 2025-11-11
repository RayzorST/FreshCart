import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final productsProvider = FutureProvider<List<dynamic>>((ref) async {
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  
  int? categoryId;
  if (selectedCategory != '0' && selectedCategory != 'Все') {
    categoryId = int.tryParse(selectedCategory);
  }
  
  return await ApiClient.searchProducts(
    name: searchQuery.isNotEmpty ? searchQuery : null,
    categoryId: categoryId,
    limit: 100,
  );
});

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiClient.getCategories();
});

// Меняем тип на String для хранения ID категории
final selectedCategoryProvider = StateProvider<String>((ref) => '0');