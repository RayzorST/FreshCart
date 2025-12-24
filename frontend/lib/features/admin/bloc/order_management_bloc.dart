// order_management_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/domain/entities/order_entity.dart';
import 'package:client/domain/repositories/order_management_repository.dart';

part 'order_management_event.dart';
part 'order_management_state.dart';

class OrderManagementBloc extends Bloc<OrderManagementEvent, OrderManagementState> {
  final OrderManagementRepository repository;

  OrderManagementBloc({required this.repository}) : super(const OrderManagementInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<ChangeStatusFilter>(_onChangeStatusFilter);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrderManagementState> emit,
  ) async {
    emit(const OrderManagementLoading());
    
    final result = await repository.getOrders(status: event.status);
    
    result.fold(
      (error) => emit(OrderManagementError(error)),
      (orders) => emit(OrderManagementLoaded(
        orders: orders,
        selectedStatus: event.status ?? 'all',
      )),
    );
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<OrderManagementState> emit,
  ) async {
    if (state is! OrderManagementLoaded) return;

    final currentState = state as OrderManagementLoaded;
    
    final result = await repository.updateOrderStatus(event.orderId, event.newStatus);
    
    result.fold(
      (error) {
        // Можно отобразить ошибку, но оставить текущие данные
        emit(OrderManagementError(error));
        // Восстанавливаем предыдущее состояние
        emit(OrderManagementLoaded(
          orders: currentState.orders,
          selectedStatus: currentState.selectedStatus,
        ));
      },
      (_) {
        // Перезагружаем заказы после успешного обновления статуса
        add(LoadOrders(status: currentState.selectedStatus));
      },
    );
  }

  Future<void> _onChangeStatusFilter(
    ChangeStatusFilter event,
    Emitter<OrderManagementState> emit,
  ) async {
    add(LoadOrders(status: event.status));
  }
}