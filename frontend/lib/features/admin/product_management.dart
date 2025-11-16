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
  List<dynamic> _categories = [];
  List<dynamic> _tags = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final [products, categories, tags] = await Future.wait([
        ApiClient.getAdminProducts(includeInactive: true),
        ApiClient.getAdminCategories(),
        ApiClient.getAdminTags(),
      ]);
      
      setState(() {
        _products = products;
        _categories = categories;
        _tags = tags;
        _isLoading = false;
      });
      
      print('Loaded ${_products.length} products, ${_categories.length} categories, ${_tags.length} tags');
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Основной контент - товары
          Expanded(
            flex: 3,
            child: _buildProductsContent(),
          ),
          const SizedBox(width: 16),
          // Боковая панель с категориями и тегами
          Expanded(
            flex: 1,
            child: _buildSidebar(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsContent() {
    return Column(
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
                  : _buildProductsList(),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300, // Максимальная ширина карточки
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8, // Соотношение сторон карточки
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ProductCard(
          product: product,
          categories: _categories,
          tags: _tags,
          onEdit: () => _showEditProductDialog(product),
          onDelete: () => _deleteProduct(product['id']),
          onToggleActive: () => _updateProduct(
            product['id'],
            {'is_active': !product['is_active']},
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        // Категории
        Expanded(
          flex: 1,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Категории',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () => _showCreateCategoryDialog(),
                        tooltip: 'Добавить категорию',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _categories.isEmpty
                        ? const Center(child: Text('Категории не найдены'))
                        : ListView.builder(
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              return ListTile(
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  ),
                                  child: category['image_url'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(
                                            category['image_url'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.category,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.primary,
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.category,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                ),
                                title: Text(
                                  category['name'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16),
                                      onPressed: () => _showEditCategoryDialog(category),
                                      color: Colors.blue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16),
                                      onPressed: () => _deleteCategory(category['id']),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Теги
        Expanded(
          flex: 1,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Теги',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () => _showCreateTagDialog(),
                        tooltip: 'Добавить тег',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _tags.isEmpty
                        ? const Center(child: Text('Теги не найдены'))
                        : ListView.builder(
                            itemCount: _tags.length,
                            itemBuilder: (context, index) {
                              final tag = _tags[index];
                              return ListTile(
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.local_offer,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  tag['name'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${tag['products_count'] ?? 0} товаров',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16),
                                      onPressed: () => _showEditTagDialog(tag),
                                      color: Colors.blue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16),
                                      onPressed: () => _deleteTag(tag['id']),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Методы для работы с продуктами
  Future<void> _createProduct(Map<String, dynamic> productData) async {
    try {
      await ApiClient.createAdminProduct(productData);
      _loadData();
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
      _loadData();
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
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар удален')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  // Методы для работы с категориями
  Future<void> _createCategory(Map<String, dynamic> categoryData) async {
    try {
      await ApiClient.createAdminCategory(categoryData);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Категория создана')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка создания: $e')),
      );
    }
  }

  Future<void> _updateCategory(int categoryId, Map<String, dynamic> categoryData) async {
    try {
      await ApiClient.updateAdminCategory(categoryId, categoryData);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Категория обновлена')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления: $e')),
      );
    }
  }

  Future<void> _deleteCategory(int categoryId) async {
    try {
      await ApiClient.deleteAdminCategory(categoryId);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Категория удалена')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  // Методы для работы с тегами
  Future<void> _createTag(Map<String, dynamic> tagData) async {
    try {
      await ApiClient.createAdminTag(tagData);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тег создан')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка создания: $e')),
      );
    }
  }

  Future<void> _updateTag(int tagId, Map<String, dynamic> tagData) async {
    try {
      await ApiClient.updateAdminTag(tagId, tagData);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тег обновлен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления: $e')),
      );
    }
  }

  Future<void> _deleteTag(int tagId) async {
    try {
      await ApiClient.deleteAdminTag(tagId);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тег удален')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  // Диалоги
  void _showCreateProductDialog() {
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(
        categories: _categories,
        tags: _tags,
        onSave: _createProduct,
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(
        product: product,
        categories: _categories,
        tags: _tags,
        onSave: (productData) => _updateProduct(product['id'], productData),
      ),
    );
  }

  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        onSave: _createCategory,
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        category: category,
        onSave: (categoryData) => _updateCategory(category['id'], categoryData),
      ),
    );
  }

  void _showCreateTagDialog() {
    showDialog(
      context: context,
      builder: (context) => TagEditDialog(
        onSave: _createTag,
      ),
    );
  }

  void _showEditTagDialog(Map<String, dynamic> tag) {
    showDialog(
      context: context,
      builder: (context) => TagEditDialog(
        tag: tag,
        onSave: (tagData) => _updateTag(tag['id'], tagData),
      ),
    );
  }
}

// Карточка продукта
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final List<dynamic> categories;
  final List<dynamic> tags;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const ProductCard({
    super.key,
    required this.product,
    required this.categories,
    required this.tags,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final category = categories.firstWhere(
      (cat) => cat['id'] == product['category_id'],
      orElse: () => {'name': 'Не указана'},
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение продукта
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: product['image_url'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '${ApiClient.baseUrl}/images/products/${product['id']}/image',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.shopping_bag,
                            size: 40,
                            color: Colors.grey[400],
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.shopping_bag,
                      size: 40,
                      color: Colors.grey[400],
                    ),
            ),
            const SizedBox(height: 8),
            
            // Название и цена
            Row(
              children: [
                Expanded(
                  child: Text(
                    product['name'] ?? 'Без названия',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${product['price']} ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Категория и статус
            Text(
              category['name'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const SizedBox(height: 4),
            
            // Количество и статус
            Row(
              children: [
                Text(
                  '${product['stock_quantity']} шт.',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: product['is_active'] ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product['is_active'] ? 'Активен' : 'Неактивен',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Кнопки управления
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    product['is_active'] ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: product['is_active'] ? Colors.orange : Colors.green,
                  ),
                  onPressed: onToggleActive,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Диалог редактирования продукта
class ProductEditDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final List<dynamic> categories;
  final List<dynamic> tags;
  final Function(Map<String, dynamic>) onSave;

  const ProductEditDialog({
    super.key,
    this.product,
    required this.categories,
    required this.tags,
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
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _stockController.text = widget.product!['stock_quantity']?.toString() ?? '';
      _selectedCategoryId = widget.product!['category_id']?.toString();
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
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: widget.categories.map<DropdownMenuItem<String>>((category) {
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

// Диалог редактирования категории
class CategoryEditDialog extends StatefulWidget {
  final Map<String, dynamic>? category;
  final Function(Map<String, dynamic>) onSave;

  const CategoryEditDialog({
    super.key,
    this.category,
    required this.onSave,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!['name'] ?? '';
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
      title: Text(widget.category == null ? 'Добавить категорию' : 'Редактировать категорию'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название категории'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название категории';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
              final categoryData = {
                'name': _nameController.text,
              };
              widget.onSave(categoryData);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

// Диалог редактирования тега
class TagEditDialog extends StatefulWidget {
  final Map<String, dynamic>? tag;
  final Function(Map<String, dynamic>) onSave;

  const TagEditDialog({
    super.key,
    this.tag,
    required this.onSave,
  });

  @override
  State<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<TagEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _nameController.text = widget.tag!['name'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tag == null ? 'Добавить тег' : 'Редактировать тег'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название тега'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название тега';
                  }
                  return null;
                },
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
              final tagData = {
                'name': _nameController.text,
              };
              widget.onSave(tagData);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}