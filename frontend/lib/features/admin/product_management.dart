// product_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:client/api/client.dart';

class ProductManagement extends ConsumerStatefulWidget {
  const ProductManagement({super.key});

  @override
  ConsumerState<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends ConsumerState<ProductManagement> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ApiClient.getAdminProducts(includeInactive: true);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createProduct(Map<String, dynamic> productData) async {
    try {
      await ApiClient.createAdminProduct(productData);
      _loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар создан')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка создания: $e')),
      );
    }
  }

  Future<void> _updateProduct(int productId, Map<String, dynamic> productData) async {
    try {
      await ApiClient.updateAdminProduct(productId, productData);
      _loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар обновлен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления: $e')),
      );
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      await ApiClient.deleteAdminProduct(productId);
      _loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар удален')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Управление товарами',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Добавить товар'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('Товары не найдены'))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ProductCard(
                            product: product,
                            onEdit: () => _showEditProductDialog(product),
                            onDelete: () => _deleteProduct(product['id']),
                            onToggleActive: () => _updateProduct(
                              product['id'],
                              {'is_active': !product['is_active']},
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showCreateProductDialog() {
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(
        onSave: _createProduct,
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(
        product: product,
        onSave: (productData) => _updateProduct(product['id'], productData),
      ),
    );
  }
}

// ProductCard и ProductEditDialog остаются примерно такими же, 
// но теперь используют реальные данные из API

// product_management.dart (продолжение)

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onToggleActive;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: product['image_url'] != null
            ? Image.network(
                product['image_url'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.shopping_bag, size: 40);
                },
              )
            : const Icon(Icons.shopping_bag, size: 40),
        title: Text(product['name'] ?? 'Без названия'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Цена: ${product['price']} ₽'),
            Text('В наличии: ${product['stock_quantity']} шт.'),
            Text('Категория: ${product['category']?['name'] ?? 'Не указана'}'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: product['is_active'] ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product['is_active'] ? 'Активен' : 'Неактивен',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggleActive != null)
              IconButton(
                icon: Icon(
                  product['is_active'] ? Icons.visibility_off : Icons.visibility,
                  color: product['is_active'] ? Colors.orange : Colors.green,
                ),
                onPressed: onToggleActive,
                tooltip: product['is_active'] ? 'Деактивировать' : 'Активировать',
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              color: Colors.blue,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class ProductEditDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final Function(Map<String, dynamic>) onSave;

  const ProductEditDialog({
    super.key,
    this.product,
    required this.onSave,
  });

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _stockController.text = widget.product!['stock_quantity']?.toString() ?? '';
      _selectedCategoryId = widget.product!['category_id']?.toString();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiClient.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Добавить товар' : 'Редактировать товар'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название товара'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название товара';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Цена'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите цену';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректную цену';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Количество на складе'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите количество';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Введите корректное количество';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Выбор категории
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: _categories.map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'].toString(),
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите категорию';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Загрузка изображения
              _imageFile != null
                  ? Column(
                      children: [
                        Image.file(_imageFile!, height: 100),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _pickImage,
                          child: const Text('Изменить изображение'),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Загрузить изображение'),
                    ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final productData = {
                'name': _nameController.text,
                'description': _descriptionController.text,
                'price': double.parse(_priceController.text),
                'stock_quantity': int.parse(_stockController.text),
                'category_id': int.parse(_selectedCategoryId!),
                'is_active': true,
              };
              
              // TODO: Добавить загрузку изображения когда будет готов эндпоинт
              widget.onSave(productData);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}