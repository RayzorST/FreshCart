part of 'order_history_bloc.dart';

enum OrderHistoryStatus {
  initial,
  loading,
  loaded,
  error,
}

class OrderHistoryState extends Equatable {
  final OrderHistoryStatus status;
  final List<OrderEntity> orders;
  final String? error;

  const OrderHistoryState({
    required this.status,
    required this.orders,
    this.error,
  });

  const OrderHistoryState.initial()
      : status = OrderHistoryStatus.initial,
        orders = const [],
        error = null;

  OrderHistoryState copyWith({
    OrderHistoryStatus? status,
    List<OrderEntity>? orders,
    String? error,
  }) {
    return OrderHistoryState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, orders, error];
}