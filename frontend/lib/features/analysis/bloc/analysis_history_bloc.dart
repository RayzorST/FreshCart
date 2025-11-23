import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/api/client.dart';

part 'analysis_history_event.dart';
part 'analysis_history_state.dart';

class AnalysisHistoryBloc extends Bloc<AnalysisHistoryEvent, AnalysisHistoryState> {
  AnalysisHistoryBloc() : super(AnalysisHistoryInitial()) {
    on<AnalysisHistoryStarted>(_onStarted);
    on<AnalysisHistoryTabChanged>(_onTabChanged);
    on<AnalysisHistoryRefreshed>(_onRefreshed);
    on<AnalysisHistoryAddAllToCart>(_onAddAllToCart);
    on<AnalysisHistoryDeleteRequested>(_onDeleteRequested);
    on<AnalysisHistoryShowDetails>(_onShowDetails);
    on<AnalysisHistoryShowOptions>(_onShowOptions);
  }

  Future<void> _onStarted(
    AnalysisHistoryStarted event,
    Emitter<AnalysisHistoryState> emit,
  ) async {
    emit(AnalysisHistoryLoading(currentTab: 0));
    
    try {
      final [myHistory, allUsers] = await Future.wait([
        ApiClient.getAnalysisHistory(),
        ApiClient.getAnalysisHistory(), // Заменить на правильный метод для всех пользователей
      ]);

      emit(AnalysisHistorySuccess(
        myAnalysisHistory: myHistory,
        allUsersAnalysis: allUsers,
        currentTab: 0,
      ));
    } catch (e) {
      emit(AnalysisHistoryError(
        message: 'Ошибка загрузки истории: $e',
        currentTab: 0,
      ));
    }
  }

  Future<void> _onTabChanged(
    AnalysisHistoryTabChanged event,
    Emitter<AnalysisHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is AnalysisHistorySuccess) {
      emit(currentState.copyWith(currentTab: event.tabIndex));
    }
  }

  Future<void> _onRefreshed(
    AnalysisHistoryRefreshed event,
    Emitter<AnalysisHistoryState> emit,
  ) async {
    final currentState = state;
    final currentTab = currentState is AnalysisHistorySuccess 
        ? currentState.currentTab 
        : 0;

    emit(AnalysisHistoryLoading(currentTab: currentTab));
    
    try {
      final [myHistory, allUsers] = await Future.wait([
        ApiClient.getAnalysisHistory(),
        ApiClient.getAnalysisHistory(), // Заменить на правильный метод для всех пользователей
      ]);

      emit(AnalysisHistorySuccess(
        myAnalysisHistory: myHistory,
        allUsersAnalysis: allUsers,
        currentTab: currentTab,
      ));
    } catch (e) {
      emit(AnalysisHistoryError(
        message: 'Ошибка загрузки истории: $e',
        currentTab: currentTab,
      ));
    }
  }

  Future<void> _onAddAllToCart(
    AnalysisHistoryAddAllToCart event,
    Emitter<AnalysisHistoryState> emit,
  ) async {
    try {
      final alternatives = event.alternatives;
      final basicAlts = List<dynamic>.from(alternatives['basic'] ?? []);
      final additionalAlts = List<dynamic>.from(alternatives['additional'] ?? []);
      
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
      
      emit(AnalysisHistoryCartAction(
        message: message,
        isSuccess: true,
      ));
    } catch (e) {
      emit(AnalysisHistoryCartAction(
        message: 'Ошибка при добавлении',
        isSuccess: false,
      ));
    }
  }

  Future<void> _onDeleteRequested(
    AnalysisHistoryDeleteRequested event,
    Emitter<AnalysisHistoryState> emit,
  ) async {
    try {
      // await ApiClient.deleteAnalysisRecord(event.analysisId);
      // В реальном приложении здесь был бы вызов API
      
      emit(const AnalysisHistoryDeleted('Анализ удален'));
      
      // Обновляем данные после удаления
      add(AnalysisHistoryRefreshed());
    } catch (e) {
      final currentState = state;
      if (currentState is AnalysisHistorySuccess) {
        emit(AnalysisHistoryError(
          message: 'Ошибка удаления: $e',
          currentTab: currentState.currentTab,
        ));
      }
    }
  }

  Future<void> _onShowDetails(
    AnalysisHistoryShowDetails event,
    Emitter<AnalysisHistoryState> emit,
  ) async {
    emit(AnalysisHistoryShowDetailsState(
      analysis: event.analysis,
      isMyAnalysis: event.isMyAnalysis,
    ));
  }

  Future<void> _onShowOptions(
    AnalysisHistoryShowOptions event,
    Emitter<AnalysisHistoryState> emit,
  ) async {
    emit(AnalysisHistoryShowOptionsState(event.analysis));
  }
}