// promotion_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';
import 'package:client/core/widgets/app_snackbar.dart';

class PromotionManagement extends ConsumerStatefulWidget {
  const PromotionManagement({super.key});

  @override
  ConsumerState<PromotionManagement> createState() => _PromotionManagementState();
}

class _PromotionManagementState extends ConsumerState<PromotionManagement> {
  List<dynamic> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final promotions = await ApiClient.getAdminPromotions();
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPromotion(Map<String, dynamic> promotionData) async {
    try {
      await ApiClient.createAdminPromotion(promotionData);
      _loadPromotions();
      AppSnackbar.showInfo(context: context, message: 'Акция создана');
    } catch (e) {
      AppSnackbar.showError(context: context, message: 'Ошибка создания');
    }
  }

  Future<void> _deletePromotion(int promotionId) async {
    try {
      await ApiClient.deleteAdminPromotion(promotionId);
      _loadPromotions();
      AppSnackbar.showInfo(context: context, message: 'Акция удалена');
    } catch (e) {
      AppSnackbar.showError(context: context, message: 'Ошибка удаления');
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
                'Управление акциями',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreatePromotionDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Создать акцию'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _promotions.isEmpty
                    ? const Center(child: Text('Акции не найдены'))
                    : ListView.builder(
                        itemCount: _promotions.length,
                        itemBuilder: (context, index) {
                          final promotion = _promotions[index];
                          return PromotionCard(
                            promotion: promotion,
                            onDelete: () => _deletePromotion(promotion['id']),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showCreatePromotionDialog() {
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