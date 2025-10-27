import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  final String imagePath;
  
  const AnalysisScreen({
    super.key,
    required this.imagePath,
  });

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    // TODO: Заглушка - имитация анализа
    _simulateAnalysis();
  }

  void _simulateAnalysis() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Анализ блюда'),
      ),
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('ИИ анализирует ваше блюдо...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TODO: Заменить на реальное изображение
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fastfood, size: 60),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ИИ определил в вашем блюде:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // TODO: Заменить на реальные продукты
                  _buildProductItem('Куриная грудка', '200 г'),
                  _buildProductItem('Брокколи', '150 г'),
                  _buildProductItem('Морковь', '100 г'),
                  _buildProductItem('Рис', '180 г'),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        // TODO: Добавить продукты в корзину
                      },
                      child: const Text('Добавить в корзину'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductItem(String name, String weight) {
    return ListTile(
      leading: const Icon(Icons.food_bank),
      title: Text(name),
      trailing: Text(weight),
      onTap: () {
        // TODO: Переход на карточку товара
      },
    );
  }
}