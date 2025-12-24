// promotion_management_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/domain/entities/promotion_entity.dart';
import 'package:client/domain/repositories/promotion_management_repository.dart';

part 'promotion_management_event.dart';
part 'promotion_management_state.dart';

class PromotionManagementBloc extends Bloc<PromotionManagementEvent, PromotionManagementState> {
  final PromotionManagementRepository repository;

  PromotionManagementBloc({required this.repository}) : super(const PromotionManagementInitial()) {
    on<LoadPromotions>(_onLoadPromotions);
    on<CreatePromotion>(_onCreatePromotion);
    on<DeletePromotion>(_onDeletePromotion);
    on<UpdatePromotion>(_onUpdatePromotion);
  }

  Future<void> _onLoadPromotions(
    LoadPromotions event,
    Emitter<PromotionManagementState> emit,
  ) async {
    emit(const PromotionManagementLoading());
    
    final result = await repository.getPromotions();
    
    result.fold(
      (error) => emit(PromotionManagementError(error)),
      (promotions) => emit(PromotionManagementLoaded(promotions)),
    );
  }

  Future<void> _onCreatePromotion(
    CreatePromotion event,
    Emitter<PromotionManagementState> emit,
  ) async {
    final result = await repository.createPromotion(event.promotionData);
    
    result.fold(
      (error) => emit(PromotionManagementError(error)),
      (_) {
        emit(const PromotionManagementOperationSuccess('Акция создана'));
        add(const LoadPromotions());
      },
    );
  }

  Future<void> _onDeletePromotion(
    DeletePromotion event,
    Emitter<PromotionManagementState> emit,
  ) async {
    final result = await repository.deletePromotion(event.promotionId);
    
    result.fold(
      (error) => emit(PromotionManagementError(error)),
      (_) {
        emit(const PromotionManagementOperationSuccess('Акция удалена'));
        add(const LoadPromotions());
      },
    );
  }

  Future<void> _onUpdatePromotion(
    UpdatePromotion event,
    Emitter<PromotionManagementState> emit,
  ) async {
    final result = await repository.updatePromotion(
      event.promotionId, 
      event.promotionData,
    );
    
    result.fold(
      (error) => emit(PromotionManagementError(error)),
      (_) {
        emit(const PromotionManagementOperationSuccess('Акция обновлена'));
        add(const LoadPromotions());
      },
    );
  }
}