// admin_dashboard_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/domain/entities/admin_stats_entity.dart';
import 'package:client/domain/repositories/admin_dashboard_repository.dart';

part 'admin_dashboard_event.dart';
part 'admin_dashboard_state.dart';

class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminDashboardRepository repository;

  AdminDashboardBloc({required this.repository}) : super(const AdminDashboardInitial()) {
    on<LoadAdminStats>(_onLoadAdminStats);
  }

  Future<void> _onLoadAdminStats(
    LoadAdminStats event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    
    final result = await repository.getAdminStats();
    
    result.fold(
      (error) => emit(AdminDashboardError(error)),
      (stats) => emit(AdminDashboardLoaded(stats)),
    );
  }
}