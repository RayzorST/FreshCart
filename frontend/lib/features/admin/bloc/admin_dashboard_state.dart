// admin_dashboard_state.dart
part of 'admin_dashboard_bloc.dart';

abstract class AdminDashboardState {
  const AdminDashboardState();
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  final AdminStatsEntity stats;

  const AdminDashboardLoaded(this.stats);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is AdminDashboardLoaded &&
      other.stats.totalUsers == stats.totalUsers &&
      other.stats.totalOrders == stats.totalOrders &&
      other.stats.totalRevenue == stats.totalRevenue;
  }

  @override
  int get hashCode => Object.hash(
    stats.totalUsers,
    stats.totalOrders,
    stats.totalRevenue,
  );
}

class AdminDashboardError extends AdminDashboardState {
  final String message;

  const AdminDashboardError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is AdminDashboardError &&
      other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}