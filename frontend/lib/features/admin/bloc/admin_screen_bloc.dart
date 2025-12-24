// admin_screen_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/domain/repositories/admin_screen_repository.dart';

part 'admin_screen_event.dart';
part 'admin_screen_state.dart';

class AdminScreenBloc extends Bloc<AdminScreenEvent, AdminScreenState> {
  final AdminScreenRepository repository;

  AdminScreenBloc({required this.repository}) : super(const AdminScreenInitial()) {
    on<AdminScreenSectionChanged>(_onSectionChanged);
    on<LoadAdminAccess>(_onLoadAdminAccess);
  }

  Future<void> _onLoadAdminAccess(
    LoadAdminAccess event,
    Emitter<AdminScreenState> emit,
  ) async {
    emit(const AdminScreenLoading());
    
    try {
      final isAdmin = await repository.isUserAdmin();
      
      if (!isAdmin) {
        emit(const AdminScreenError('Доступ запрещен'));
      } else {
        // Сразу переходим в загруженное состояние
        emit(const AdminScreenLoaded(selectedSection: 0));
      }
    } catch (e) {
      emit(AdminScreenError('Ошибка: $e'));
    }
  }

  void _onSectionChanged(
    AdminScreenSectionChanged event,
    Emitter<AdminScreenState> emit,
  ) {
    print('Section changed to: ${event.sectionIndex}'); // Добавляем лог
    
    if (state is AdminScreenLoaded) {
      emit(AdminScreenLoaded(selectedSection: event.sectionIndex));
    }
    // Также позволяем менять секцию из состояния ошибки
    else if (state is AdminScreenError) {
      emit(AdminScreenError((state as AdminScreenError).message, 
          selectedSection: event.sectionIndex));
    }
  }

  void loadAdminAccess() {
    add(LoadAdminAccess());
  }
}