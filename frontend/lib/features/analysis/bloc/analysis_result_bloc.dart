import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart. ';
import 'package:client/domain/repositories/analysis_repository.dart';
import 'package:client/domain/repositories/cart_repository.dart';
import 'package:injectable/injectable.dart';

part 'analysis_result_event.dart';
part 'analysis_result_state.dart';

@injectable
class AnalysisResultBloc extends Bloc<AnalysisResultEvent, AnalysisResultState> {
  final AnalysisRepository _analysisRepository;
  final CartRepository _cartRepository;

  AnalysisResultBloc({
    required AnalysisRepository analysisRepository,
    required CartRepository cartRepository,
  })  : _analysisRepository = analysisRepository,
        _cartRepository = cartRepository,
        super(AnalysisResultInitial()) {
    on<AnalysisResultStarted>(_onStarted);
    on<AnalysisResultRetried>(_onRetried);
    on<AnalysisResultAddToCart>(_onAddToCart);
    on<AnalysisResultAddAllToCart>(_onAddAllToCart);
    on<AnalysisResultBackPressed>(_onBackPressed);
    on<AnalysisResultFromHistory>(_onFromHistory);
    on<AnalysisResultProductSelected>(_onProductSelected);
    on<AnalysisResultProductDeselected>(_onProductDeselected);
  }

  Future<void> _onStarted(
    AnalysisResultStarted event,
    Emitter<AnalysisResultState> emit,
  ) async {
    emit(AnalysisResultLoading(message: 'Анализируем изображение...'));
    
    try {
      final result = await _analysisRepository.analyzeFoodImage(event.imageData);
      
      result.fold(
        (error) => emit(AnalysisResultError('Ошибка анализа: $error')),
        (analysisResult) {
          emit(AnalysisResultSuccess(
            result: analysisResult.toJson(),
            hasAvailableProducts: analysisResult.hasAvailableProducts,
            analyzedAt: DateTime.now(),
            selectedProducts: [],
          ));
        },
      );
    } catch (e) {
      emit(AnalysisResultError('Неожиданная ошибка: ${e.toString()}'));
    }
  }

  Future<void> _onRetried(
    AnalysisResultRetried event,
    Emitter<AnalysisResultState> emit,
  ) async {
    if (event.imageData != null) {
      add(AnalysisResultStarted(event.imageData!));
    } else {
      emit(AnalysisResultNavigateBack(shouldRefreshHistory: true));
    }
  }

  Future<void> _onAddToCart(
    AnalysisResultAddToCart event,
    Emitter<AnalysisResultState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AnalysisResultSuccess) return;

    emit(AnalysisResultLoading(message: 'Добавляем в корзину...'));

    try {
      final result = await _cartRepository.addToCart(
        event.productId,
        event.quantity,
      );

      result.fold(
        (error) => emit(AnalysisResultCartAction(
          message: error,
          isSuccess: false,
        )),
        (cartItem) => emit(AnalysisResultCartAction(
          message: 'Товар добавлен в корзину',
          isSuccess: true,
          addedCount: 1,
        )),
      );
    } catch (e) {
      emit(AnalysisResultCartAction(
        message: 'Ошибка добавления в корзину: $e',
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

    emit(AnalysisResultLoading(message: 'Добавляем товары в корзину...'));

    try {
      // Добавляем только выбранные продукты
      final selectedProducts = currentState.selectedProducts;
      
      if (selectedProducts.isEmpty) {
        emit(AnalysisResultCartAction(
          message: 'Выберите продукты для добавления в корзину',
          isSuccess: false,
        ));
        return;
      }

      int addedCount = 0;
      int skippedCount = 0;
      List<String> errors = [];
      
      for (final selectedProduct in selectedProducts) {
        final productData = selectedProduct.productData;
        final stockQuantity = (productData['stock_quantity'] ?? 1).toInt();
        
        if (stockQuantity > 0) {
          try {
            final cartResult = await _cartRepository.addToCart(
              selectedProduct.productId,
              1, // Количество по умолчанию
            );
            
            cartResult.fold(
              (error) {
                skippedCount++;
                errors.add(error);
              },
              (_) => addedCount++,
            );
          } catch (e) {
            skippedCount++;
            errors.add('Ошибка для продукта ${selectedProduct.productId}: $e');
          }
        } else {
          skippedCount++;
          errors.add('Нет в наличии: ${productData['name']}');
        }
      }
      
      String message;
      if (skippedCount > 0) {
        message = 'Добавлено $addedCount товаров в корзину (пропущено $skippedCount)';
        if (errors.isNotEmpty) {
          message += '\n${errors.take(3).join(", ")}';
          if (errors.length > 3) message += '...';
        }
      } else {
        message = 'Добавлено $addedCount товаров в корзину';
      }
      
      emit(AnalysisResultCartAction(
        message: message,
        isSuccess: true,
        addedCount: addedCount,
        skippedCount: skippedCount,
      ));
    } catch (e) {
      emit(AnalysisResultCartAction(
        message: 'Ошибка при добавлении товаров: $e',
        isSuccess: false,
      ));
    }
  }

  Future<void> _onBackPressed(
    AnalysisResultBackPressed event,
    Emitter<AnalysisResultState> emit,
  ) async {
    emit(AnalysisResultNavigateBack(shouldRefreshHistory: true));
  }

  // Новый обработчик для выбора продукта
  Future<void> _onProductSelected(
    AnalysisResultProductSelected event,
    Emitter<AnalysisResultState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AnalysisResultSuccess) return;

    // Создаем новое состояние с добавленным продуктом
    final newState = currentState.copyWithAddedProduct(
      productId: event.productId,
      ingredient: event.ingredient,
      isBasic: event.isBasic,
      productData: event.product,
    );

    emit(newState);
    
    // Дополнительно можно эмитнуть уведомление о выборе
    emit(AnalysisResultProductSelectedState(
      ingredient: event.ingredient,
      productId: event.productId,
    ));
    
    // Возвращаемся к основному состоянию
    emit(newState);
  }

  // Новый обработчик для отмены выбора продукта
  Future<void> _onProductDeselected(
    AnalysisResultProductDeselected event,
    Emitter<AnalysisResultState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AnalysisResultSuccess) return;

    // Создаем новое состояние с удаленным продуктом
    final newState = currentState.copyWithRemovedProduct(
      productId: event.productId,
      ingredient: event.ingredient,
      isBasic: event.isBasic,
    );

    emit(newState);
  }
  
  Future<void> _onFromHistory(
    AnalysisResultFromHistory event,
    Emitter<AnalysisResultState> emit,
  ) async {
    emit(AnalysisResultSuccess(
      result: event.resultData,
      hasAvailableProducts: _checkHasAvailableProducts(event.resultData), // Добавить
      analyzedAt: DateTime.now(), // Добавить
      selectedProducts: [],
    ));
  }

  // Вспомогательный метод для проверки наличия продуктов
  bool _checkHasAvailableProducts(Map<String, dynamic> resultData) {
    try {
      final basicAlternatives = List<dynamic>.from(resultData['basic_alternatives'] ?? []);
      final additionalAlternatives = List<dynamic>.from(resultData['additional_alternatives'] ?? []);
      
      for (final alt in [...basicAlternatives, ...additionalAlternatives]) {
        final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
        for (final product in products) {
          final stockQuantity = (product['stock_quantity'] ?? 1).toInt();
          if (stockQuantity > 0) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}