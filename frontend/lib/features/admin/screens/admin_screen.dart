// admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/features/admin/screens/product_management.dart';
import 'package:client/features/admin/screens/user_management.dart';
import 'package:client/features/admin/screens/admin_dashboard.dart';
import 'package:client/features/admin/screens/promotion_management.dart';
import 'package:client/features/admin/screens/order_management.dart';
import 'package:client/features/admin/bloc/admin_screen_bloc.dart';
import 'package:client/data/repositories/admin_screen_repository_impl.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminScreenBloc(
        repository: AdminScreenRepositoryImpl(),
      ),
      child: const _AdminScreenView(),
    );
  }
}

class _AdminScreenView extends StatefulWidget {
  const _AdminScreenView();

  @override
  State<_AdminScreenView> createState() => _AdminScreenViewState();
}

class _AdminScreenViewState extends State<_AdminScreenView> {
  final List<String> _sectionTitles = [
    'Дашборд',
    'Пользователи',
    'Товары',
    'Заказы',
    'Акции',
  ];

  final List<IconData> _sectionIcons = [
    Icons.dashboard,
    Icons.people,
    Icons.shopping_bag,
    Icons.receipt_long,
    Icons.local_offer,
  ];

  final List<Widget> _sectionWidgets = [
    const AdminDashboard(),
    const UserManagement(),
    const ProductManagement(),
    const OrderManagement(),
    const PromotionManagement(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminScreenBloc>().loadAdminAccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminScreenBloc, AdminScreenState>(
      builder: (context, state) {
        if (state is AdminScreenError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ошибка доступа')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AdminScreenBloc>().loadAdminAccess();
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is AdminScreenLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Для всех остальных состояний
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
              _buildNavigationBar(context, state.selectedSection),
              // Основной контент
              _buildContent(state.selectedSection),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationBar(BuildContext context, int selectedSection) {
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
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sectionTitles.length,
        itemBuilder: (context, index) {
          final isSelected = selectedSection == index;
          return _buildNavItem(context, index, isSelected);
        },
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, bool isSelected) {
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

  Widget _buildContent(int selectedSection) {
    if (selectedSection < _sectionWidgets.length) {
      return Expanded(
        child: _sectionWidgets[selectedSection],
      );
    }
    
    return const Expanded(
      child: Center(child: Text('Раздел не найден')),
    );
  }

  void _onSectionChanged(BuildContext context, int sectionIndex) {
    context.read<AdminScreenBloc>().add(AdminScreenSectionChanged(sectionIndex));
  }
}