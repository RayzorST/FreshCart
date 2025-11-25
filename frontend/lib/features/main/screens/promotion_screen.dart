import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/features/main/bloc/promotions_bloc.dart';

class PromotionScreen extends StatefulWidget {
  final int? promotionId;
  
  const PromotionScreen({super.key, required this.promotionId});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromotionsBloc>().add(PromotionLoaded(widget.promotionId));
    });
  }

  void _refreshPromotion() {
    context.read<PromotionsBloc>().add(PromotionRefreshed(widget.promotionId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Детали акции',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPromotion,
          ),
        ],
      ),
      body: BlocConsumer<PromotionsBloc, PromotionsState>(
        listener: (context, state) {
          // Можно добавить обработку ошибок через SnackBar если нужно
        },
        builder: (context, state) {
          if (state.status == PromotionsStatus.initial || 
              state.status == PromotionsStatus.loading) {
            return _buildLoadingScreen();
          }

          if (state.status == PromotionsStatus.error) {
            return _buildErrorScreen(context, state.error ?? 'Ошибка загрузки акции');
          }

          if (state.currentPromotion == null) {
            return _buildErrorScreen(context, 'Акция не найдена');
          }

          return _buildPromotionContent(context, state.currentPromotion!);
        },
      ),
    );
  }

  Widget _buildPromotionContent(BuildContext context, Map<String, dynamic> promotion) {
    final promotionType = promotion['promotion_type'];
    final isPercentage = promotionType == 'percentage';
    final isFixed = promotionType == 'fixed';
    final isGift = promotionType == 'gift';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточка акции
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _getGradient(promotionType),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Бейдж типа акции
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getPromotionTypeText(promotionType),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Название акции
                Text(
                  promotion['name'] ?? 'Акция',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Описание
                if (promotion['description'] != null)
                  Text(
                    promotion['description'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Значение акции
                if (isPercentage || isFixed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPercentage 
                          ? 'СКИДКА ${promotion['value']}%'
                          : 'СКИДКА ${(promotion['value'] / 100).toStringAsFixed(0)} ₽',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getPrimaryColor(promotionType),
                      ),
                    ),
                  ),
                
                if (isGift && promotion['gift_product_id'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ПОДАРОК ПРИ ПОКУПКЕ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getPrimaryColor(promotionType),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Детали акции
          Text(
            'Условия акции',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (promotion['min_order_amount'] != 0) ...[
                  _buildDetailItem(
                    Icons.shopping_cart,
                    'Минимальная сумма заказа',
                    '${(promotion['min_order_amount'] / 100).toStringAsFixed(2)} ₽',
                  ),
                  const Divider(),
                ],
                if (promotion['min_quantity'] != 0) ...[
                  _buildDetailItem(
                    Icons.filter_alt,
                    'Минимальное количество',
                    '${promotion['min_quantity']} шт.',
                  ),
                  const Divider(),
                ],
                _buildDetailItem(
                  Icons.calendar_today,
                  'Действует до',
                  _formatDate(promotion['end_date']),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Статус акции
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(promotion['is_active'] ?? true).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(promotion['is_active'] ?? true).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  promotion['is_active'] ?? true ? Icons.check_circle : Icons.pause_circle,
                  color: _getStatusColor(promotion['is_active'] ?? true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    promotion['is_active'] ?? true 
                        ? 'Акция активна и применяется автоматически'
                        : 'Акция временно неактивна',
                    style: TextStyle(
                      color: _getStatusColor(promotion['is_active'] ?? true),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Как использовать
          Text(
            'Как использовать',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionStep(context, '1', 'Добавьте товары в корзину'),
                _buildInstructionStep(context, '2', 'Скидка применится автоматически'),
                _buildInstructionStep(context, '3', 'Оформите заказ и получите выгоду'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка акции...'),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshPromotion,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPrimaryColor(String promotionType) {
    switch (promotionType) {
      case 'percentage':
        return Colors.green;
      case 'fixed':
        return Colors.blue;
      case 'gift':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Color _getStatusColor(bool isActive) {
    return isActive ? Colors.green : Colors.orange;
  }

  LinearGradient _getGradient(String promotionType) {
    switch (promotionType) {
      case 'percentage':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C853), Color(0xFF00E676)],
        );
      case 'fixed':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
        );
      case 'gift':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF757575), Color(0xFF9E9E9E)],
        );
    }
  }

  String _getPromotionTypeText(String type) {
    switch (type) {
      case 'percentage': return 'Процентная скидка';
      case 'fixed': return 'Фиксированная скидка';
      case 'gift': return 'Подарок';
      default: return type;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}