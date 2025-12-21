import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/entities/promotion_entity.dart';
import 'package:client/domain/repositories/promotion_repository.dart';

part 'promotions_event.dart';
part 'promotions_state.dart';

@injectable
class PromotionsBloc extends Bloc<PromotionsEvent, PromotionsState> {
  final PromotionRepository _promotionRepository;

  PromotionsBloc(this._promotionRepository) : super(const PromotionsState.initial()) {
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
      final result = await _promotionRepository.getPromotionById(event.promotionId!);
      
      result.fold(
        (error) {
          emit(state.copyWith(
            status: PromotionsStatus.error,
            error: error,
          ));
        },
        (promotion) {
          emit(state.copyWith(
            status: PromotionsStatus.loaded,
            currentPromotion: promotion,
          ));
        },
      );
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
      final result = await _promotionRepository.getPromotions();
      
      result.fold(
        (error) {
          emit(state.copyWith(
            status: PromotionsStatus.error,
            error: error,
          ));
        },
        (promotions) {
          emit(state.copyWith(
            status: PromotionsStatus.loaded,
            promotionsList: promotions,
          ));
        },
      );
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
      final result = await _promotionRepository.getPromotionById(event.promotionId!);
      
      result.fold(
        (error) {
          emit(state.copyWith(error: error));
        },
        (promotion) {
          emit(state.copyWith(currentPromotion: promotion));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        error: 'Ошибка обновления акции: $e',
      ));
    }
  }
}