part of 'analysis_result_bloc.dart';

abstract class AnalysisResultEvent {}

class AnalysisResultStarted extends AnalysisResultEvent {
  final String imageData;

  AnalysisResultStarted(this.imageData);
}

class AnalysisResultRetried extends AnalysisResultEvent {}

class AnalysisResultAddToCart extends AnalysisResultEvent {
  final int productId;

  AnalysisResultAddToCart(this.productId);
}

class AnalysisResultAddAllToCart extends AnalysisResultEvent {}

class AnalysisResultBackPressed extends AnalysisResultEvent {}