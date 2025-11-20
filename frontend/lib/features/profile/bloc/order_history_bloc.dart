import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';
import 'package:equatable/equatable.dart';

part 'order_history_event.dart';
part 'order_history_state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  OrderHistoryBloc() : super(OrderHistoryInitial()) {
    on<LoadOrders>(_onLoadOrders);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(OrderHistoryLoading());
    try {
      final orders = await ApiClient.getMyOrders();
      emit(OrderHistoryLoaded(orders: orders));
    } catch (e) {
      emit(OrderHistoryError(message: e.toString()));
    }
  }
}