import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/features/profile/bloc/order_history_bloc.dart';
import 'package:client/domain/entities/order_entity.dart';
import 'package:client/core/di/di.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<OrderHistoryBloc>();
        bloc.add(const LoadOrders());
        return bloc;
      },
      child: const _OrderHistoryScreen(),
    );
  }
}

class _OrderHistoryScreen extends StatelessWidget {
  const _OrderHistoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Мои заказы',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: _OrderHistoryContent(),
    );
  }
}

class _OrderHistoryContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
      builder: (context, state) {
        if (state.status == OrderHistoryStatus.initial ||
            state.status == OrderHistoryStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == OrderHistoryStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Ошибка загрузки', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<OrderHistoryBloc>().add(const LoadOrders()),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        if (state.orders.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...state.orders.map((order) => _OrderCard(order: order)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
          const Text(
            'Нет заказов',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут отображаться ваши заказы',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderEntity order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

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
      case 'processing':
        return 'В обработке';
      case 'shipped':
        return 'Отправлен';
      case 'completed':
        return 'Завершен';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'confirmed':
      case 'shipped':
        return Colors.blue;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";

    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'мая',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getItemsPreview(List<OrderItemEntity> items) {
    if (items.isEmpty) return 'Нет товаров';

    final itemNames = items.take(3).map((item) {
      return item.product.name;
    }).toList();

    final preview = itemNames.join(', ');
    if (items.length > 3) {
      return '$preview и ещё ${items.length - 3}';
    }
    return preview;
  }

  Widget _buildStatusIndicator(String status) {
    final List<StatusStep> steps;

    if (status == 'cancelled') {
      steps = [
        StatusStep(icon: Icons.shopping_cart, isActive: true),
        StatusStep(icon: Icons.close, isActive: true, isCancelled: true),
      ];
    } else if (status == 'pending' || status == 'processing') {
      steps = [
        StatusStep(icon: Icons.shopping_cart, isActive: true),
        StatusStep(icon: Icons.local_shipping, isActive: false),
        StatusStep(icon: Icons.check_circle, isActive: false),
      ];
    } else if (status == 'confirmed' || status == 'shipped') {
      steps = [
        StatusStep(icon: Icons.shopping_cart, isActive: true),
        StatusStep(icon: Icons.local_shipping, isActive: true),
        StatusStep(icon: Icons.check_circle, isActive: false),
      ];
    } else {
      steps = [
        StatusStep(icon: Icons.shopping_cart, isActive: true),
        StatusStep(icon: Icons.local_shipping, isActive: true),
        StatusStep(icon: Icons.check_circle, isActive: true),
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
    return SizedBox(
      width: 32,
      child: Column(
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
      ),
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

  Widget _buildOrderItem(OrderItemEntity item) {
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
            child: item.product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.shopping_bag,
                          color: Colors.grey[400],
                          size: 20,
                        );
                      },
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
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${item.quantity} × ${item.price.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(item.quantity * item.price).toStringAsFixed(0)} ₽',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomSheet(BuildContext context) {
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
            'Заказ #${widget.order.id}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Статус', _getStatusText(widget.order.status)),
          _buildDetailRow('Дата заказа', _formatDate(widget.order.createdAt)),
          if (widget.order.updatedAt != null)
            _buildDetailRow('Дата обновления', _formatDate(widget.order.updatedAt)),
          _buildDetailRow('Адрес доставки', widget.order.shippingAddress),
          if (widget.order.notes != null && widget.order.notes!.isNotEmpty)
            _buildDetailRow('Примечание', widget.order.notes!),
          const SizedBox(height: 16),
          const Text(
            'Состав заказа:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.order.items.map((item) => _buildOrderItem(item)).toList(),
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
                  '${widget.order.totalAmount.toStringAsFixed(0)} ₽',
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
  }

  Widget _buildDesktopExpandedContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Статус', _getStatusText(widget.order.status)),
          _buildDetailRow('Дата заказа', _formatDate(widget.order.createdAt)),
          if (widget.order.updatedAt != null)
            _buildDetailRow('Дата обновления', _formatDate(widget.order.updatedAt)),
          _buildDetailRow('Адрес доставки', widget.order.shippingAddress),
          if (widget.order.notes != null && widget.order.notes!.isNotEmpty)
            _buildDetailRow('Примечание', widget.order.notes!),
          const SizedBox(height: 16),
          const Text(
            'Состав заказа:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.order.items.map((item) => _buildOrderItem(item)).toList(),
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
                  '${widget.order.totalAmount.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDetailsPressed(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    if (isWideScreen) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _buildMobileBottomSheet(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.order.status);
    final statusText = _getStatusText(widget.order.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Заказ #${widget.order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatusIndicator(widget.order.status),
                const SizedBox(height: 12),
                Text(
                  _formatDate(widget.order.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getItemsPreview(widget.order.items),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.order.totalAmount.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onDetailsPressed(context),
                      child: Text(
                        _isExpanded ? 'Скрыть' : 'Подробнее',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isExpanded) _buildDesktopExpandedContent(),
        ],
      ),
    );
  }
}

class StatusStep {
  final IconData icon;
  final bool isActive;
  final bool isCancelled;

  StatusStep({
    required this.icon,
    required this.isActive,
    this.isCancelled = false,
  });
}