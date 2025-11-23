part of 'analysis_result_bloc.dart';

abstract class AnalysisResultState {
  const AnalysisResultState();
}

class AnalysisResultInitial extends AnalysisResultState {}

class AnalysisResultLoading extends AnalysisResultState {}

class AnalysisResultSuccess extends AnalysisResultState {
  final Map<String, dynamic> result;
  final bool hasAvailableProducts;

  const AnalysisResultSuccess({
    required this.result,
    required this.hasAvailableProducts,
  });
}

class AnalysisResultError extends AnalysisResultState {
  final String message;

  const AnalysisResultError(this.message);
}

class AnalysisResultCartAction extends AnalysisResultState {
  final String message;
  final bool isSuccess;

  const AnalysisResultCartAction({
    required this.message,
    required this.isSuccess,
  });
}

class AnalysisResultNavigateBack extends AnalysisResultState {}