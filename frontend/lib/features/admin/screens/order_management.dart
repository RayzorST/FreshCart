// order_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/admin/bloc/order_management_bloc.dart';
import 'package:client/data/repositories/order_management_repository_impl.dart';
import 'package:client/domain/entities/order_entity.dart';

class OrderManagement extends StatelessWidget {
  const OrderManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderManagementBloc(
        repository: OrderManagementRepositoryImpl(),
      )..add(const LoadOrders(status: 'all')),
      child: const _OrderManagementView(),
    );
  }
}

class _OrderManagementView extends StatelessWidget {
  const _OrderManagementView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<OrderManagementBloc, OrderManagementState>(
      builder: (context, state) {
        final selectedStatus = state is OrderManagementLoaded 
            ? state.selectedStatus 
            : 'all';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Управление заказами',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButton<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Все заказы')),
                DropdownMenuItem(value: 'pending', child: Text('Ожидание')),
                DropdownMenuItem(value: 'confirmed', child: Text('Подтвержденные')),
                DropdownMenuItem(value: 'delivered', child: Text('Доставленные')),
                DropdownMenuItem(value: 'cancelled', child: Text('Отмененные')),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<OrderManagementBloc>().add(ChangeStatusFilter(value));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    return BlocConsumer<OrderManagementBloc, OrderManagementState>(
      listener: (context, state) {
        if (state is OrderManagementError) {
          AppSnackbar.showError(context: context, message: state.message);
        }
      },
      builder: (context, state) {
        if (state is OrderManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is OrderManagementError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<OrderManagementBloc>().add(const LoadOrders(status: 'all'));
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        } else if (state is OrderManagementLoaded) {
          return _buildOrdersList(context, state.filteredOrders);
        } else {
          return const Center(child: Text('Загрузка...'));
        }
      },
    );
  }

  Widget _buildOrdersList(BuildContext context, List<OrderEntity> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('Заказы не найдены'));
    }

    return Expanded(
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            onStatusChange: (newStatus) => _updateOrderStatus(context, order.id, newStatus),
          );
        },
      ),
    );
  }

  void _updateOrderStatus(BuildContext context, int orderId, String newStatus) async {
    try {
      context.read<OrderManagementBloc>().add(
        UpdateOrderStatus(orderId: orderId, newStatus: newStatus),
      );
      AppSnackbar.showInfo(context: context, message: 'Статус заказа обновлен на $newStatus');
    } catch (e) {
      AppSnackbar.showError(context: context, message: 'Ошибка обновления');
    }
  }
}

class OrderCard extends StatelessWidget {
  final OrderEntity order;
  final Function(String) onStatusChange;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);

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
                  'Заказ #${order.id}',
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
            Text('Пользователь ID: ${order.userId}'),
            Text('Адрес: ${order.shippingAddress}'),
            Text('Сумма: ${order.totalAmount} ₽'),
            Text('Дата: ${order.createdAt.toString().substring(0, 16)}'),
            const SizedBox(height: 8),
            ...order.items.map<Widget>((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${item.product.name} - ${item.quantity} шт. x ${item.price} ₽'),
            )).toList(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Изменить статус:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: order.status,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Ожидание')),
                    DropdownMenuItem(value: 'confirmed', child: Text('Подтвердить')),
                    DropdownMenuItem(value: 'delivered', child: Text('Доставлено')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Отменить')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onStatusChange(value);
                    }
                  },
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