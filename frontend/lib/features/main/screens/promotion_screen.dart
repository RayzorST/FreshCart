// features/promotions/screens/promotion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromotionScreen extends ConsumerWidget {
  final Map<String, dynamic> promotion;
  
  const PromotionScreen({super.key, required this.promotion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(promotion['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок акции
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.blue.withOpacity(0.1),
                ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion['name'],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (promotion['description'] != null)
                    Text(
                      promotion['description'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Детали акции
            Text(
              'Детали акции',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailItem('Тип акции', _getPromotionTypeText(promotion['promotion_type'])),
            _buildDetailItem('Размер скидки', _getPromotionValueText(promotion)),
            _buildDetailItem('Минимальная сумма заказа', '${(promotion['min_order_amount'] / 100).toStringAsFixed(2)} ₽'),
            _buildDetailItem('Действует до', _formatDate(promotion['end_date'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _getPromotionTypeText(String type) {
    switch (type) {
      case 'percentage': return 'Процентная скидка';
      case 'fixed': return 'Фиксированная скидка';
      case 'gift': return 'Подарок';
      default: return type;
    }
  }

  String _getPromotionValueText(Map<String, dynamic> promotion) {
    switch (promotion['promotion_type']) {
      case 'percentage':
        return '${promotion['value']}%';
      case 'fixed':
        return '${(promotion['value'] / 100).toStringAsFixed(2)} ₽';
      case 'gift':
        return 'Подарочный товар';
      default:
        return '${promotion['value']}';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}