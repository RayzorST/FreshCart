part of 'analysis_history_bloc.dart';

abstract class AnalysisHistoryEvent {}

class AnalysisHistoryStarted extends AnalysisHistoryEvent {}

class AnalysisHistoryTabChanged extends AnalysisHistoryEvent {
  final int tabIndex;

  AnalysisHistoryTabChanged(this.tabIndex);
}

class AnalysisHistoryRefreshed extends AnalysisHistoryEvent {}

class AnalysisHistoryItemSelected extends AnalysisHistoryEvent {
  final Map<String, dynamic> analysis;
  final bool isMyAnalysis;

  AnalysisHistoryItemSelected({
    required this.analysis,
    required this.isMyAnalysis,
  });
}

class AnalysisHistoryAddAllToCart extends AnalysisHistoryEvent {
  final Map<String, dynamic> alternatives;

  AnalysisHistoryAddAllToCart(this.alternatives);
}

class AnalysisHistoryDeleteRequested extends AnalysisHistoryEvent {
  final int analysisId;

  AnalysisHistoryDeleteRequested(this.analysisId);
}

class AnalysisHistoryShowDetails extends AnalysisHistoryEvent {
  final Map<String, dynamic> analysis;
  final bool isMyAnalysis;

  AnalysisHistoryShowDetails({
    required this.analysis,
    required this.isMyAnalysis,
  });
}

class AnalysisHistoryShowOptions extends AnalysisHistoryEvent {
  final Map<String, dynamic> analysis;

  AnalysisHistoryShowOptions(this.analysis);
}