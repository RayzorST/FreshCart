import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/api/client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _userData;
  List<dynamic>? _orders;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await ApiClient.getProfile();
      final orders = await ApiClient.getMyOrders();
      
      setState(() {
        _userData = user;
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getInitials() {
    if (_userData == null) return 'U';
    final firstName = _userData!['first_name'] ?? '';
    final lastName = _userData!['last_name'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    return _userData!['username'][0].toUpperCase();
  }

  String _getDisplayName() {
    if (_userData == null) return 'Пользователь';
    final firstName = _userData!['first_name'] ?? '';
    final lastName = _userData!['last_name'] ?? '';
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return _userData!['username'];
  }

  int _getOrdersCount() {
    return _orders?.length ?? 0;
  }

  String _getMemberSince() {
    if (_userData == null) return 'Недавно';
    final createdAt = _userData!['created_at'];
    if (createdAt != null) {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays < 30) return '${difference.inDays} д.';
      if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} мес.';
      return '${(difference.inDays / 365).floor()} г.';
    }
    return 'Недавно';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Шапка профиля
                _buildProfileHeader(context),
                
                // Основной контент
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // История заказов
                      _buildSectionCard(
                        context,
                        title: 'Мои заказы',
                        subtitle: '${_getOrdersCount()} заказов',
                        icon: Icons.shopping_bag,
                        onTap: () {
                          context.push('/order-history');
                        },
                      ),
                      
                      // Адреса доставки
                      _buildSectionCard(
                        context,
                        title: 'Адреса доставки',
                        subtitle: 'Управление адресами',
                        icon: Icons.location_on,
                        onTap: () {
                          context.push('/addresses');
                        },
                      ),
                      
                      // Настройки
                      _buildSectionCard(
                        context,
                        title: 'Настройки',
                        subtitle: 'Персональные настройки',
                        icon: Icons.settings,
                        onTap: () {
                          context.push('/settings');
                        },
                      ),
                      
                      // Помощь
                      _buildSectionCard(
                        context,
                        title: 'Помощь и поддержка',
                        subtitle: 'FAQ и контакты',
                        icon: Icons.help,
                        onTap: () {
                          context.push('/help');
                        },
                      ),
                      
                      // Выйти
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: Colors.red[400],
                          ),
                          title: Text(
                            'Выйти из аккаунта',
                            style: TextStyle(
                              color: Colors.red[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            _showLogoutDialog(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          // Аватар с инициалами
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
          
          // Имя
          Text(
            _getDisplayName(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Email
          Text(
            _userData?['email'] ?? 'email@example.com',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Статистика
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, '${_getOrdersCount()}', 'Заказов'),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход из аккаунта'),
          content: const Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                // Очищаем токен и переходим на логин
                ApiClient.setToken("");
                Navigator.of(context).pop();
                context.go('/login');
              },
              child: const Text(
                'Выйти', 
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}