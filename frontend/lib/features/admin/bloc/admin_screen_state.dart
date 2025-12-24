// admin_screen_state.dart
part of 'admin_screen_bloc.dart';

abstract class AdminScreenState {
  final int selectedSection;
  
  const AdminScreenState({this.selectedSection = 0});
}

class AdminScreenInitial extends AdminScreenState {
  const AdminScreenInitial() : super(selectedSection: 0);
}

class AdminScreenLoading extends AdminScreenState {
  const AdminScreenLoading() : super(selectedSection: 0);
}

class AdminScreenLoaded extends AdminScreenState {
  const AdminScreenLoaded({int selectedSection = 0}) 
      : super(selectedSection: selectedSection);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is AdminScreenLoaded &&
      other.selectedSection == selectedSection;
  }

  @override
  int get hashCode => selectedSection.hashCode;
}

class AdminScreenError extends AdminScreenState {
  final String message;

  const AdminScreenError(this.message, {int selectedSection = 0}) 
      : super(selectedSection: selectedSection);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is AdminScreenError &&
      other.message == message &&
      other.selectedSection == selectedSection;
  }

  @override
  int get hashCode => Object.hash(message, selectedSection);
}