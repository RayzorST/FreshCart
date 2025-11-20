// order_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';
import 'package:client/core/widgets/app_snackbar.dart';

class OrderManagement extends ConsumerStatefulWidget {
  const OrderManagement({super.key});

  @override
  ConsumerState<OrderManagement> createState() => _OrderManagementState();
}

class _OrderManagementState extends ConsumerState<OrderManagement> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ApiClient.getAdminOrders(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      await ApiClient.updateOrderStatus(orderId, newStatus);
      _loadOrders();
      AppSnackbar.showInfo(context: context, message: 'Статус заказа обновлен на $newStatus');
    } catch (e) {
      AppSnackbar.showError(context: context, message: 'Ошибка обновления');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Управление заказами',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _selectedStatus,
                items: [
                  DropdownMenuItem(value: 'all', child: Text('Все заказы')),
                  DropdownMenuItem(value: 'pending', child: Text('Ожидание')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Подтвержденные')),
                  DropdownMenuItem(value: 'delivered', child: Text('Доставленные')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Отмененные')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                    _isLoading = true;
                  });
                  _loadOrders();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(child: Text('Заказы не найдены'))
                    : ListView.builder(
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return OrderCard(
                            order: order,
                            onStatusChange: (newStatus) => _updateOrderStatus(order['id'], newStatus),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String) onStatusChange;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order['status']);
    final statusText = _getStatusText(order['status']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Пользователь: ${order['user']?['email'] ?? 'Неизвестно'}'),
            Text('Адрес: ${order['shipping_address']}'),
            Text('Сумма: ${order['total_amount']} ₽'),
            Text('Дата: ${DateTime.parse(order['created_at']).toString().substring(0, 16)}'),
            const SizedBox(height: 8),
            ...order['items'].map<Widget>((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${item['product']?['name']} - ${item['quantity']} шт. x ${item['price']} ₽'),
            )).toList(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Изменить статус:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: order['status'],
                  items: [
                    DropdownMenuItem(value: 'pending', child: Text('Ожидание')),
                    DropdownMenuItem(value: 'confirmed', child: Text('Подтвердить')),
                    DropdownMenuItem(value: 'delivered', child: Text('Доставлено')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Отменить')),
                  ],
                  onChanged: (value) => onStatusChange(value!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Ожидание';
      case 'confirmed': return 'Подтвержден';
      case 'delivered': return 'Доставлен';
      case 'cancelled': return 'Отменен';
      default: return status;
    }
  }
}