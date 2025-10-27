import 'package:flutter/material.dart';

class PromotionScreen extends StatelessWidget {
  final String promotionId;

  const PromotionScreen({super.key, required this.promotionId});

  @override
  Widget build(BuildContext context) {
    // TODO: Заглушка данных - позже заменим на реальные
    final promotion = _getPromotionById(promotionId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Акция'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Шапка акции
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    promotion['color'].withOpacity(0.3),
                    promotion['color'].withOpacity(0.1),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    child: Icon(
                      Icons.local_offer_outlined,
                      size: 120,
                      color: promotion['color'].withOpacity(0.2),
                    ),
                  ),
                  Center(
                    child: Text(
                      promotion['title'],
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: promotion['color'],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Срок действия
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Срок действия',
                    value: promotion['duration'],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Условия акции
                  Text(
                    'Условия акции',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...promotion['conditions'].map((condition) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: promotion['color'],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              condition,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )
                  ).toList(),
                  
                  const SizedBox(height: 24),
                  
                  // Как участвовать
                  Text(
                    'Как участвовать',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...promotion['steps'].map((step) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: promotion['color'],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${promotion['steps'].indexOf(step) + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )
                  ).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Заглушка данных
  Map<String, dynamic> _getPromotionById(String id) {
    final promotions = {
      '1': {
        'title': 'Скидка 20% на овощи',
        'color': Colors.green,
        'duration': 'до 31 декабря 2024',
        'conditions': [
          'Скидка действует на все свежие овощи',
          'Минимальная сумма покупки - 500 рублей',
          'Акция не суммируется с другими предложениями',
          'Один покупатель может воспользоваться акцией один раз',
        ],
        'steps': [
          'Выберите любые свежие овощи в нашем магазине',
          'Добавьте товары в корзину',
          'При оформлении заказа акция применится автоматически',
          'Получите скидку 20% на выбранные овощи',
        ],
      },
      '2': {
        'title': 'Акция на мясо',
        'color': Colors.red,
        'duration': 'до 15 января 2024',
        'conditions': [
          'Скидка 15% на премиальную говядину',
          'Акция действует на упаковки от 500г',
          'Предложение ограничено',
        ],
        'steps': [
          'Выберите премиальную говядину в мясном отделе',
          'Вес упаковки должен быть от 500г',
          'Скидка применится автоматически на кассе',
        ],
      },
      '3': {
        'title': 'Фруктовая неделя',
        'color': Colors.orange,
        'duration': 'еженедельно',
        'conditions': [
          'Специальные цены на экзотические фрукты',
          'Акция действует с понедельника по воскресенье',
          'Ассортимент может меняться',
        ],
        'steps': [
          'Посетите наш магазин с понедельника по воскресенье',
          'Выберите любые экзотические фрукты из акционного ассортимента',
          'Наслаждайтесь специальными ценами',
        ],
      },
    };

    return promotions[id] ?? {
      'title': 'Акция не найдена',
      'color': Colors.grey,
      'duration': 'неизвестно',
      'conditions': ['Информация об акции временно недоступна'],
      'steps': ['Попробуйте позже'],
    };
  }
}