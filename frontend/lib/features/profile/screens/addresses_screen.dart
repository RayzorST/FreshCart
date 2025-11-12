import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  List<dynamic>? _addresses;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await ApiClient.getAddresses();
      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefaultAddress(int addressId) async {
    try {
      await ApiClient.setDefaultAddress(addressId);
      await _loadAddresses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Адрес установлен по умолчанию')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _deleteAddress(int addressId) async {
    try {
      await ApiClient.deleteAddress(addressId);
      await _loadAddresses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Адрес удален')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _showDeleteDialog(int addressId, String addressTitle) {
    showDialog(
      context: context,
      barrierColor: Colors.grey.withOpacity(0.2),
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удаление адреса'),
          content: Text('Вы уверены, что хотите удалить адрес "$addressTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAddress(addressId);
              },
              child: const Text(
                'Удалить',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои адреса'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_addresses != null && _addresses!.isNotEmpty) ...[
          ..._addresses!.map((address) => _buildAddressCard(context, address)),
          const SizedBox(height: 16),
        ],
        _buildAddAddressCard(context),
      ],
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
                icon: Icon(
                  Icons.star_outline,
                  color: Colors.grey[600],
                ),
                onPressed: () => _setDefaultAddress(address['id']),
                tooltip: 'Сделать адресом по умолчанию',
              ),
            ],
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red[400],
              ),
              onPressed: () => _showDeleteDialog(
                address['id'],
                address['title'] ?? 'Адрес',
              ),
              tooltip: 'Удалить адрес',
            ),
          ],
        ),
        onTap: () {
          _showEditAddressDialog(address);
        },
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
        onTap: () {
          _showAddAddressDialog();
        },
      ),
    );
  }

  void _showAddAddressDialog() {
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      barrierColor: Colors.grey.withOpacity(0.2),
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
                    onChanged: (value) {
                      setState(() => isDefault = value ?? false);
                    },
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
                onPressed: () async {
                  if (titleController.text.isEmpty || addressController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Заполните обязательные поля')),
                    );
                    return;
                  }

                  try {
                    await ApiClient.createAddress({
                      'title': titleController.text,
                      'address_line': addressController.text,
                      'city': cityController.text.isEmpty ? null : cityController.text,
                      'is_default': isDefault,
                    });
                    
                    Navigator.of(context).pop();
                    await _loadAddresses();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Адрес добавлен')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditAddressDialog(dynamic address) {
    final titleController = TextEditingController(text: address['title']);
    final addressController = TextEditingController(text: address['address_line']);
    final cityController = TextEditingController(text: address['city'] ?? '');
    bool isDefault = address['is_default'] ?? false;

    showDialog(
      context: context,
      barrierColor: Colors.grey.withOpacity(0.2),
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
                        : (value) {
                            setState(() => isDefault = value ?? false);
                          },
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
                onPressed: () async {
                  if (titleController.text.isEmpty || addressController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Заполните обязательные поля')),
                    );
                    return;
                  }

                  try {
                    await ApiClient.updateAddress(address['id'], {
                      'title': titleController.text,
                      'address_line': addressController.text,
                      'city': cityController.text.isEmpty ? null : cityController.text,
                      'is_default': isDefault,
                    });
                    
                    Navigator.of(context).pop();
                    await _loadAddresses();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Адрес обновлен')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
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