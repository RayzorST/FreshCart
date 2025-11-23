import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/api/client.dart';

part 'analysis_result_event.dart';
part 'analysis_result_state.dart';

class AnalysisResultBloc extends Bloc<AnalysisResultEvent, AnalysisResultState> {
  AnalysisResultBloc() : super(AnalysisResultInitial()) {
    on<AnalysisResultStarted>(_onStarted);
    on<AnalysisResultRetried>(_onRetried);
    on<AnalysisResultAddToCart>(_onAddToCart);
    on<AnalysisResultAddAllToCart>(_onAddAllToCart);
    on<AnalysisResultBackPressed>(_onBackPressed);
  }

  Future<void> _onStarted(
    AnalysisResultStarted event,
    Emitter<AnalysisResultState> emit,
  ) async {
    emit(AnalysisResultLoading());
    
    try {
      final result = await ApiClient.analyzeFoodImage(event.imageData);
      
      if (result['success'] == false) {
        emit(AnalysisResultError('Ошибка анализа: ${result['message']}'));
        return;
      }
      
      final hasProducts = _hasAvailableProducts(result);
      emit(AnalysisResultSuccess(
        result: result,
        hasAvailableProducts: hasProducts,
      ));
    } catch (e) {
      emit(AnalysisResultError('Ошибка анализа: ${e.toString()}'));
    }
  }

  Future<void> _onRetried(
    AnalysisResultRetried event,
    Emitter<AnalysisResultState> emit,
  ) async {
    final currentState = state;
    if (currentState is AnalysisResultError) {
      // Для повторного анализа нужно вернуться на предыдущий экран
      emit(AnalysisResultNavigateBack());
    }
  }

  Future<void> _onAddToCart(
    AnalysisResultAddToCart event,
    Emitter<AnalysisResultState> emit,
  ) async {
    try {
      await ApiClient.addToCart(event.productId, 1);
      emit(AnalysisResultCartAction(
        message: 'Товар добавлен в корзину',
        isSuccess: true,
      ));
    } catch (e) {
      emit(AnalysisResultCartAction(
        message: 'Ошибка добавления',
        isSuccess: false,
      ));
    }
  }

  Future<void> _onAddAllToCart(
    AnalysisResultAddAllToCart event,
    Emitter<AnalysisResultState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AnalysisResultSuccess) return;

    try {
      final result = currentState.result;
      final basicAlts = List<dynamic>.from(result['basic_alternatives'] ?? []);
      final additionalAlts = List<dynamic>.from(result['additional_alternatives'] ?? []);
      
      int addedCount = 0;
      int skippedCount = 0;
      
      for (final alt in [...basicAlts, ...additionalAlts]) {
        final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
        for (final product in products) {
          final stockQuantity = (product['stock_quantity'] ?? 1).toInt();
          if (stockQuantity > 0) {
            await ApiClient.addToCart(product['id'], 1);
            addedCount++;
          } else {
            skippedCount++;
          }
        }
      }
      
      String message;
      if (skippedCount > 0) {
        message = 'Добавлено $addedCount товаров в корзину (пропущено $skippedCount - нет в наличии)';
      } else {
        message = 'Добавлено $addedCount товаров в корзину';
      }
      
      emit(AnalysisResultCartAction(
        message: message,
        isSuccess: true,
      ));
    } catch (e) {
      emit(AnalysisResultCartAction(
        message: 'Ошибка при добавлении',
        isSuccess: false,
      ));
    }
  }

  Future<void> _onBackPressed(
    AnalysisResultBackPressed event,
    Emitter<AnalysisResultState> emit,
  ) async {
    emit(AnalysisResultNavigateBack());
  }

  bool _hasAvailableProducts(Map<String, dynamic> result) {
    final basicAlts = List<dynamic>.from(result['basic_alternatives'] ?? []);
    final additionalAlts = List<dynamic>.from(result['additional_alternatives'] ?? []);
    
    for (final alt in [...basicAlts, ...additionalAlts]) {
      final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
      for (final product in products) {
        final stockQuantity = (product['stock_quantity'] ?? 1).toInt();
        if (stockQuantity > 0) {
          return true;
        }
      }
    }
    return false;
  }
}