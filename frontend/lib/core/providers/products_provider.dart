import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';

final productsProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiClient.getProducts();
});

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiClient.getCategories();
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'Все');