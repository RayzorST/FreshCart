// lib/presentation/bloc/analysis_result/analysis_result_event.dart
part of 'analysis_result_bloc.dart';

abstract class AnalysisResultEvent {
  const AnalysisResultEvent();
}

class AnalysisResultStarted extends AnalysisResultEvent {
  final String imageData;

  const AnalysisResultStarted(this.imageData);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultStarted && other.imageData == imageData;
  }

  @override
  int get hashCode => imageData.hashCode;
}

class AnalysisResultRetried extends AnalysisResultEvent {
  final String? imageData;

  const AnalysisResultRetried({this.imageData});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultRetried && other.imageData == imageData;
  }

  @override
  int get hashCode => imageData.hashCode;
}

class AnalysisResultAddToCart extends AnalysisResultEvent {
  final int productId;
  final int quantity;

  const AnalysisResultAddToCart({
    required this.productId,
    this.quantity = 1,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultAddToCart &&
        other.productId == productId &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => productId.hashCode ^ quantity.hashCode;
}

// Новые события для управления выбором продуктов
class AnalysisResultProductSelected extends AnalysisResultEvent {
  final int productId;
  final String ingredient;
  final bool isBasic;
  final Map<String, dynamic> product;

  const AnalysisResultProductSelected({
    required this.productId,
    required this.ingredient,
    required this.isBasic,
    required this.product,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultProductSelected &&
        other.productId == productId &&
        other.ingredient == ingredient &&
        other.isBasic == isBasic;
  }

  @override
  int get hashCode => productId.hashCode ^ ingredient.hashCode ^ isBasic.hashCode;
}

class AnalysisResultProductDeselected extends AnalysisResultEvent {
  final int productId;
  final String ingredient;
  final bool isBasic;

  const AnalysisResultProductDeselected({
    required this.productId,
    required this.ingredient,
    required this.isBasic,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultProductDeselected &&
        other.productId == productId &&
        other.ingredient == ingredient &&
        other.isBasic == isBasic;
  }

  @override
  int get hashCode => productId.hashCode ^ ingredient.hashCode ^ isBasic.hashCode;
}

class AnalysisResultAddAllToCart extends AnalysisResultEvent {
  final Map<String, dynamic>? analysisData;

  const AnalysisResultAddAllToCart({this.analysisData});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultAddAllToCart && other.analysisData == analysisData;
  }

  @override
  int get hashCode => analysisData.hashCode;
}

class AnalysisResultBackPressed extends AnalysisResultEvent {
  const AnalysisResultBackPressed();

  @override
  bool operator ==(Object other) => identical(this, other) || other is AnalysisResultBackPressed;

  @override
  int get hashCode => runtimeType.hashCode;
}

class AnalysisResultSaveToHistory extends AnalysisResultEvent {
  final Map<String, dynamic> analysisData;

  const AnalysisResultSaveToHistory(this.analysisData);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultSaveToHistory && other.analysisData == analysisData;
  }

  @override
  int get hashCode => analysisData.hashCode;
}

class AnalysisResultShare extends AnalysisResultEvent {
  final Map<String, dynamic> analysisData;

  const AnalysisResultShare(this.analysisData);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResultShare && other.analysisData == analysisData;
  }

  @override
  int get hashCode => analysisData.hashCode;
}