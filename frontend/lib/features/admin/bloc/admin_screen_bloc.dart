import 'package:flutter_bloc/flutter_bloc.dart';

part 'admin_screen_event.dart';
part 'admin_screen_state.dart';

class AdminScreenBloc extends Bloc<AdminScreenEvent, AdminScreenState> {
  AdminScreenBloc() : super(const AdminScreenInitial()) {
    on<AdminScreenSectionChanged>(_onSectionChanged);
  }

  void _onSectionChanged(
    AdminScreenSectionChanged event,
    Emitter<AdminScreenState> emit,
  ) {
    emit(AdminScreenChanged(selectedSection: event.sectionIndex));
  }
}