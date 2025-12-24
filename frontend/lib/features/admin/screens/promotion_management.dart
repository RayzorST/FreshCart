// promotion_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/admin/bloc/promotion_management_bloc.dart';
import 'package:client/features/admin/bloc/product_management_bloc.dart';
import 'package:client/data/repositories/promotion_management_repository_impl.dart';
import 'package:client/domain/entities/promotion_entity.dart';
import 'package:client/core/widgets/promotion_form_dialog.dart';

class PromotionManagement extends StatelessWidget {
  const PromotionManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PromotionManagementBloc(
        repository: PromotionManagementRepositoryImpl(),
      )..add(const LoadPromotions()),
      child: const _PromotionManagementView(),
    );
  }
}

class _PromotionManagementView extends StatelessWidget {
  const _PromotionManagementView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PromotionManagementBloc, PromotionManagementState>(
      listener: (context, state) {
        if (state is PromotionManagementError) {
          AppSnackbar.showError(context: context, message: state.message);
        } else if (state is PromotionManagementOperationSuccess) {
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
    return BlocBuilder<PromotionManagementBloc, PromotionManagementState>(
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
            Text(
              'Управление акциями',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  'Активных: $activeCount/$totalCount',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreatePromotionDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Создать акцию'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    return BlocBuilder<PromotionManagementBloc, PromotionManagementState>(
      builder: (context, state) {
        if (state is PromotionManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PromotionManagementError) {
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
                    context.read<PromotionManagementBloc>().add(const LoadPromotions());
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        } else if (state is PromotionManagementLoaded) {
          return _buildPromotionsList(context, state.promotions);
        } else {
          return const Center(child: Text('Загрузка...'));
        }
      },
    );
  }

  Widget _buildPromotionsList(BuildContext context, List<PromotionEntity> promotions) {
    if (promotions.isEmpty) {
      return const Center(child: Text('Акции не найдены'));
    }

    return Expanded(
      child: ListView.builder(
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          return PromotionCard(
            promotion: promotion,
            onDelete: () => _deletePromotion(context, promotion.id),
            onEdit: () => null,
          );
        },
      ),
    );
  }

  // promotion_management.dart (обновляем метод _showCreatePromotionDialog)
  void _showCreatePromotionDialog(BuildContext context) {
    final productManagementState = context.read<ProductManagementBloc>().state;
    
    if (productManagementState is! ProductManagementLoaded) {
      AppSnackbar.showError(context: context, message: 'Не удалось загрузить данные товаров');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PromotionFormDialog(
        categories: productManagementState.categories,
        products: productManagementState.products,
        onSave: (promotionData) {
          Navigator.of(context).pop();
          context.read<PromotionManagementBloc>().add(CreatePromotion(promotionData));
        },
      ),
    );
  }

  // Также добавим метод для редактирования
  void _showEditPromotionDialog(BuildContext context, PromotionEntity promotion) {
    final productManagementState = context.read<ProductManagementBloc>().state;
    
    if (productManagementState is! ProductManagementLoaded) {
      AppSnackbar.showError(context: context, message: 'Не удалось загрузить данные товаров');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PromotionFormDialog(
        promotion: promotion,
        categories: productManagementState.categories,
        products: productManagementState.products,
        onSave: (promotionData) {
          Navigator.of(context).pop();
          context.read<PromotionManagementBloc>().add(UpdatePromotion(
            promotionId: promotion.id,
            promotionData: promotionData,
          ));
        },
      ),
    );
  }

  void _deletePromotion(BuildContext context, int promotionId) {
    context.read<PromotionManagementBloc>().add(DeletePromotion(promotionId));
  }
}

// promotion_management.dart (обновляем метод форматирования даты)
class PromotionCard extends StatelessWidget {
  final PromotionEntity promotion;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const PromotionCard({
    super.key,
    required this.promotion,
    required this.onDelete,
    required this.onEdit,
  });

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: promotion.isValid ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            promotion.isValid ? Icons.local_offer : Icons.local_offer_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(promotion.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тип: ${promotion.promotionType.displayName}'),
            if (promotion.discountPercent != null)
              Text('Скидка: ${promotion.discountPercent}%'),
            if (promotion.fixedDiscount != null)
              Text('Фиксированная скидка: ${promotion.fixedDiscount} ₽'),
            Text('Период: ${_formatDate(promotion.startDate)} - '
                 '${_formatDate(promotion.endDate)}'),
            Text(
              promotion.isValid ? 'Активна' : 'Неактивна',
              style: TextStyle(
                color: promotion.isValid ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
              tooltip: 'Редактировать',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              onPressed: onDelete,
              tooltip: 'Удалить',
            ),
          ],
        ),
      ),
    );
  }
}