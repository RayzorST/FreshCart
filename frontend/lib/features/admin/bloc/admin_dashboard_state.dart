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
  final Map<String, dynamic> stats;

  const AdminDashboardLoaded(this.stats);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is AdminDashboardLoaded &&
      _mapsEqual(other.stats, stats);
  }

  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => stats.hashCode;
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