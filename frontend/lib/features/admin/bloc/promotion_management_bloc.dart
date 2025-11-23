import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/api/client.dart';
import 'package:flutter/foundation.dart';

part 'promotion_management_event.dart';
part 'promotion_management_state.dart';

class PromotionManagementBloc extends Bloc<PromotionManagementEvent, PromotionManagementState> {
  PromotionManagementBloc() : super(const PromotionManagementInitial()) {
    on<LoadPromotions>(_onLoadPromotions);
    on<CreatePromotion>(_onCreatePromotion);
    on<DeletePromotion>(_onDeletePromotion);
  }

  Future<void> _onLoadPromotions(
    LoadPromotions event,
    Emitter<PromotionManagementState> emit,
  ) async {
    emit(const PromotionManagementLoading());
    
    try {
      final promotions = await ApiClient.getAdminPromotions();
      emit(PromotionManagementLoaded(promotions));
    } catch (e) {
      emit(PromotionManagementError('Ошибка загрузки акций: $e'));
    }
  }

  Future<void> _onCreatePromotion(
    CreatePromotion event,
    Emitter<PromotionManagementState> emit,
  ) async {
    try {
      await ApiClient.createAdminPromotion(event.promotionData);
      emit(const PromotionManagementOperationSuccess('Акция создана'));
      add(const LoadPromotions());
    } catch (e) {
      emit(PromotionManagementError('Ошибка создания акции: $e'));
    }
  }

  Future<void> _onDeletePromotion(
    DeletePromotion event,
    Emitter<PromotionManagementState> emit,
  ) async {
    try {
      await ApiClient.deleteAdminPromotion(event.promotionId);
      emit(const PromotionManagementOperationSuccess('Акция удалена'));
      add(const LoadPromotions());
    } catch (e) {
      emit(PromotionManagementError('Ошибка удаления акции: $e'));
    }
  }
}