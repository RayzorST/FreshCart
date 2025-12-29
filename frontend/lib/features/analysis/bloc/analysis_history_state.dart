part of 'analysis_history_bloc.dart';

abstract class AnalysisHistoryState {
  const AnalysisHistoryState();
}

class AnalysisHistoryInitial extends AnalysisHistoryState {}

class AnalysisHistoryLoading extends AnalysisHistoryState {
  final int currentTab;

  const AnalysisHistoryLoading({required this.currentTab});
}

class AnalysisHistorySuccess extends AnalysisHistoryState {
  final List<dynamic> myAnalysisHistory;
  final List<dynamic> allUsersAnalysis;
  final int currentTab;
  final bool isLoadingMyHistory;
  final bool isLoadingAllUsers;

  const AnalysisHistorySuccess({
    required this.myAnalysisHistory,
    required this.allUsersAnalysis,
    required this.currentTab,
    this.isLoadingMyHistory = false,
    this.isLoadingAllUsers = false,
  });

  AnalysisHistorySuccess copyWith({
    List<dynamic>? myAnalysisHistory,
    List<dynamic>? allUsersAnalysis,
    int? currentTab,
    bool? isLoadingMyHistory,
    bool? isLoadingAllUsers,
  }) {
    return AnalysisHistorySuccess(
      myAnalysisHistory: myAnalysisHistory ?? this.myAnalysisHistory,
      allUsersAnalysis: allUsersAnalysis ?? this.allUsersAnalysis,
      currentTab: currentTab ?? this.currentTab,
      isLoadingMyHistory: isLoadingMyHistory ?? this.isLoadingMyHistory,
      isLoadingAllUsers: isLoadingAllUsers ?? this.isLoadingAllUsers,
    );
  }
}

class AnalysisHistoryError extends AnalysisHistoryState {
  final String message;
  final int currentTab;

  const AnalysisHistoryError({
    required this.message,
    required this.currentTab,
  });
}

class AnalysisHistoryCartAction extends AnalysisHistoryState {
  final String message;
  final bool isSuccess;

  const AnalysisHistoryCartAction({
    required this.message,
    required this.isSuccess,
  });
}

class AnalysisHistoryShowDetailsState extends AnalysisHistoryState {
  final Map<String, dynamic> analysis;
  final bool isMyAnalysis;

  const AnalysisHistoryShowDetailsState({
    required this.analysis,
    required this.isMyAnalysis,
  });
}

class AnalysisHistoryShowOptionsState extends AnalysisHistoryState {
  final Map<String, dynamic> analysis;

  const AnalysisHistoryShowOptionsState(this.analysis);
}

class AnalysisHistoryDeleted extends AnalysisHistoryState {
  final String message;

  const AnalysisHistoryDeleted(this.message);
}

class AnalysisHistoryNavigateToResult extends AnalysisHistoryState {
  final Map<String, dynamic> resultData;
  final bool fromHistory;

  const AnalysisHistoryNavigateToResult({
    required this.resultData,
    required this.fromHistory,
  });
}