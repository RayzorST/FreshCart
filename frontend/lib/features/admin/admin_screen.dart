import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/features/admin/product_management.dart';
import 'package:client/features/admin/user_management.dart';
import 'package:client/features/admin/admin_dashboard.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _selectedSection = 0;

  final List<Widget> _sections = [
    const AdminDashboard(),
    const UserManagement(),
    const ProductManagement(),
    //const OrderManagement(),
    //const PromotionManagement(),
    //const CategoryManagement(),
  ];

  final List<String> _sectionTitles = [
    'Дашборд',
    'Пользователи',
    'Товары',
    'Заказы',
    'Акции',
    'Категории',
  ];

  final List<IconData> _sectionIcons = [
    Icons.dashboard,
    Icons.people,
    Icons.shopping_bag,
    Icons.receipt_long,
    Icons.local_offer,
    Icons.category,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Админ панель',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Верхняя навигация
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sectionTitles.length,
              itemBuilder: (context, index) {
                return _buildNavItem(index);
              },
            ),
          ),
          // Основной контент
          Expanded(
            child: _sections[_selectedSection],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedSection == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _selectedSection = index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _sectionIcons[index],
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  _sectionTitles[index],
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}