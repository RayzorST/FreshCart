// lib/presentation/bloc/analysis_result/analysis_result_state.dart
part of 'analysis_result_bloc.dart';

abstract class AnalysisResultState {
  const AnalysisResultState();
}

class AnalysisResultInitial extends AnalysisResultState {
  const AnalysisResultInitial();
}

class AnalysisResultLoading extends AnalysisResultState {
  final String? message;

  const AnalysisResultLoading({this.message});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultLoading && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class AnalysisResultSuccess extends AnalysisResultState {
  final Map<String, dynamic> result;
  final bool hasAvailableProducts;
  final DateTime analyzedAt;
  final List<SelectedProduct> selectedProducts; // Новое поле

  const AnalysisResultSuccess({
    required this.result,
    required this.hasAvailableProducts,
    required this.analyzedAt,
    this.selectedProducts = const [], // Инициализация пустым списком
  });

  factory AnalysisResultSuccess.now({
    required Map<String, dynamic> result,
    required bool hasAvailableProducts,
    List<SelectedProduct>? selectedProducts,
  }) {
    return AnalysisResultSuccess(
      result: result,
      hasAvailableProducts: hasAvailableProducts,
      analyzedAt: DateTime.now(),
      selectedProducts: selectedProducts ?? const [],
    );
  }

  // Новый метод для проверки выбранных продуктов
  bool get hasSelectedProducts => selectedProducts.isNotEmpty;

  // Новый метод для проверки выбран ли конкретный продукт
  bool isProductSelected(int productId, String ingredient, bool isBasic) {
    return selectedProducts.any((sp) => 
      sp.productId == productId && 
      sp.ingredient == ingredient &&
      sp.isBasic == isBasic
    );
  }

  // Новый метод для добавления выбранного продукта
  AnalysisResultSuccess copyWithAddedProduct({
    required int productId,
    required String ingredient,
    required bool isBasic,
    required Map<String, dynamic> productData,
  }) {
    final newProduct = SelectedProduct(
      productId: productId,
      ingredient: ingredient,
      isBasic: isBasic,
      productData: productData,
    );

    // Удаляем предыдущий выбор для этого ингредиента (если есть)
    final filteredProducts = selectedProducts.where((sp) => 
      !(sp.ingredient == ingredient && sp.isBasic == isBasic)
    ).toList();

    return AnalysisResultSuccess(
      result: result,
      hasAvailableProducts: hasAvailableProducts,
      analyzedAt: analyzedAt,
      selectedProducts: [...filteredProducts, newProduct],
    );
  }

  // Новый метод для удаления выбранного продукта
  AnalysisResultSuccess copyWithRemovedProduct({
    required int productId,
    required String ingredient,
    required bool isBasic,
  }) {
    final filteredProducts = selectedProducts.where((sp) => 
      !(sp.productId == productId && 
        sp.ingredient == ingredient &&
        sp.isBasic == isBasic)
    ).toList();

    return AnalysisResultSuccess(
      result: result,
      hasAvailableProducts: hasAvailableProducts,
      analyzedAt: analyzedAt,
      selectedProducts: filteredProducts,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultSuccess &&
        other.result == result &&
        other.hasAvailableProducts == hasAvailableProducts &&
        other.analyzedAt == analyzedAt &&
        listEquals(other.selectedProducts, selectedProducts);
  }

  @override
  int get hashCode => 
      result.hashCode ^ 
      hasAvailableProducts.hashCode ^ 
      analyzedAt.hashCode ^ 
      selectedProducts.hashCode;
}

class AnalysisResultError extends AnalysisResultState {
  final String message;
  final bool canRetry;

  const AnalysisResultError(this.message, {this.canRetry = true});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultError &&
        other.message == message &&
        other.canRetry == canRetry;
  }

  @override
  int get hashCode => message.hashCode ^ canRetry.hashCode;
}

class AnalysisResultCartAction extends AnalysisResultState {
  final String message;
  final bool isSuccess;
  final int? addedCount;
  final int? skippedCount;

  const AnalysisResultCartAction({
    required this.message,
    required this.isSuccess,
    this.addedCount,
    this.skippedCount,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultCartAction &&
        other.message == message &&
        other.isSuccess == isSuccess &&
        other.addedCount == addedCount &&
        other.skippedCount == skippedCount;
  }

  @override
  int get hashCode => 
      message.hashCode ^ 
      isSuccess.hashCode ^ 
      addedCount.hashCode ^ 
      skippedCount.hashCode;
}

class AnalysisResultNavigateBack extends AnalysisResultState {
  final bool shouldRefreshHistory;

  const AnalysisResultNavigateBack({this.shouldRefreshHistory = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultNavigateBack && 
        other.shouldRefreshHistory == shouldRefreshHistory;
  }

  @override
  int get hashCode => shouldRefreshHistory.hashCode;
}

class AnalysisResultSavingToHistory extends AnalysisResultState {
  const AnalysisResultSavingToHistory();
}

class AnalysisResultSavedToHistory extends AnalysisResultState {
  final String message;
  final int? historyId;

  const AnalysisResultSavedToHistory(this.message, {this.historyId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultSavedToHistory &&
        other.message == message &&
        other.historyId == historyId;
  }

  @override
  int get hashCode => message.hashCode ^ historyId.hashCode;
}

// Новое состояние для уведомления о выборе продукта
class AnalysisResultProductSelectedState extends AnalysisResultState {
  final String ingredient;
  final int productId;

  const AnalysisResultProductSelectedState({
    required this.ingredient,
    required this.productId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultProductSelectedState &&
        other.ingredient == ingredient &&
        other.productId == productId;
  }

  @override
  int get hashCode => ingredient.hashCode ^ productId.hashCode;
}

// Класс для хранения выбранных продуктов (добавить в этот же файл)
class SelectedProduct {
  final int productId;
  final String ingredient;
  final bool isBasic;
  final Map<String, dynamic> productData;

  SelectedProduct({
    required this.productId,
    required this.ingredient,
    required this.isBasic,
    required this.productData,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedProduct && 
        other.productId == productId && 
        other.ingredient == ingredient &&
        other.isBasic == isBasic;
  }

  @override
  int get hashCode => productId.hashCode ^ ingredient.hashCode ^ isBasic.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'ingredient': ingredient,
      'is_basic': isBasic,
      'product_data': productData,
    };
  }
}