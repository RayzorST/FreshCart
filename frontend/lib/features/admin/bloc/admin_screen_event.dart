part of 'admin_screen_bloc.dart';

abstract class AdminScreenEvent {
  const AdminScreenEvent();
}

class AdminScreenSectionChanged extends AdminScreenEvent {
  final int sectionIndex;

  const AdminScreenSectionChanged(this.sectionIndex);
}