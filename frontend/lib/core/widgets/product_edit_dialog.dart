// product_edit_dialog.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/entities/category_entity.dart';
import 'package:client/domain/entities/tag_entity.dart';
import 'package:client/features/admin/bloc/product_management_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';

class ProductEditDialog extends StatefulWidget {
  final ProductEntity? product;
  final List<CategoryEntity> categories;
  final List<TagEntity> tags;
  final ProductManagementBloc bloc;

  const ProductEditDialog({
    super.key,
    this.product,
    required this.categories,
    required this.tags,
    required this.bloc,
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
  
  Uint8List? _imageBytes;
  String? _imageBase64;
  bool _isLoading = false;
  
  int? _selectedCategoryId;
  final List<TagEntity> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stockQuantity?.toString() ?? '0';
      _selectedCategoryId = widget.product!.categoryId;
      _selectedTags.addAll(widget.product!.tags);
    }
  }

  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        
        reader.onLoadEnd.listen((e) async {
          setState(() {
            _imageBytes = reader.result as Uint8List;
            _imageBase64 = base64Encode(_imageBytes!);
          });
        });
        
        reader.readAsArrayBuffer(file);
      }
    });
    
    uploadInput.click();
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageBase64 = null;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      AppSnackbar.showError(context: context, message: 'Выберите категорию');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
        'price': double.parse(_priceController.text),
        'stock_quantity': int.parse(_stockController.text),
        'category_id': _selectedCategoryId!,
        'tag_ids': _selectedTags.isNotEmpty 
            ? _selectedTags.map((tag) => tag.id).toList() 
            : null,
        'is_active': true,
      };

      if (widget.product == null) {
        widget.bloc.add(CreateProduct(productData));

        AppSnackbar.showInfo(
          context: context, 
          message: 'Товар создается...'
        );
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.of(context).pop();
        });
      
        
      } else {
        widget.bloc.add(UpdateProduct(
          productId: widget.product!.id,
          productData: productData,
        ));

        if (_imageBase64 != null) {
          widget.bloc.add(UploadProductImage(
            productId: widget.product!.id,
            base64Image: _imageBase64,
          ));
        }
        
        AppSnackbar.showInfo(
          context: context, 
          message: 'Товар обновляется...'
        );
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.of(context).pop();
        });
      }

    } catch (e) {
      AppSnackbar.showError(context: context, message: 'Ошибка: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Widget _buildTagsSelector() {
    return Card(
      elevation: 1,
      child: ExpansionTile(
        title: const Text('Теги', style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          _selectedTags.isEmpty 
            ? 'Не выбрано' 
            : 'Выбрано: ${_selectedTags.length}',
          style: const TextStyle(fontSize: 12),
        ),
        initiallyExpanded: widget.tags.length < 10, // Авто-раскрытие если мало тегов
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 200, // Ограничиваем высоту списка тегов
            ),
            child: SingleChildScrollView( // Прокрутка только для тегов
              child: Column(
                children: [
                  if (widget.tags.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Теги не найдены'),
                    )
                  else
                    ...widget.tags.map((tag) {
                      final isSelected = _selectedTags.any((t) => t.id == tag.id);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(tag.name, style: const TextStyle(fontSize: 14)),
                        subtitle: tag.productCount != null 
                            ? Text('${tag.productCount} товаров', style: const TextStyle(fontSize: 11))
                            : null,
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.removeWhere((t) => t.id == tag.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final hasExistingImage = widget.product?.imageUrl.isNotEmpty == true;
    final hasNewImage = _imageBytes != null;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Изображение товара',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (hasNewImage)
              Column(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Удалить'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              )
            else if (hasExistingImage && !hasNewImage)
              Column(
                children: [
                  Text(
                    'Текущее изображение:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.product!.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                SizedBox(height: 8),
                                Text('Ошибка загрузки', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.change_circle, size: 16),
                    label: const Text('Заменить изображение'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Загрузить изображение'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.product != null;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isEditMode ? 600 : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? 'Редактировать товар' : 'Добавить товар',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Основная информация
                        Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Название товара *',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Введите название товара';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Описание (опционально)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Цена и количество
                        Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Цена (₽) *',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Введите цену';
                                      }
                                      final parsed = double.tryParse(value);
                                      if (parsed == null) {
                                        return 'Введите корректную цену';
                                      }
                                      if (parsed <= 0) {
                                        return 'Цена должна быть больше 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _stockController,
                                    decoration: const InputDecoration(
                                      labelText: 'Количество *',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Введите количество';
                                      }
                                      final parsed = int.tryParse(value);
                                      if (parsed == null) {
                                        return 'Введите целое число';
                                      }
                                      if (parsed < 0) {
                                        return 'Количество не может быть отрицательным';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Категория
                        Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: DropdownButtonFormField<int?>(
                              value: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Категория *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Не выбрано', style: TextStyle(color: Colors.grey)),
                                ),
                                ...widget.categories.map<DropdownMenuItem<int?>>((category) {
                                  return DropdownMenuItem<int?>(
                                    value: category.id,
                                    child: Text(category.name),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Выберите категорию';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Теги
                        _buildTagsSelector(),
                        const SizedBox(height: 12),
                        
                        // Изображение
                        _buildImageSection(),
                        
                        // Индикатор загрузки
                        if (_isLoading)
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isEditMode 
                                          ? 'Обновление товара...' 
                                          : 'Создание товара...',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Кнопки
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Text(isEditMode ? 'Сохранить' : 'Создать'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}