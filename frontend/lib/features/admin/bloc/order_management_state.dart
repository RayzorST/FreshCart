// order_management_state.dart
part of 'order_management_bloc.dart';

abstract class OrderManagementState {
  const OrderManagementState();
}

class OrderManagementInitial extends OrderManagementState {
  const OrderManagementInitial();
}

class OrderManagementLoading extends OrderManagementState {
  const OrderManagementLoading();
}

class OrderManagementLoaded extends OrderManagementState {
  final List<OrderEntity> orders;
  final String selectedStatus;

  const OrderManagementLoaded({
    required this.orders,
    required this.selectedStatus,
  });

  // Фильтрация заказов по статусу
  List<OrderEntity> get filteredOrders {
    if (selectedStatus == 'all') return orders;
    return orders.where((order) => order.status == selectedStatus).toList();
  }

  // Получение статистики
  Map<String, int> get statusCounts {
    final counts = <String, int>{};
    for (final order in orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    return counts;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is OrderManagementLoaded &&
      _listsEqual(other.orders, orders) &&
      other.selectedStatus == selectedStatus;
  }

  bool _listsEqual(List<OrderEntity> list1, List<OrderEntity> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(orders.length, selectedStatus);
}

class OrderManagementError extends OrderManagementState {
  final String message;

  const OrderManagementError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is OrderManagementError &&
      other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}