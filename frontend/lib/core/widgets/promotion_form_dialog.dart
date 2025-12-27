import 'package:flutter/material.dart';
import 'package:client/domain/entities/promotion_entity.dart';
import 'package:client/core/types/promotion_type.dart';
import 'package:client/domain/entities/category_entity.dart';
import 'package:client/domain/entities/product_entity.dart';

class PromotionFormDialog extends StatefulWidget {
  final PromotionEntity? promotion;
  final List<CategoryEntity> categories;
  final List<ProductEntity> products;
  final Function(Map<String, dynamic>) onSave;

  const PromotionFormDialog({
    super.key,
    this.promotion,
    required this.categories,
    required this.products,
    required this.onSave,
  });

  @override
  State<PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<PromotionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _priorityController = TextEditingController();

  PromotionType _selectedType = PromotionType.percentage;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  int? _selectedGiftProductId;
  final List<int> _selectedCategoryIds = [];
  final List<int> _selectedProductIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.promotion != null) {
      _initializeForm(widget.promotion!);
    }
  }

  void _initializeForm(PromotionEntity promotion) {
    _titleController.text = promotion.title;
    _descriptionController.text = promotion.description ?? '';
    _selectedType = promotion.promotionType;
    _startDate = promotion.startDate;
    _endDate = promotion.endDate;
    _isActive = promotion.isActive;
    _selectedGiftProductId = promotion.giftProductId;
    _selectedCategoryIds.addAll(promotion.categoryIds ?? []);
    _selectedProductIds.addAll(promotion.productIds ?? []);
    
    if (promotion.promotionType == PromotionType.percentage) {
      _discountController.text = promotion.discountPercent?.toStringAsFixed(0) ?? '';
    } else if (promotion.promotionType == PromotionType.fixed) {
      _discountController.text = promotion.fixedDiscount?.toStringAsFixed(0) ?? '';
    }
    
    _minAmountController.text = promotion.minimumAmount?.toStringAsFixed(0) ?? '';
    _minQuantityController.text = promotion.minQuantity?.toString() ?? '';
    _priorityController.text = promotion.priority?.toString() ?? '';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final promotionData = {
        'name': _titleController.text,
        'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        'promotion_type': _selectedType.value,
        'is_active': _isActive,
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
        'priority': int.tryParse(_priorityController.text) ?? 0,
      };

      // Добавляем поля в зависимости от типа акции
      switch (_selectedType) {
        case PromotionType.percentage:
          if (_discountController.text.isNotEmpty) {
            promotionData['value'] = int.parse(_discountController.text);
          }
          break;
        case PromotionType.fixed:
          if (_discountController.text.isNotEmpty) {
            promotionData['value'] = int.parse(_discountController.text);
          }
          break;
        case PromotionType.gift:
          if (_selectedGiftProductId != null) {
            promotionData['gift_product_id'] = _selectedGiftProductId;
          }
          break;
        case PromotionType.bundle:
        case PromotionType.freeShipping:
          break;
      }

      // Добавляем условия
      if (_minAmountController.text.isNotEmpty) {
        promotionData['min_order_amount'] = int.parse(_minAmountController.text);
      }
      if (_minQuantityController.text.isNotEmpty) {
        promotionData['min_quantity'] = int.parse(_minQuantityController.text);
      }

      // Добавляем категории и товары
      if (_selectedCategoryIds.isNotEmpty) {
        promotionData['category_ids'] = _selectedCategoryIds;
      }
      if (_selectedProductIds.isNotEmpty) {
        promotionData['product_ids'] = _selectedProductIds;
      }

      widget.onSave(promotionData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.promotion == null ? 'Создать акцию' : 'Редактировать акцию'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Название
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название акции',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название акции';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (опционально)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Тип акции
              DropdownButtonFormField<PromotionType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип акции',
                  border: OutlineInputBorder(),
                ),
                items: PromotionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.displayName),
                        Text(
                          type.description,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                validator: (value) => value == null ? 'Выберите тип акции' : null,
              ),
              const SizedBox(height: 12),

              // Поля в зависимости от типа акции
              if (_selectedType == PromotionType.percentage || 
                  _selectedType == PromotionType.fixed)
                TextFormField(
                  controller: _discountController,
                  decoration: InputDecoration(
                    labelText: _selectedType == PromotionType.percentage 
                        ? 'Процент скидки (%)' 
                        : 'Сумма скидки (₽)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedType == PromotionType.percentage || 
                        _selectedType == PromotionType.fixed) {
                      if (value == null || value.isEmpty) {
                        return 'Введите значение скидки';
                      }
                      final numValue = int.tryParse(value);
                      if (numValue == null) {
                        return 'Введите корректное число';
                      }
                      if (_selectedType == PromotionType.percentage && 
                          (numValue < 1 || numValue > 100)) {
                        return 'Процент должен быть от 1 до 100';
                      }
                    }
                    return null;
                  },
                ),

              if (_selectedType == PromotionType.gift)
                DropdownButtonFormField<int?>(
                  value: _selectedGiftProductId,
                  decoration: const InputDecoration(
                    labelText: 'Выберите подарок',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Не выбрано'),
                    ),
                    ...widget.products.map((product) {
                      return DropdownMenuItem(
                        value: product.id,
                        child: Text('${product.name} (${product.price} ₽)'),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGiftProductId = value;
                    });
                  },
                  validator: (value) {
                    if (_selectedType == PromotionType.gift && value == null) {
                      return 'Выберите товар для подарка';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 12),

              // Даты начала и окончания
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Начало:'),
                        OutlinedButton(
                          onPressed: () => _selectDate(context, true),
                          child: Text(_formatDate(_startDate)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Окончание:'),
                        OutlinedButton(
                          onPressed: () => _selectDate(context, false),
                          child: Text(_formatDate(_endDate)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Минимальная сумма заказа
              TextFormField(
                controller: _minAmountController,
                decoration: const InputDecoration(
                  labelText: 'Минимальная сумма заказа (₽, опционально)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              // Минимальное количество
              TextFormField(
                controller: _minQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Минимальное количество товаров (опционально)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              // Приоритет
              TextFormField(
                controller: _priorityController,
                decoration: const InputDecoration(
                  labelText: 'Приоритет (чем больше, тем выше)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              // Активность
              SwitchListTile(
                title: const Text('Активная'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Выбор категорий
              if (widget.categories.isNotEmpty)
                ExpansionTile(
                  title: const Text('Категории для акции'),
                  subtitle: Text(_selectedCategoryIds.isEmpty 
                      ? 'Не выбрано' 
                      : 'Выбрано: ${_selectedCategoryIds.length}'),
                  children: widget.categories.map((category) {
                    final isSelected = _selectedCategoryIds.contains(category.id);
                    return CheckboxListTile(
                      title: Text(category.name),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedCategoryIds.add(category.id);
                          } else {
                            _selectedCategoryIds.remove(category.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

              // Выбор товаров
              if (widget.products.isNotEmpty)
                ExpansionTile(
                  title: const Text('Товары для акции'),
                  subtitle: Text(_selectedProductIds.isEmpty 
                      ? 'Не выбрано' 
                      : 'Выбрано: ${_selectedProductIds.length}'),
                  children: widget.products.map((product) {
                    final isSelected = _selectedProductIds.contains(product.id);
                    return CheckboxListTile(
                      title: Text('${product.name} (${product.price} ₽)'),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedProductIds.add(product.id);
                          } else {
                            _selectedProductIds.remove(product.id);
                          }
                        });
                      },
                    );
                  }).toList(),
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
          onPressed: _onSave,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}