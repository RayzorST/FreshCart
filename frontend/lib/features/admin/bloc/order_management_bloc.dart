import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/api/client.dart';
import 'package:flutter/foundation.dart';

part 'order_management_event.dart';
part 'order_management_state.dart';

class OrderManagementBloc extends Bloc<OrderManagementEvent, OrderManagementState> {
  OrderManagementBloc() : super(const OrderManagementInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<ChangeStatusFilter>(_onChangeStatusFilter);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrderManagementState> emit,
  ) async {
    emit(const OrderManagementLoading());
    
    try {
      final orders = await ApiClient.getAdminOrders(
        status: event.status == 'all' ? null : event.status,
      );
      emit(OrderManagementLoaded(
        orders: orders,
        selectedStatus: event.status ?? 'all',
      ));
    } catch (e) {
      emit(OrderManagementError('Ошибка загрузки заказов: $e'));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<OrderManagementState> emit,
  ) async {
    if (state is! OrderManagementLoaded) return;

    final currentState = state as OrderManagementLoaded;
    
    try {
      await ApiClient.updateOrderStatus(event.orderId, event.newStatus);
      
      // Перезагружаем заказы после обновления статуса
      add(LoadOrders(status: currentState.selectedStatus));
    } catch (e) {
      // Можно добавить обработку ошибок через Snackbar или другое состояние
      rethrow;
    }
  }

  Future<void> _onChangeStatusFilter(
    ChangeStatusFilter event,
    Emitter<OrderManagementState> emit,
  ) async {
    add(LoadOrders(status: event.status));
  }
}