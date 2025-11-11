import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/core/providers/promotions_provider.dart';

class PromotionsSection extends ConsumerWidget {
  const PromotionsSection({super.key});

  String _getPromotionsCountText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '$count акция';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return '$count акции';
    } else {
      return '$count акций';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(promotionsListProvider);

    return Column(
      children: [
        _buildPromotionsHeader(promotionsAsync, context),
        _buildPromotionsContent(promotionsAsync, context),
      ],
    );
  }

  Widget _buildPromotionsHeader(AsyncValue<List<dynamic>> promotionsAsync, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Акции',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          promotionsAsync.when(
            loading: () => const Text('... акций'),
            error: (error, stack) => const Text('0 акций'),
            data: (promotions) => Text(
              _getPromotionsCountText(promotions.length),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsContent(AsyncValue<List<dynamic>> promotionsAsync, BuildContext context) {
    return SizedBox(
      height: 95,
      child: promotionsAsync.when(
        loading: () => _buildPromotionsLoading(),
        error: (error, stack) => _buildPromotionsError(error, context),
        data: (promotions) => _buildPromotionsList(promotions, context),
      ),
    );
  }

  Widget _buildPromotionsLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildPromotionsError(Object error, BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Container(
          width: 200,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 24),
                const SizedBox(height: 8),
                Text(
                  'Ошибка загрузки',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[700],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionsList(List<dynamic> promotions, BuildContext context) {
    if (promotions.isEmpty) {
      return ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Нет активных акций',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
      itemCount: promotions.length,
      itemBuilder: (context, index) {
        final promotion = promotions[index];
        return _buildPromotionCard(promotion, context);
      },
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion, BuildContext context) {
    Color getPromotionColor(String promotionType) {
      switch (promotionType) {
        case 'percentage':
          return Colors.green;
        case 'fixed':
          return Colors.blue;
        case 'gift':
          return Colors.orange;
        default:
          return Colors.purple;
      }
    }

    String getPromotionDescription() {
      final type = promotion['promotion_type'];
      final value = promotion['value'];
      
      switch (type) {
        case 'percentage':
          return 'Скидка $value%';
        case 'fixed':
          final amount = (value / 100).toStringAsFixed(2);
          return 'Скидка $amount ₽';
        case 'gift':
          return 'Подарок';
        default:
          return promotion['name'];
      }
    }

    final color = getPromotionColor(promotion['promotion_type']);
    final description = getPromotionDescription();

    return GestureDetector(
      onTap: () {
        context.push('/promotion/${promotion['id']}', extra: promotion);
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Icon(
                Icons.local_offer_outlined,
                size: 80,
                color: color.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    promotion['name'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color.withOpacity(0.8),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}