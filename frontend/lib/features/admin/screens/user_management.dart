import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/admin/bloc/user_management_bloc.dart';
import 'package:client/data/repositories/user_management_repository_impl.dart';
import 'package:client/domain/entities/user_entity.dart';

class UserManagement extends StatelessWidget {
  const UserManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserManagementBloc(
        repository: UserManagementRepositoryImpl(),
      )..add(const LoadUsers()),
      child: const _UserManagementView(),
    );
  }
}

class _UserManagementView extends StatelessWidget {
  const _UserManagementView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserManagementBloc, UserManagementState>(
      listener: (context, state) {
        if (state is UserManagementError) {
          AppSnackbar.showError(context: context, message: state.message);
        } else if (state is UserManagementOperationSuccess) {
          AppSnackbar.showInfo(context: context, message: state.message);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<UserManagementBloc, UserManagementState>(
      builder: (context, state) {
        if (state is UserManagementLoaded) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Управление пользователями',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Всего: ${state.totalUsers} | Активных: ${state.activeUsersCount}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          );
        }
        return Text(
          'Управление пользователями',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return BlocBuilder<UserManagementBloc, UserManagementState>(
      builder: (context, state) {
        if (state is UserManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is UserManagementError) {
          return Center(
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
                    context.read<UserManagementBloc>().add(const LoadUsers());
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        } else if (state is UserManagementLoaded) {
          return _buildUsersList(context, state.users);
        } else {
          return const Center(child: Text('Загрузка...'));
        }
      },
    );
  }

  Widget _buildUsersList(BuildContext context, List<UserEntity> users) {
    if (users.isEmpty) {
      return const Center(child: Text('Пользователи не найдены'));
    }

    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return UserCard(
            user: user,
            onBlock: user.isActive! ? () => _blockUser(context, user.id) : null,
            onUnblock: !user.isActive! ? () => _unblockUser(context, user.id) : null,
            onChangeRole: (newRole) => _changeUserRole(context, user.id, newRole),
          );
        },
      ),
    );
  }

  void _blockUser(BuildContext context, int userId) {
    context.read<UserManagementBloc>().add(BlockUser(userId));
  }

  void _unblockUser(BuildContext context, int userId) {
    context.read<UserManagementBloc>().add(UnblockUser(userId));
  }

  void _changeUserRole(BuildContext context, int userId, String newRole) {
    context.read<UserManagementBloc>().add(ChangeUserRole(
      userId: userId,
      newRole: newRole,
    ));
  }
}

class UserCard extends StatelessWidget {
  final UserEntity user;
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.isActive! ? Colors.green : Colors.red,
                  child: Text(
                    user.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Информация о роли и статусе
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Роль: ${user.role ?? 'user'}',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  user.isActive! ? 'Активен' : 'Заблокирован',
                  style: TextStyle(
                    color: user.isActive! ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (user.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Телефон: ${user.phone}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            
            const Spacer(),
            
            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Смена роли
                PopupMenuButton<String>(
                  icon: const Icon(Icons.admin_panel_settings, size: 20),
                  onSelected: (role) => onChangeRole(role),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'user', child: Text('Пользователь')),
                    const PopupMenuItem(value: 'admin', child: Text('Администратор')),
                    const PopupMenuItem(value: 'moderator', child: Text('Модератор')),
                  ],
                ),
                
                // Блокировка/разблокировка
                if (onBlock != null)
                  IconButton(
                    icon: const Icon(Icons.block, color: Colors.red, size: 20),
                    onPressed: onBlock,
                    tooltip: 'Заблокировать',
                  ),
                if (onUnblock != null)
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    onPressed: onUnblock,
                    tooltip: 'Разблокировать',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}