// admin_stats_entity.dart
class AdminStatsEntity {
  final int totalUsers;
  final int totalOrders;
  final double totalRevenue;
  final int totalProducts;
  final int activePromotions;
  final Map<String, int> ordersByStatus;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> topProducts;

  AdminStatsEntity({
    required this.totalUsers,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalProducts,
    required this.activePromotions,
    required this.ordersByStatus,
    required this.recentOrders,
    required this.topProducts,
  });

  factory AdminStatsEntity.fromJson(Map<String, dynamic> json) {
    return AdminStatsEntity(
      totalUsers: json['total_users'] as int? ?? 0,
      totalOrders: json['total_orders'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalProducts: json['total_products'] as int? ?? 0,
      activePromotions: json['active_promotions'] as int? ?? 0,
      ordersByStatus: Map<String, int>.from(json['orders_by_status'] as Map? ?? {}),
      recentOrders: List<Map<String, dynamic>>.from(json['recent_orders'] as List? ?? []),
      topProducts: List<Map<String, dynamic>>.from(json['top_products'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'total_products': totalProducts,
      'active_promotions': activePromotions,
      'orders_by_status': ordersByStatus,
      'recent_orders': recentOrders,
      'top_products': topProducts,
    };
  }
}