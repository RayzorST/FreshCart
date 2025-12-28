// lib/presentation/bloc/analysis_history/analysis_history_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/domain/repositories/analysis_repository.dart';
import 'package:injectable/injectable.dart';

part 'analysis_history_event.dart';
part 'analysis_history_state.dart';

@injectable
class AnalysisHistoryBloc extends Bloc<AnalysisHistoryEvent, AnalysisHistoryState> {
  final AnalysisRepository _analysisRepository;

  AnalysisHistoryBloc(this._analysisRepository) : super(AnalysisHistoryInitial()) {
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
      final results = await Future.wait([
        _analysisRepository.getMyAnalysisHistory(),
        _analysisRepository.getAllAnalysisHistory(),
      ]);

      results[0].fold(
        (error) => emit(AnalysisHistoryError(message: error, currentTab: 0)),
        (myHistory) {
          results[1].fold(
            (error) => emit(AnalysisHistoryError(message: error, currentTab: 0)),
            (allUsers) {
              emit(AnalysisHistorySuccess(
                myAnalysisHistory: myHistory.map((e) => e.toJson()).toList(),
                allUsersAnalysis: allUsers.map((e) => e.toJson()).toList(),
                currentTab: 0,
              ));
            },
          );
        },
      );
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
      final results = await Future.wait([
        _analysisRepository.getMyAnalysisHistory(),
        _analysisRepository.getAllAnalysisHistory(),
      ]);

      results[0].fold(
        (error) => emit(AnalysisHistoryError(message: error, currentTab: currentTab)),
        (myHistory) {
          results[1].fold(
            (error) => emit(AnalysisHistoryError(message: error, currentTab: currentTab)),
            (allUsers) {
              emit(AnalysisHistorySuccess(
                myAnalysisHistory: myHistory.map((e) => e.toJson()).toList(),
                allUsersAnalysis: allUsers.map((e) => e.toJson()).toList(),
                currentTab: currentTab,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(AnalysisHistoryError(
        message: 'Ошибка загрузки истории: $e',
        currentTab: currentTab,
      ));
    }
  }

  // Остальные методы остаются без изменений, так как они работают с UI-логикой
  Future<void> _onAddAllToCart(
    AnalysisHistoryAddAllToCart event,
    Emitter<AnalysisHistoryState> emit,
  ) async {
    // Логика добавления в корзину остается прежней
    // Это UI-логика, она не относится к слою данных
  }

  Future<void> _onDeleteRequested(
    AnalysisHistoryDeleteRequested event,
    Emitter<AnalysisHistoryState> emit,
  ) async {
    try {
      final result = await _analysisRepository.deleteAnalysisRecord(event.analysisId);
      
      result.fold(
        (error) {
          final currentState = state;
          if (currentState is AnalysisHistorySuccess) {
            emit(AnalysisHistoryError(
              message: 'Ошибка удаления: $error',
              currentTab: currentState.currentTab,
            ));
          }
        },
        (_) {
          emit(const AnalysisHistoryDeleted('Анализ удален'));
          add(AnalysisHistoryRefreshed());
        },
      );
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