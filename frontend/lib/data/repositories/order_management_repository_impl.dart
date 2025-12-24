// order_management_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/order_entity.dart';
import 'package:client/domain/repositories/order_management_repository.dart';

class OrderManagementRepositoryImpl implements OrderManagementRepository {
  @override
  Future<Either<String, List<OrderEntity>>> getOrders({String? status}) async {
    try {
      final response = await ApiClient.getAdminOrders(
        status: status == 'all' ? null : status,
      );
      
      final orders = (response as List)
          .map((json) => OrderEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return Right(orders);
    } catch (e) {
      return Left('Ошибка загрузки заказов: $e');
    }
  }

  @override
  Future<Either<String, void>> updateOrderStatus(int orderId, String status) async {
    try {
      await ApiClient.updateOrderStatus(orderId, status);
      return const Right(null);
    } catch (e) {
      return Left('Ошибка обновления статуса заказа: $e');
    }
  }
}