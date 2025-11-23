import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/features/admin/screens/product_management.dart';
import 'package:client/features/admin/screens/user_management.dart';
import 'package:client/features/admin/screens/admin_dashboard.dart';
import 'package:client/features/admin/screens/promotion_management.dart';
import 'package:client/features/admin/screens/order_management.dart';
import 'package:client/features/admin/bloc/admin_screen_bloc.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminScreenBloc(),
      child: const _AdminScreenView(),
    );
  }
}

class _AdminScreenView extends StatelessWidget {
  const _AdminScreenView();

  final List<String> _sectionTitles = const [
    'Дашборд',
    'Пользователи',
    'Товары',
    'Заказы',
    'Акции',
  ];

  final List<IconData> _sectionIcons = const [
    Icons.dashboard,
    Icons.people,
    Icons.shopping_bag,
    Icons.receipt_long,
    Icons.local_offer,
  ];

  final List<Widget> _sections = const [
    AdminDashboard(),
    UserManagement(),
    ProductManagement(),
    OrderManagement(),
    PromotionManagement(),
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
          _buildNavigationBar(context),
          // Основной контент
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: BlocBuilder<AdminScreenBloc, AdminScreenState>(
        builder: (context, state) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _sectionTitles.length,
            itemBuilder: (context, index) {
              return _buildNavItem(context, index, state.selectedSection);
            },
          );
        },
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, int selectedSection) {
    final isSelected = selectedSection == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _onSectionChanged(context, index),
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

  Widget _buildContent() {
    return BlocBuilder<AdminScreenBloc, AdminScreenState>(
      builder: (context, state) {
        return Expanded(
          child: _sections[state.selectedSection],
        );
      },
    );
  }

  void _onSectionChanged(BuildContext context, int sectionIndex) {
    context.read<AdminScreenBloc>().add(AdminScreenSectionChanged(sectionIndex));
  }
}