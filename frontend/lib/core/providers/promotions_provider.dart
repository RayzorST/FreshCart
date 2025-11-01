import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';

final promotionProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, promotionId) async {
  try {
    final promotion = await ApiClient.getPromotion(promotionId);
    return promotion;
  } catch (e) {
    print('Error loading promotion: $e');
    throw e;
  }
});

final promotionsListProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final promotions = await ApiClient.getPromotions();
    return promotions;
  } catch (e) {
    print('Error loading promotions: $e');
    throw e;
  }
});