import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/admin/bloc/promotion_management_bloc.dart';

class PromotionManagement extends StatelessWidget {
  const PromotionManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PromotionManagementBloc()..add(const LoadPromotions()),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Управление акциями',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showCreatePromotionDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Создать акцию'),
        ),
      ],
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

  Widget _buildPromotionsList(BuildContext context, List<dynamic> promotions) {
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
            onDelete: () => _deletePromotion(context, promotion['id']),
          );
        },
      ),
    );
  }

  void _showCreatePromotionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать акцию'),
        content: const Text('Форма создания акции будет здесь'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Создать акцию
              Navigator.of(context).pop();
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _deletePromotion(BuildContext context, int promotionId) {
    context.read<PromotionManagementBloc>().add(DeletePromotion(promotionId));
  }
}

class PromotionCard extends StatelessWidget {
  final Map<String, dynamic> promotion;
  final VoidCallback onDelete;

  const PromotionCard({
    super.key,
    required this.promotion,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: promotion['is_active'] ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            promotion['is_active'] ? Icons.local_offer : Icons.local_offer_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(promotion['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тип: ${promotion['promotion_type']}'),
            Text('Скидка: ${promotion['discount_value']}%'),
            Text('Период: ${promotion['start_date'].toString().substring(0, 10)} - ${promotion['end_date'].toString().substring(0, 10)}'),
            Text(
              promotion['is_active'] ? 'Активна' : 'Неактивна',
              style: TextStyle(
                color: promotion['is_active'] ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}