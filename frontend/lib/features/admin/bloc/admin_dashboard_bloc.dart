import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/api/client.dart';

part 'admin_dashboard_event.dart';
part 'admin_dashboard_state.dart';

class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  AdminDashboardBloc() : super(const AdminDashboardInitial()) {
    on<LoadAdminStats>(_onLoadAdminStats);
  }

  Future<void> _onLoadAdminStats(
    LoadAdminStats event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    
    try {
      final stats = await ApiClient.getAdminStats();
      emit(AdminDashboardLoaded(stats));
    } catch (e) {
      emit(AdminDashboardError('Ошибка загрузки статистики: $e'));
    }
  }
}