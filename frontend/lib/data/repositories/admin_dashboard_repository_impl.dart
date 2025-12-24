// admin_dashboard_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/admin_stats_entity.dart';
import 'package:client/domain/repositories/admin_dashboard_repository.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  @override
  Future<Either<String, AdminStatsEntity>> getAdminStats() async {
    try {
      final response = await ApiClient.getAdminStats();
      final stats = AdminStatsEntity.fromJson(response);
      return Right(stats);
    } catch (e) {
      return Left('Ошибка загрузки статистики: $e');
    }
  }
}