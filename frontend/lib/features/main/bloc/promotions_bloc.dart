import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';
import 'package:equatable/equatable.dart';

part 'promotions_event.dart';
part 'promotions_state.dart';

class PromotionsBloc extends Bloc<PromotionsEvent, PromotionsState> {
  PromotionsBloc() : super(const PromotionsState.initial()) {
    on<PromotionLoaded>(_onPromotionLoaded);
    on<PromotionsListLoaded>(_onPromotionsListLoaded);
    on<PromotionRefreshed>(_onPromotionRefreshed);
  }

  Future<void> _onPromotionLoaded(
    PromotionLoaded event,
    Emitter<PromotionsState> emit,
  ) async {
    if (event.promotionId == null) {
      emit(state.copyWith(
        status: PromotionsStatus.error,
        error: 'Неверный ID акции',
      ));
      return;
    }

    emit(state.copyWith(status: PromotionsStatus.loading));
    
    try {
      final promotion = await ApiClient.getPromotion(event.promotionId!);
      emit(state.copyWith(
        status: PromotionsStatus.loaded,
        currentPromotion: promotion,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PromotionsStatus.error,
        error: 'Ошибка загрузки акции: $e',
      ));
    }
  }

  Future<void> _onPromotionsListLoaded(
    PromotionsListLoaded event,
    Emitter<PromotionsState> emit,
  ) async {
    emit(state.copyWith(status: PromotionsStatus.loading));
    
    try {
      final promotions = await ApiClient.getPromotions();
      emit(state.copyWith(
        status: PromotionsStatus.loaded,
        promotionsList: promotions,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PromotionsStatus.error,
        error: 'Ошибка загрузки списка акций: $e',
      ));
    }
  }

  Future<void> _onPromotionRefreshed(
    PromotionRefreshed event,
    Emitter<PromotionsState> emit,
  ) async {
    if (event.promotionId == null) return;

    try {
      final promotion = await ApiClient.getPromotion(event.promotionId!);
      emit(state.copyWith(
        currentPromotion: promotion,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Ошибка обновления акции: $e',
      ));
    }
  }
}