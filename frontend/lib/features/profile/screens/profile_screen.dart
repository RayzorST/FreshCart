import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/features/profile/bloc/profile_bloc.dart';
import 'package:client/features/auth/bloc/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc()..add(LoadProfile()),
      child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            BlocListener<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state is LogoutSuccess) {
                  context.read<AuthBloc>().add(LoggedOut());
                  context.go('/login');
                }
              },
            ),
          ],
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return _buildContent(context, state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProfileState state) {
    if (state is ProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ProfileLoaded) {
      return _ProfileContent(user: state.user, orders: state.orders);
    }

    if (state is ProfileError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ProfileBloc>().add(LoadProfile()),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}

class _ProfileContent extends StatelessWidget {
  final Map<String, dynamic> user;
  final List<dynamic> orders;

  const _ProfileContent({required this.user, required this.orders});

  String _getInitials() {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    return (user['username']?[0] ?? 'U').toString().toUpperCase();
  }

  String _getDisplayName() {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return user['username']?.toString() ?? 'Пользователь';
  }

  String _getMemberSince() {
    final createdAt = user['created_at'];
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(date);
        
        if (difference.inDays < 30) return '${difference.inDays} д.';
        if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} мес.';
        return '${(difference.inDays / 365).floor()} г.';
      } catch (e) {
        return 'Недавно';
      }
    }
    return 'Недавно';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProfileHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionCard(
                context,
                title: 'Мои заказы',
                subtitle: '${orders.length} заказов',
                icon: Icons.shopping_bag,
                onTap: () => context.push('/order-history'),
              ),
              _buildSectionCard(
                context,
                title: 'Адреса доставки',
                subtitle: 'Управление адресами',
                icon: Icons.location_on,
                onTap: () => context.push('/addresses'),
              ),
              _buildSectionCard(
                context,
                title: 'Настройки',
                subtitle: 'Персональные настройки',
                icon: Icons.settings,
                onTap: () => context.push('/settings'),
              ),
              _buildSectionCard(
                context,
                title: 'Помощь и поддержка',
                subtitle: 'FAQ и контакты',
                icon: Icons.help,
                onTap: () => context.push('/help'),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.red.withOpacity(0.05),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red[400]),
                  title: Text(
                    'Выйти из аккаунта',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _showLogoutDialog(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getDisplayName(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            user['email']?.toString() ?? 'email@example.com',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, '${orders.length}', 'Заказов'),
              _buildStatItem(context, _getMemberSince(), 'С нами'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, 
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Сменить пароль'),
          content: const Text('Эта функция будет доступна в следующем обновлении.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>(); // Получить до диалога
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход из аккаунта'),
          content: const Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                profileBloc.add(Logout()); // Использовать сохраненный bloc
              },
              child: const Text('Выйти', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}