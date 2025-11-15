// user_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';

class UserManagement extends ConsumerStatefulWidget {
  const UserManagement({super.key});

  @override
  ConsumerState<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends ConsumerState<UserManagement> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ApiClient.getAdminUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _blockUser(int userId) async {
    try {
      await ApiClient.blockUser(userId);
      _loadUsers(); // Перезагружаем список
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь заблокирован')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _unblockUser(int userId) async {
    try {
      await ApiClient.unblockUser(userId);
      _loadUsers(); // Перезагружаем список
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь разблокирован')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _changeUserRole(int userId, String newRole) async {
    try {
      await ApiClient.setUserRole(userId, newRole);
      _loadUsers(); // Перезагружаем список
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Роль изменена на $newRole')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Управление пользователями',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('Пользователи не найдены'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return UserCard(
                            user: user,
                            onBlock: user['is_active'] ? () => _blockUser(user['id']) : null,
                            onUnblock: !user['is_active'] ? () => _unblockUser(user['id']) : null,
                            onChangeRole: (newRole) => _changeUserRole(user['id'], newRole),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onBlock;
  final VoidCallback? onUnblock;
  final Function(String) onChangeRole;

  const UserCard({
    super.key,
    required this.user,
    this.onBlock,
    this.onUnblock,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user['is_active'] ? Colors.green : Colors.red,
          child: Text(
            user['first_name']?.toString().substring(0, 1) ?? 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('${user['first_name']} ${user['last_name']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email']),
            Text('Роль: ${user['role']?['name'] ?? 'user'}'),
            Text(
              user['is_active'] ? 'Активен' : 'Заблокирован',
              style: TextStyle(
                color: user['is_active'] ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Смена роли
            PopupMenuButton<String>(
              icon: const Icon(Icons.admin_panel_settings),
              onSelected: (role) => onChangeRole(role),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'user', child: Text('Пользователь')),
                const PopupMenuItem(value: 'admin', child: Text('Администратор')),
                const PopupMenuItem(value: 'moderator', child: Text('Модератор')),
              ],
            ),
            const SizedBox(width: 8),
            // Блокировка/разблокировка
            if (onBlock != null)
              IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: onBlock,
                tooltip: 'Заблокировать',
              ),
            if (onUnblock != null)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: onUnblock,
                tooltip: 'Разблокировать',
              ),
          ],
        ),
      ),
    );
  }
}