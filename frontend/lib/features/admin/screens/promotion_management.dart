// promotion_management.dart
import 'package:client/domain/entities/category_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/admin/bloc/promotion_management_bloc.dart';
import 'package:client/features/admin/bloc/product_management_bloc.dart';
import 'package:client/data/repositories/promotion_management_repository_impl.dart';
import 'package:client/data/repositories/product_management_repository_impl.dart';
import 'package:client/domain/entities/promotion_entity.dart';
import 'package:client/core/widgets/promotion_form_dialog.dart';
import 'package:client/domain/entities/product_entity.dart';

class PromotionManagement extends StatelessWidget {
  const PromotionManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PromotionManagementBloc(
            repository: PromotionManagementRepositoryImpl(),
          )..add(const LoadPromotions()),
        ),
        // Добавляем ProductManagementBloc, если его еще нет в дереве
        BlocProvider(
          create: (context) => ProductManagementBloc(
            repository: ProductManagementRepositoryImpl(),
          )..add(const LoadProductData()),
        ),
      ],
      child: const _PromotionManagementView(),
    );
  }
}

class _PromotionManagementView extends StatefulWidget {
  const _PromotionManagementView();

  @override
  State<_PromotionManagementView> createState() => _PromotionManagementViewState();
}

class _PromotionManagementViewState extends State<_PromotionManagementView> {
  @override
  void initState() {
    super.initState();
    // Загружаем товары при инициализации
    Future.microtask(() {
      context.read<ProductManagementBloc>().add(const LoadProductData());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PromotionManagementBloc, PromotionManagementState>(
      listener: (context, state) {
        if (state is PromotionManagementError) {
          AppSnackbar.showError(context: context, message: state.message);
        } else if (state is PromotionManagementOperationSuccess) {
          AppSnackbar.showInfo(context: context, message: state.message);
          // После успешной операции перезагружаем список
          Future.microtask(() {
            context.read<PromotionManagementBloc>().add(const LoadPromotions());
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<PromotionManagementBloc, PromotionManagementState>(
          builder: (context, state) {
            int activeCount = 0;
            int totalCount = 0;
            
            if (state is PromotionManagementLoaded) {
              activeCount = state.activePromotions.length;
              totalCount = state.promotions.length;
            }
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Управление акциями',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Активных: $activeCount/$totalCount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleCreatePromotion(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Создать акцию'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Card(
      elevation: 2,
      child: BlocBuilder<PromotionManagementBloc, PromotionManagementState>(
        builder: (context, state) {
          if (state is PromotionManagementLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Загрузка акций...'),
                  ],
                ),
              ),
            );
          } else if (state is PromotionManagementError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<PromotionManagementBloc>().add(const LoadPromotions());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is PromotionManagementLoaded) {
            return _buildPromotionsList(state.promotions);
          } else if (state is PromotionManagementOperationSuccess) {
            // Показываем загрузку после успешной операции
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Обновление списка...'),
                ],
              ),
            );
          } else {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка...'),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPromotionsList(List<PromotionEntity> promotions) {
    if (promotions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, color: Colors.grey[400], size: 64),
            const SizedBox(height: 16),
            Text(
              'Акции не найдены',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте первую акцию',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: promotions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final promotion = promotions[index];
        return PromotionCard(
          promotion: promotion,
          onEdit: () => _handleEditPromotion(promotion),
          onDelete: () => _handleDeletePromotion(promotion.id),
        );
      },
    );
  }

  void _handleCreatePromotion() {
    print('Создание акции: обработка нажатия кнопки');
    
    // Проверяем состояние ProductManagementBloc
    final productBloc = context.read<ProductManagementBloc>();
    final productState = productBloc.state;
    
    if (productState is ProductManagementLoaded) {
      _showCreateDialog(productState.products, productState.categories);
    } else if (productState is ProductManagementLoading) {
      _showLoadingDialog();
    } else {
      // Если товары не загружены, загружаем их
      productBloc.add(const LoadProductData());
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Загрузка данных'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                productState is ProductManagementError 
                  ? 'Ошибка загрузки товаров. Повторяем...' 
                  : 'Загрузка данных товаров...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
      
      // Ждем загрузки товаров
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Закрыть диалог загрузки
        final newState = productBloc.state;
        if (newState is ProductManagementLoaded) {
          _showCreateDialog(newState.products, newState.categories);
        } else {
          AppSnackbar.showError(
            context: context, 
            message: 'Не удалось загрузить данные товаров'
          );
        }
      });
    }
  }

  void _handleEditPromotion(PromotionEntity promotion) {
    print('Редактирование акции: ${promotion.id}');
    
    final productBloc = context.read<ProductManagementBloc>();
    final productState = productBloc.state;
    
    if (productState is ProductManagementLoaded) {
      _showEditDialog(promotion, productState.products, productState.categories);
    } else {
      // Загружаем товары, если они еще не загружены
      productBloc.add(const LoadProductData());
      AppSnackbar.showInfo(
        context: context, 
        message: 'Загрузка данных товаров...'
      );
      
      // Отложенное открытие диалога
      Future.delayed(const Duration(seconds: 1), () {
        final newState = productBloc.state;
        if (newState is ProductManagementLoaded) {
          _showEditDialog(promotion, newState.products, newState.categories);
        } else {
          AppSnackbar.showError(
            context: context, 
            message: 'Не удалось загрузить данные товаров'
          );
        }
      });
    }
  }

  void _handleDeletePromotion(int promotionId) {
    final promotionBloc = context.read<PromotionManagementBloc>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить акцию?'),
        content: const Text('Вы уверены, что хотите удалить эту акцию? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              promotionBloc.add(DeletePromotion(promotionId));
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(List<ProductEntity> products, List<CategoryEntity> categories) {
    final promotionBloc = context.read<PromotionManagementBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PromotionFormDialog(
        categories: categories,
        products: products,
        onSave: (promotionData) {
          Navigator.of(context).pop();
          promotionBloc.add(CreatePromotion(promotionData));
        },
      ),
    );
  }

  void _showEditDialog(PromotionEntity promotion, List<ProductEntity> products, List<CategoryEntity> categories) {
    final promotionBloc = context.read<PromotionManagementBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PromotionFormDialog(
        promotion: promotion,
        categories: categories,
        products: products,
        onSave: (promotionData) {
          Navigator.of(context).pop();
          promotionBloc.add(UpdatePromotion(
            promotionId: promotion.id,
            promotionData: promotionData,
          ));
        },
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Пожалуйста, подождите'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка данных...'),
          ],
        ),
      ),
    );
  }
}

