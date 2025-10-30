// core/providers/promotions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';

final promotionsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    // TODO: Добавить endpoint для получения акций в API клиент
    final response = await ApiClient.getPromotions();
    return response;
  } catch (e) {
    print('Error loading promotions: $e');
    throw e;
  }
});