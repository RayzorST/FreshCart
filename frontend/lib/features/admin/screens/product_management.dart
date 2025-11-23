// product_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:client/api/client.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/admin/bloc/product_management_bloc.dart';

class ProductManagement extends StatelessWidget {
  const ProductManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductManagementBloc()..add(const LoadProductData()),
      child: const _ProductManagementView(),
    );
  }
}

class _ProductManagementView extends StatelessWidget {
  const _ProductManagementView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductManagementBloc, ProductManagementState>(
      listener: (context, state) {
        if (state is ProductManagementError) {
          AppSnackbar.showError(context: context, message: state.message);
        } else if (state is ProductManagementOperationSuccess) {
          AppSnackbar.showInfo(context: context, message: state.message);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основной контент - товары
            Expanded(
              flex: 3,
              child: _buildProductsContent(context),
            ),
            const SizedBox(width: 16),
            // Боковая панель с категориями и тегами
            Expanded(
              flex: 1,
              child: _buildSidebar(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsContent(BuildContext context) {
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
              onPressed: () => _showCreateProductDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Добавить товар'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BlocBuilder<ProductManagementBloc, ProductManagementState>(
            builder: (context, state) {
              if (state is ProductManagementLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ProductManagementLoaded) {
                return _buildProductsList(context, state.products, state.categories, state.tags);
              } else if (state is ProductManagementError) {
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
                          context.read<ProductManagementBloc>().add(const LoadProductData());
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(child: Text('Загрузка...'));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList(BuildContext context, List<dynamic> products, List<dynamic> categories, List<dynamic> tags) {
    if (products.isEmpty) {
      return const Center(child: Text('Товары не найдены'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          categories: categories,
          tags: tags,
          onEdit: () => _showEditProductDialog(context, product, categories, tags),
          onDelete: () => _deleteProduct(context, product['id']),
          onToggleActive: () => _toggleProductActive(context, product['id'], !product['is_active']),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return BlocBuilder<ProductManagementBloc, ProductManagementState>(
      builder: (context, state) {
        if (state is! ProductManagementLoaded) {
          return const SizedBox();
        }

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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith( // Добавлен context
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: () => _showCreateCategoryDialog(context),
                            tooltip: 'Добавить категорию',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: state.categories.isEmpty
                            ? const Center(child: Text('Категории не найдены'))
                            : ListView.builder(
                                itemCount: state.categories.length,
                                itemBuilder: (context, index) {
                                  final category = state.categories[index];
                                  return ListTile(
                                    leading: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1), // Добавлен context
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
                                                    color: Theme.of(context).colorScheme.primary, // Добавлен context
                                                  );
                                                },
                                              ),
                                            )
                                          : Icon(
                                              Icons.category,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary, // Добавлен context
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
                                          onPressed: () => _showEditCategoryDialog(context, category),
                                          color: Colors.blue,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 16),
                                          onPressed: () => _deleteCategory(context, category['id']),
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith( // Добавлен context
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: () => _showCreateTagDialog(context),
                            tooltip: 'Добавить тег',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: state.tags.isEmpty
                            ? const Center(child: Text('Теги не найдены'))
                            : ListView.builder(
                                itemCount: state.tags.length,
                                itemBuilder: (context, index) {
                                  final tag = state.tags[index];
                                  return ListTile(
                                    leading: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1), // Добавлен context
                                      ),
                                      child: Icon(
                                        Icons.local_offer,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary, // Добавлен context
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
                                          onPressed: () => _showEditTagDialog(context, tag),
                                          color: Colors.blue,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 16),
                                          onPressed: () => _deleteTag(context, tag['id']),
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
      },
    );
  }

  // Методы для работы с продуктами
  void _showCreateProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(
        categories: _getCategoriesFromState(context),
        tags: _getTagsFromState(context),
        onSave: (productData) {
          context.read<ProductManagementBloc>().add(CreateProduct(productData));
        },
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Map<String, dynamic> product, List<dynamic> categories, List<dynamic> tags) {
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(
        product: product,
        categories: categories,
        tags: tags,
        onSave: (productData) {
          context.read<ProductManagementBloc>().add(UpdateProduct(
            productId: product['id'],
            productData: productData,
          ));
        },
      ),
    );
  }

  void _deleteProduct(BuildContext context, int productId) {
    context.read<ProductManagementBloc>().add(DeleteProduct(productId));
  }

  void _toggleProductActive(BuildContext context, int productId, bool isActive) {
    context.read<ProductManagementBloc>().add(ToggleProductActive(
      productId: productId,
      isActive: isActive,
    ));
  }

  void _showCreateCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        onSave: (categoryData) {
          context.read<ProductManagementBloc>().add(CreateCategory(categoryData));
        },
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        category: category,
        onSave: (categoryData) {
          context.read<ProductManagementBloc>().add(UpdateCategory(
            categoryId: category['id'],
            categoryData: categoryData,
          ));
        },
      ),
    );
  }

  void _deleteCategory(BuildContext context, int categoryId) {
    context.read<ProductManagementBloc>().add(DeleteCategory(categoryId));
  }

  void _showCreateTagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TagEditDialog(
        onSave: (tagData) {
          context.read<ProductManagementBloc>().add(CreateTag(tagData));
        },
      ),
    );
  }

  void _showEditTagDialog(BuildContext context, Map<String, dynamic> tag) {
    showDialog(
      context: context,
      builder: (context) => TagEditDialog(
        tag: tag,
        onSave: (tagData) {
          context.read<ProductManagementBloc>().add(UpdateTag(
            tagId: tag['id'],
            tagData: tagData,
          ));
        },
      ),
    );
  }

  void _deleteTag(BuildContext context, int tagId) {
    context.read<ProductManagementBloc>().add(DeleteTag(tagId));
  }

  List<dynamic> _getCategoriesFromState(BuildContext context) {
    final state = context.read<ProductManagementBloc>().state;
    return state is ProductManagementLoaded ? state.categories : [];
  }

  List<dynamic> _getTagsFromState(BuildContext context) {
    final state = context.read<ProductManagementBloc>().state;
    return state is ProductManagementLoaded ? state.tags : [];
  }
}

// Карточка продукта (остается без изменений)
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

// Диалог редактирования продукта (остается без изменений)
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

// Диалог редактирования категории (остается без изменений)
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

// Диалог редактирования тега (остается без изменений)
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