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
  final List<dynamic> orders;
  final String selectedStatus;

  const OrderManagementLoaded({
    required this.orders,
    required this.selectedStatus,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is OrderManagementLoaded &&
      listEquals(other.orders, orders) &&
      other.selectedStatus == selectedStatus;
  }

  @override
  int get hashCode => orders.hashCode ^ selectedStatus.hashCode;
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