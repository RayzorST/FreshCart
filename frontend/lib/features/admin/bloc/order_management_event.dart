part of 'order_management_bloc.dart';

abstract class OrderManagementEvent {
  const OrderManagementEvent();
}

class LoadOrders extends OrderManagementEvent {
  final String? status;

  const LoadOrders({this.status});
}

class UpdateOrderStatus extends OrderManagementEvent {
  final int orderId;
  final String newStatus;

  const UpdateOrderStatus({
    required this.orderId,
    required this.newStatus,
  });
}

class ChangeStatusFilter extends OrderManagementEvent {
  final String status;

  const ChangeStatusFilter(this.status);
}