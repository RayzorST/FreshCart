import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';
import 'package:client/core/widgets/bottom_navigation_bar.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  List<dynamic>? _orders;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ApiClient.getMyOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'В обработке';
      case 'confirmed':
        return 'Подтвержден';
      case 'delivered':
        return 'Доставлен';
      case 'cancelled':
        return 'Отменен';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getItemsPreview(List<dynamic> items) {
    if (items.isEmpty) return 'Нет товаров';
    
    final itemNames = items.take(3).map((item) {
      return item['product']?['name'] ?? 'Товар';
    }).toList();
    
    final preview = itemNames.join(', ');
    if (items.length > 3) {
      return '$preview и ещё ${items.length - 3}';
    }
    return preview;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Мои заказы',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold,),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders == null || _orders!.isEmpty
              ? _buildEmptyState()
              : _buildOrdersList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет заказов',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут отображаться ваши заказы',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(currentIndexProvider.notifier).state = 0,
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Сделать первый заказ'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._orders!.map((order) => _buildOrderCard(context, order)),
      ],
    );
  }

Widget _buildOrderCard(BuildContext context, dynamic order) {
  final status = order['status'] ?? 'pending';
  final items = order['items'] ?? [];

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Заказ #${order['id']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildStatusIndicator(status),
          const SizedBox(height: 12),
          
          Text(
            _formatDate(order['created_at']),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getItemsPreview(items),
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order['total_amount']?.toStringAsFixed(0) ?? '0'} ₽',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
              if (status != 'cancelled' && status != 'delivered')
                TextButton(
                  onPressed: () {
                    _showOrderDetails(order);
                  },
                  child: const Text('Подробнее'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStatusIndicator(String status) {
    final List<StatusStep> steps;
    
    if (status == 'cancelled') {
      steps = [
        StatusStep(icon: Icons.shopping_cart, label: 'Заказ создан', isActive: true),
        StatusStep(icon: Icons.close, label: 'Отменен', isActive: true, isCancelled: true),
      ];
    } else {
      steps = [
        StatusStep(icon: Icons.shopping_cart, label: 'Заказ создан', isActive: true),
        StatusStep(
          icon: Icons.local_shipping, 
          label: 'Подтвержден', 
          isActive: status == 'confirmed' || status == 'delivered'
        ),
        StatusStep(
          icon: Icons.check_circle, 
          label: 'Доставлен', 
          isActive: status == 'delivered'
        ),
      ];
    }

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _buildStatusStep(steps[i]),
              if (i < steps.length - 1) 
                Expanded(
                  child: Container(
                    height: 2,
                    color: steps[i].isActive && steps[i + 1].isActive 
                        ? Colors.green 
                        : Colors.grey[300],
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusStep(StatusStep step) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: step.isActive 
                ? (step.isCancelled ? Colors.red : Colors.green)
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            step.icon,
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    );
  }

  void _showOrderDetails(dynamic order) {
    final items = order['items'] ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.grey.withOpacity(0.2),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Детали заказа #${order['id']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Статус', _getStatusText(order['status'])),
              _buildDetailRow('Дата', _formatDate(order['created_at'])),
              _buildDetailRow('Адрес доставки', order['shipping_address'] ?? 'Не указан'),
              if (order['notes'] != null) 
                _buildDetailRow('Примечание', order['notes']!),
              
              const SizedBox(height: 16),
              const Text(
                'Состав заказа:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...items.map((item) => _buildOrderItem(item)).toList(),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Итого:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${order['total_amount']?.toStringAsFixed(0) ?? '0'} ₽',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: item['product']?['image_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '${ApiClient.baseUrl}/images/products/${item['product']['id']}/image',
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.shopping_bag,
                    color: Colors.grey[400],
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product']?['name'] ?? 'Товар',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${item['quantity']} × ${item['price']} ₽',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(item['quantity'] * item['price']).toStringAsFixed(0)} ₽',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusStep {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCancelled;

  StatusStep({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isCancelled = false,
  });
}