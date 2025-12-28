import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/admin/bloc/product_management_bloc.dart';
import 'package:client/data/repositories/product_management_repository_impl.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/entities/category_entity.dart';
import 'package:client/domain/entities/tag_entity.dart';
import 'package:client/core/widgets/product_edit_dialog.dart';
import 'package:image_picker/image_picker.dart';

class ProductManagement extends StatelessWidget {
  const ProductManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductManagementBloc(
        repository: ProductManagementRepositoryImpl(),
      )..add(const LoadProductData()),
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
            Expanded(
              flex: 3,
              child: _buildProductsContent(context),
            ),
            const SizedBox(width: 16),
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
            BlocBuilder<ProductManagementBloc, ProductManagementState>(
              builder: (context, state) {
                if (state is ProductManagementLoaded) {
                  return ElevatedButton.icon(
                    onPressed: () => _showCreateProductDialog(
                      context, 
                      state.categories, 
                      state.tags
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить товар'),
                  );
                } else {
                  return ElevatedButton.icon(
                    onPressed: () {
                      // Можно показать загрузку или сообщение
                      AppSnackbar.showInfo(
                        context: context, 
                        message: 'Загрузка данных...'
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить товар'),
                  );
                }
              },
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
                return _buildProductsList(
                  context, 
                  state.products, 
                  state.categories, 
                  state.tags
                );
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

  Widget _buildProductsList(BuildContext context, List<ProductEntity> products, List<CategoryEntity> categories, List<TagEntity> tags) {
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
          onDelete: () => _deleteProduct(context, product.id),
          onToggleActive: () => _toggleProductActive(context, product.id, !product.isActive),
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          category.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.category,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      category.name,
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
                                          onPressed: () => _deleteCategory(context, category.id),
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
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        Icons.local_offer,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    title: Text(
                                      tag.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      '${tag.productCount ?? 0} товаров',
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
                                          onPressed: () => _deleteTag(context, tag.id),
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
  void _showCreateProductDialog(BuildContext context, List<CategoryEntity> categories, List<TagEntity> tags) {
    final productBloc = context.read<ProductManagementBloc>();

    if (productBloc.state is ProductManagementLoaded) {
      showDialog(
        context: context,
        builder: (context) => ProductEditDialog(
          categories: categories,
          tags: tags,
          bloc: productBloc,
        ),
      );
    }
  }

  void _showEditProductDialog(BuildContext context, ProductEntity product, List<CategoryEntity> categories, List<TagEntity> tags) {
    final productBloc = context.read<ProductManagementBloc>();

    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(
        product: product,
        categories: categories,
        tags: tags,
        bloc: productBloc,
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
    final bloc = context.read<ProductManagementBloc>();
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(bloc: bloc),
    );
  }

  void _showEditCategoryDialog(BuildContext context, CategoryEntity category) {
    final bloc = context.read<ProductManagementBloc>();
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        category: category,
        bloc: bloc,
      ),
    );
  }

  void _deleteCategory(BuildContext context, int categoryId) {
    context.read<ProductManagementBloc>().add(DeleteCategory(categoryId));
  }

  void _showCreateTagDialog(BuildContext context) {
    final productBloc = context.read<ProductManagementBloc>();

    showDialog(
      context: context,
      builder: (context) => TagEditDialog(
        onSave: (tagData) {
          productBloc.add(CreateTag(tagData));
        },
      ),
    );
  }

  void _showEditTagDialog(BuildContext context, TagEntity tag) {
    final productBloc = context.read<ProductManagementBloc>();

    showDialog(
      context: context,
      builder: (context) => TagEditDialog(
        tag: tag,
        onSave: (tagData) {
          productBloc.add(UpdateTag(
            tagId: tag.id,
            tagData: tagData,
          ));
        },
      ),
    );
  }

  void _deleteTag(BuildContext context, int tagId) {
    context.read<ProductManagementBloc>().add(DeleteTag(tagId));
  }
}

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final List<CategoryEntity> categories;
  final List<TagEntity> tags;
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
    final categoryName = product.category?.name ?? 'Не указана';
    
    final productTags = product.tags;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.shopping_bag,
                      size: 40,
                      color: Colors.grey[400],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${product.price} ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Text(
              categoryName,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const SizedBox(height: 4),

            if (productTags.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 28,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: productTags.length,
                      itemBuilder: (context, index) {
                        final tag = productTags[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Text(
                            tag.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            
            // Количество и статус
            Row(
              children: [
                Text(
                  '${product.stockQuantity ?? 0} шт.',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: product.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.isActive ? 'Активен' : 'Неактивен',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    product.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: product.isActive ? Colors.orange : Colors.green,
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


class CategoryEditDialog extends StatefulWidget {
  final CategoryEntity? category;
  final ProductManagementBloc bloc;

  const CategoryEditDialog({
    super.key,
    this.category,
    required this.bloc,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Uint8List? _imageBytes; // Изменим с File на Uint8List для веба
  String? _imageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      AppSnackbar.showError(
        context: context, 
        message: 'Ошибка выбора изображения: $e'
      );
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Сохраняем категорию
      final categoryData = {'name': _nameController.text};
      
      if (widget.category == null) {
        // Создаем новую категорию
        widget.bloc.add(CreateCategory(categoryData));
        AppSnackbar.showInfo(context: context, message: 'Категория создана');
      } else {
        // Обновляем существующую категорию
        widget.bloc.add(UpdateCategory(
          categoryId: widget.category!.id,
          categoryData: categoryData,
        ));
      }

      // 2. Если есть изображение - загружаем его
      if (_imageBase64 != null && widget.category != null) {
        widget.bloc.add(UploadCategoryImage(
          categoryId: widget.category!.id,
          base64Image: _imageBase64,
        ));
      }

      // 3. Закрываем диалог
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });

    } catch (e) {
      AppSnackbar.showError(context: context, message: 'Ошибка: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                decoration: const InputDecoration(
                  labelText: 'Название категории',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Изображение
              if (_imageBytes != null)
                Column(
                  children: [
                    Image.memory(_imageBytes!, height: 100), // Используем Image.memory для веба
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Изменить изображение'),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}

class TagEditDialog extends StatefulWidget {
  final TagEntity? tag;
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
      _nameController.text = widget.tag!.name;
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