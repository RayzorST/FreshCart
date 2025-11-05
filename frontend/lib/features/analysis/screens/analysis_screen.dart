// analysis_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:client/api/client.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  final XFile? imageFile;
  
  const AnalysisScreen({
    super.key,
    this.imagePath,
    this.imageFile,
  });

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isAnalyzing = true;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() async {
    try {
      Map<String, dynamic> result;
      
      if (widget.imageFile != null) {
        // Анализ из файла
        final imageBytes = await widget.imageFile!.readAsBytes();
        result = await ApiClient.analyzeFoodImageFile(imageBytes);
      } else if (widget.imagePath != null) {
        // Анализ из пути (если нужно)
        // TODO: Реализовать конвертацию пути в base64
        result = await _analyzeFromPath();
      } else {
        throw Exception('No image provided');
      }
      
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Ошибка анализа: $e';
        });
      }
    }
  }

  Future<Map<String, dynamic>> _analyzeFromPath() async {
    // Заглушка - в реальности нужно конвертировать imagePath в base64
    await Future.delayed(const Duration(seconds: 2));
    return {
      'success': true,
      'detected_dish': 'Салат Цезарь',
      'confidence': 0.85,
      'message': 'Определено блюдо: Салат Цезарь',
      'basic_ingredients': ['салат романо', 'курица', 'сыр пармезан', 'сухарики'],
      'additional_ingredients': ['черри', 'бекон', 'соус цезарь'],
      'basic_alternatives': [
        {
          'ingredient': 'салат романо',
          'products': [
            {'id': 5, 'name': 'Салат Цезарь «Белая дача» Романо и айсберг', 'price': 179.0, 'image_url': '/minio/images/c02dacf0-abd3-45c1-aaf8-5269bf41e2cd.jpg', 'in_favorites': false}
          ]
        },
        {
          'ingredient': 'соус цезарь', 
          'products': [
            {'id': 4, 'name': 'Соус Цезарь Heinz', 'price': 215.0, 'image_url': '/minio/images/22366249-c01a-4b80-831d-3cc8c4f97c29.jpg', 'in_favorites': true}
          ]
        }
      ],
      'additional_alternatives': [
        {
          'ingredient': 'черри',
          'products': [
            {'id': 6, 'name': 'Помидоры Черри', 'price': 320.0, 'image_url': '', 'in_favorites': false}
          ]
        }
      ],
      'recommendations': [
        '✅ Высокая уверенность в определении блюда: Салат Цезарь',
        '🔍 Найдено 2 из 4 основных ингредиентов',
        '✨ Найдено 1 дополнительных ингредиентов для улучшения блюда'
      ]
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Анализ блюда'),
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: _addAllToCart,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isAnalyzing) {
      return _buildLoading();
    }
    
    if (_errorMessage != null) {
      return _buildError();
    }
    
    return _buildResults();
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('ИИ анализирует ваше блюдо...'),
          SizedBox(height: 8),
          Text(
            'Это может занять несколько секунд',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final result = _analysisResult!;
    final dishName = result['detected_dish'];
    final confidence = result['confidence'];
    final recommendations = List<String>.from(result['recommendations'] ?? []);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с уверенностью
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dishName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Уверенность: ${(confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: confidence > 0.7 ? Colors.green : 
                            confidence > 0.4 ? Colors.orange : Colors.red,
                    ),
                  ),
                  if (result['message'] != null) ...[
                    const SizedBox(height: 8),
                    Text(result['message']),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Рекомендации
          if (recommendations.isNotEmpty) ...[
            const Text(
              'Рекомендации:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec)),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],
          
          // Основные ингредиенты
          if (result['basic_alternatives'] != null && 
              (result['basic_alternatives'] as List).isNotEmpty) ...[
            const Text(
              'Основные ингредиенты:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildIngredientSections(result['basic_alternatives']),
          ],
          
          // Дополнительные ингредиенты
          if (result['additional_alternatives'] != null && 
              (result['additional_alternatives'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Дополнительные ингредиенты:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildIngredientSections(result['additional_alternatives']),
          ],
          
          const SizedBox(height: 32),
          
          // Кнопки действий
          _buildActionButtons(),
        ],
      ),
    );
  }

  List<Widget> _buildIngredientSections(List<dynamic> alternatives) {
    return alternatives.map<Widget>((alt) {
      final ingredient = alt['ingredient'];
      final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ingredient,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...products.map((product) => _buildProductItem(product)),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    return ListTile(
      leading: product['image_url'] != null && product['image_url'].isNotEmpty
          ? CircleAvatar(
              backgroundImage: NetworkImage('${ApiClient.baseUrl}/images/products/${product['id']}/image'),
            )
          : const CircleAvatar(
              child: Icon(Icons.food_bank),
            ),
      title: Text(product['name']),
      subtitle: Text('${product['price']} ₽'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product['in_favorites'] == true)
            const Icon(Icons.favorite, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () => _addToCart(product['id']),
          ),
        ],
      ),
      onTap: () {
        // TODO: Переход на карточку товара
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (context) => ProductDetailScreen(productId: product['id'])
        // ));
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _addAllToCart,
            child: const Text('Добавить все в корзину'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Сделать новый анализ'),
          ),
        ),
      ],
    );
  }

  void _addToCart(int productId) async {
    try {
      await ApiClient.addToCart(productId, 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар добавлен в корзину')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _addAllToCart() async {
    try {
      final result = _analysisResult!;
      final basicAlts = List<dynamic>.from(result['basic_alternatives'] ?? []);
      final additionalAlts = List<dynamic>.from(result['additional_alternatives'] ?? []);
      
      int addedCount = 0;
      
      // Добавляем основные ингредиенты
      for (final alt in basicAlts) {
        final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
        for (final product in products) {
          await ApiClient.addToCart(product['id'], 1);
          addedCount++;
        }
      }
      
      // Добавляем дополнительные ингредиенты
      for (final alt in additionalAlts) {
        final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
        for (final product in products) {
          await ApiClient.addToCart(product['id'], 1);
          addedCount++;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Добавлено $addedCount товаров в корзину')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении: $e')),
      );
    }
  }
}