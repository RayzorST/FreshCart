// admin_dashboard_repository.dart
import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/admin_stats_entity.dart';

abstract class AdminDashboardRepository {
  Future<Either<String, AdminStatsEntity>> getAdminStats();
}