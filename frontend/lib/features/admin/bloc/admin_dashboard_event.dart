// admin_dashboard_event.dart
part of 'admin_dashboard_bloc.dart';

abstract class AdminDashboardEvent {
  const AdminDashboardEvent();
}

class LoadAdminStats extends AdminDashboardEvent {
  const LoadAdminStats();
}