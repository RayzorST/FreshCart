import 'package:bloc/bloc.dart';
import 'package:client/domain/entities/order_entity.dart';
import 'package:client/domain/repositories/order_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'order_history_event.dart';
part 'order_history_state.dart';

@injectable
class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  final OrderRepository _orderRepository;

  OrderHistoryBloc(this._orderRepository) : super(const OrderHistoryState.initial()) {
    on<LoadOrders>(_onLoadOrders);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(state.copyWith(status: OrderHistoryStatus.loading));

    try {
      final result = await _orderRepository.getOrders();
      
      result.fold(
        (error) {
          emit(state.copyWith(
            status: OrderHistoryStatus.error,
            error: error,
          ));
        },
        (orders) {
          emit(state.copyWith(
            status: OrderHistoryStatus.loaded,
            orders: orders,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: OrderHistoryStatus.error,
        error: 'Ошибка загрузки заказов: $e',
      ));
    }
  }
}