class PromotionCard extends StatelessWidget {
  final PromotionEntity promotion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PromotionCard({
    super.key,
    required this.promotion,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
           '${date.month.toString().padLeft(2, '0')}.'
           '${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(bool isValid) {
    return isValid ? Colors.green : Colors.grey;
  }

  String _getStatusText(bool isValid) {
    return isValid ? 'Активна' : 'Неактивна';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = promotion.isValid;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getStatusColor(isActive),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isActive ? Icons.local_offer : Icons.local_offer_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promotion.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStatusText(isActive),
                              style: TextStyle(
                                color: _getStatusColor(isActive),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit, size: 20, color: Colors.blue[700]),
                      tooltip: 'Редактировать',
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      tooltip: 'Удалить',
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoItem(
                  icon: Icons.category,
                  label: 'Тип',
                  value: promotion.promotionType.displayName,
                ),
                if (promotion.discountPercent != null)
                  _buildInfoItem(
                    icon: Icons.percent,
                    label: 'Скидка',
                    value: '${promotion.discountPercent}%',
                  ),
                if (promotion.fixedDiscount != null)
                  _buildInfoItem(
                    icon: Icons.attach_money,
                    label: 'Фикс. скидка',
                    value: '${promotion.fixedDiscount} ₽',
                  ),
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Начало',
                  value: '${_formatDate(promotion.startDate)} ${_formatTime(promotion.startDate)}',
                ),
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Конец',
                  value: '${_formatDate(promotion.endDate)} ${_formatTime(promotion.endDate)}',
                ),
              ],
            ),
            if (promotion.description?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                promotion.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}