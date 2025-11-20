import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/profile/bloc/addresses_bloc.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddressesBloc()..add(LoadAddresses()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Мои адреса',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        body: const _AddressesContent(),
      ),
    );
  }
}

class _AddressesContent extends StatelessWidget {
  const _AddressesContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddressesBloc, AddressesState>(
      listener: (context, state) {
        if (state is AddressesError) {
          AppSnackbar.showError(context: context, message: state.message);
        }
      },
      builder: (context, state) {
        if (state is AddressesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AddressesLoaded) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.addresses.isNotEmpty) ...[
                ...state.addresses.map((address) => 
                  _buildAddressCard(context, address)),
                const SizedBox(height: 16),
              ],
              _buildAddAddressCard(context),
            ],
          );
        }

        if (state is AddressesError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Ошибка загрузки', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<AddressesBloc>().add(LoadAddresses()),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildAddressCard(BuildContext context, dynamic address) {
    final isDefault = address['is_default'] ?? false;
    
    return Card(
      elevation: 0,
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
            Icons.location_on,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          address['title'] ?? 'Адрес',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address['address_line'] ?? ''),
            if (address['city'] != null) 
              Text('г. ${address['city']}', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'По умолчанию',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (!isDefault) ...[
              IconButton(
                icon: Icon(Icons.star_outline, color: Colors.grey[600]),
                onPressed: () => context.read<AddressesBloc>().add(
                  SetDefaultAddress(address['id'])
                ),
                tooltip: 'Сделать адресом по умолчанию',
              ),
            ],
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[400]),
              onPressed: () => _showDeleteDialog(context, address),
              tooltip: 'Удалить адрес',
            ),
          ],
        ),
        onTap: () => _showEditAddressDialog(context, address),
      ),
    );
  }

  Widget _buildAddAddressCard(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          'Добавить новый адрес',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        subtitle: Text(
          'Нажмите чтобы добавить адрес доставки',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () => _showAddAddressDialog(context),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удаление адреса'),
          content: Text('Вы уверены, что хотите удалить адрес "${address['title'] ?? 'Адрес'}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AddressesBloc>().add(DeleteAddress(address['id']));
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddAddressDialog(BuildContext context) {
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Добавить адрес'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название (Дом, Работа...)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Адрес',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cityController,
                    decoration: const InputDecoration(
                      labelText: 'Город',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Сделать адресом по умолчанию'),
                    value: isDefault,
                    onChanged: (value) => setState(() => isDefault = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  if (titleController.text.isEmpty || addressController.text.isEmpty) {
                    AppSnackbar.showWarning(context: context, message: 'Заполните обязательные поля');
                    return;
                  }

                  context.read<AddressesBloc>().add(AddAddress({
                    'title': titleController.text,
                    'address_line': addressController.text,
                    'city': cityController.text.isEmpty ? null : cityController.text,
                    'is_default': isDefault,
                  }));

                  Navigator.of(context).pop();
                  AppSnackbar.showSuccess(context: context, message: 'Адрес добавлен');
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditAddressDialog(BuildContext context, dynamic address) {
    final titleController = TextEditingController(text: address['title']);
    final addressController = TextEditingController(text: address['address_line']);
    final cityController = TextEditingController(text: address['city'] ?? '');
    bool isDefault = address['is_default'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Редактировать адрес'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Адрес',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cityController,
                    decoration: const InputDecoration(
                      labelText: 'Город',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Адрес по умолчанию'),
                    value: isDefault,
                    onChanged: address['is_default'] == true 
                        ? null
                        : (value) => setState(() => isDefault = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  if (titleController.text.isEmpty || addressController.text.isEmpty) {
                    AppSnackbar.showWarning(context: context, message: 'Заполните обязательные поля');
                    return;
                  }

                  context.read<AddressesBloc>().add(UpdateAddress(
                    address['id'],
                    {
                      'title': titleController.text,
                      'address_line': addressController.text,
                      'city': cityController.text.isEmpty ? null : cityController.text,
                      'is_default': isDefault,
                    },
                  ));

                  Navigator.of(context).pop();
                  AppSnackbar.showInfo(context: context, message: 'Адрес обновлен');
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }
}