part of 'admin_screen_bloc.dart';

abstract class AdminScreenState {
  final int selectedSection;

  const AdminScreenState({required this.selectedSection});
}

class AdminScreenInitial extends AdminScreenState {
  const AdminScreenInitial() : super(selectedSection: 0);
}

class AdminScreenChanged extends AdminScreenState {
  const AdminScreenChanged({required int selectedSection}) 
      : super(selectedSection: selectedSection);
}