import 'package:flutter/material.dart';

class AdminSectionEntity {
  final int id;
  final String title;
  final IconData icon;
  final bool isVisible;

  const AdminSectionEntity({
    required this.id,
    required this.title,
    required this.icon,
    this.isVisible = true,
  });

  factory AdminSectionEntity.fromJson(Map<String, dynamic> json) {
    return AdminSectionEntity(
      id: json['id'] as int,
      title: json['title'] as String,
      icon: _iconFromString(json['icon'] as String),
      isVisible: json['is_visible'] as bool? ?? true,
    );
  }

  static IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'dashboard':
        return Icons.dashboard;
      case 'people':
        return Icons.people;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'local_offer':
        return Icons.local_offer;
      default:
        return Icons.help_outline;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': _iconToString(icon),
      'is_visible': isVisible,
    };
  }

  static String _iconToString(IconData icon) {
    if (icon == Icons.dashboard) return 'dashboard';
    if (icon == Icons.people) return 'people';
    if (icon == Icons.shopping_bag) return 'shopping_bag';
    if (icon == Icons.receipt_long) return 'receipt_long';
    if (icon == Icons.local_offer) return 'local_offer';
    return 'help_outline';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminSectionEntity && 
      other.id == id &&
      other.title == title;
  }

  @override
  int get hashCode => Object.hash(id, title);
}