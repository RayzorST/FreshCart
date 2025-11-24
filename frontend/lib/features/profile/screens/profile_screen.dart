import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/features/profile/bloc/profile_bloc.dart';
import 'package:client/features/auth/bloc/auth_bloc.dart';
import 'package:client/core/widgets/product_modal.dart';
import 'package:client/features/profile/screens/order_history_screen.dart';
import 'package:client/features/profile/screens/help_screen.dart';
import 'package:client/features/profile/screens/settings_screen.dart';
import 'package:client/features/profile/screens/addresses_screen.dart';

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
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _WideProfileLayout(user: state.user, orders: state.orders);
          } else {
            return _NarrowProfileLayout(user: state.user, orders: state.orders);
          }
        },
      );
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

class _NarrowProfileLayout extends StatelessWidget {
  final Map<String, dynamic> user;
  final List<dynamic> orders;

  const _NarrowProfileLayout({required this.user, required this.orders});

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
                title: 'Мои блюда',
                subtitle: '0 заказов',
                icon: Icons.fastfood,
                onTap: () => context.push('/analysis/history'),
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
              color: Theme.of(context).colorScheme.primary,
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
                  color: Colors.white,
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
                  color: Colors.white,
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

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
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
      color: Theme.of(context).colorScheme.surface,
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

  void _showLogoutDialog(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>(); 
    
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
                profileBloc.add(Logout()); 
              },
              child: const Text('Выйти', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class _WideProfileLayout extends StatelessWidget {
  final Map<String, dynamic> user;
  final List<dynamic> orders;

  const _WideProfileLayout({required this.user, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSidebar(context),
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(context),
                    const SizedBox(height: 32),
                    _buildActionsGrid(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSidebar(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Имя и email
          Text(
            _getDisplayName(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            user['email']?.toString() ?? 'email@example.com',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          _buildStatCard(
            context,
            title: 'Активные заказы',
            value: '0',
            icon: Icons.pending_actions,
            color: Colors.blue,
          ),
          const SizedBox(width: 20),
          _buildStatCard(
            context,
            title: 'Всего заказов',
            value: '${orders.length}',
            icon: Icons.shopping_bag,
            color: Colors.green,
          ),
          const SizedBox(width: 20),
          _buildStatCard(
            context,
            title: 'С нами',
            value: _getMemberSince(),
            icon: Icons.calendar_today,
            color: Colors.orange,
          ),
          
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
              ),
              icon: Icon(Icons.logout, size: 20, color: Colors.red[400]),
              label: Text(
                'Выйти из аккаунта',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Добро пожаловать!',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Управляйте вашим аккаунтом и заказами',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.4,
          children: [
            _buildActionCard(
              context,
              title: 'Мои заказы',
              subtitle: '${orders.length} заказов',
              icon: Icons.history,
              color: Colors.purple,
              onTap: () => ScreenToModal.show(context: context, child: OrderHistoryScreen()),
            ),
            _buildActionCard(
              context,
              title: 'Мои блюда',
              subtitle: 'Анализ питания',
              icon: Icons.restaurant,
              color: Colors.green,
              onTap: () => context.push('/analysis/history'),
            ),
            _buildActionCard(
              context,
              title: 'Адреса',
              subtitle: 'Управление адресами',
              icon: Icons.location_on,
              color: Colors.blue,
              onTap: () => ScreenToModal.show(context: context, child: AddressesScreen()),
            ),
            _buildActionCard(
              context,
              title: 'Настройки',
              subtitle: 'Персональные настройки',
              icon: Icons.settings,
              color: Colors.orange,
              onTap: () => ScreenToModal.show(context: context, child: SettingsScreen()),
            ),
            _buildActionCard(
              context,
              title: 'Помощь',
              subtitle: 'FAQ и поддержка',
              icon: Icons.help_center,
              color: Colors.red,
              onTap: () => ScreenToModal.show(context: context, child: HelpScreen()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Открыть',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  void _showLogoutDialog(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>(); 
    
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
                profileBloc.add(Logout()); 
              },
              child: const Text('Выйти', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}