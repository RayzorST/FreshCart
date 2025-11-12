import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощь и поддержка'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpItem(
            context,
            title: 'Часто задаваемые вопросы',
            icon: Icons.help_outline,
            onTap: () {
              _showFaqDialog(context);
            },
          ),
          _buildHelpItem(
            context,
            title: 'О приложении',
            icon: Icons.info_outline,
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          _buildHelpItem(
            context,
            title: 'Политика конфиденциальности', 
            icon: Icons.security,
            onTap: () {
              _showPrivacyPolicyDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.grey.withOpacity(0.2),
      builder: (context) => AlertDialog(
        title: const Text('Часто задаваемые вопросы'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFaqItem(
                question: 'Как сделать заказ?',
                answer: 'Выберите товары в каталоге, добавьте в корзину и оформите заказ.',
              ),
              const SizedBox(height: 12),
              _buildFaqItem(
                question: 'Как отследить заказ?',
                answer: 'Статус заказа можно посмотреть в разделе "Мои заказы".',
              ),
              const SizedBox(height: 12),
              _buildFaqItem(
                question: 'Какие способы оплаты доступны?',
                answer: 'Доступна оплата картой и наличными при получении.',
              ),
              const SizedBox(height: 12),
              _buildFaqItem(
                question: 'Как вернуть товар?',
                answer: 'Возврат возможен в течение 14 дней с момента покупки.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.grey.withOpacity(0.2),
      builder: (context) => AlertDialog(
        title: const Text('О приложении'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FreshCart',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Версия 1.0.0',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              'Приложение для заказа продуктов с доставкой на дом.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2025 FreshCart. Все права защищены.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.grey.withOpacity(0.2),
      builder: (context) => AlertDialog(
        title: const Text('Политика конфиденциальности'),
        content: SingleChildScrollView(
          child: Text(
            'Мы серьезно относимся к защите ваших персональных данных.\n\n'
            '1. Сбор информации: Мы собираем только необходимую информацию для обработки заказов.\n\n'
            '2. Использование данных: Ваши данные используются исключительно для предоставления услуг.\n\n'
            '3. Защита данных: Мы принимаем все необходимые меры для защиты вашей информации.\n\n'
            '4. Конфиденциальность: Мы не передаем ваши данные третьим лицам без вашего согласия.\n\n'
            'Если у вас есть вопросы, свяжитесь с нами через приложение.',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}