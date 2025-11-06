// analysis_screen.dart
import 'dart:convert';
import 'dart:io';
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
        
        // Проверяем размер изображения (макс 5MB)
        if (imageBytes.length > 5 * 1024 * 1024) {
          throw Exception('Изображение слишком большое. Максимум 5MB');
        }
        
        result = await ApiClient.analyzeFoodImageFile(imageBytes);
      } else if (widget.imagePath != null) {
        // Анализ из пути файла
        final file = File(widget.imagePath!);
        final imageBytes = await file.readAsBytes();
        result = await ApiClient.analyzeFoodImageFile(imageBytes);
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
          _errorMessage = 'Ошибка анализа: ${e.toString()}';
        });
      }
    }
  }

  void _retryAnalysis() {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _analysisResult = null;
    });
    _startAnalysis();
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
              tooltip: 'Добавить все в корзину',
            ),
          if (_errorMessage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retryAnalysis,
              tooltip: 'Повторить анализ',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: _retryAnalysis,
                  child: const Text('Повторить'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Назад'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final result = _analysisResult!;
    
    // Проверяем успешность запроса
    if (result['success'] == false) {
      return _buildError();
    }
    
    final dishName = result['detected_dish'] ?? 'Неизвестное блюдо';
    final confidence = (result['confidence'] ?? 0.0).toDouble();
    final recommendations = List<String>.from(result['recommendations'] ?? []);
    final basicAlternatives = List<dynamic>.from(result['basic_alternatives'] ?? []);
    final additionalAlternatives = List<dynamic>.from(result['additional_alternatives'] ?? []);
    
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Уверенность: ${(confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: confidence > 0.7 ? Colors.green : 
                                  confidence > 0.4 ? Colors.orange : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _buildConfidenceIndicator(confidence),
                    ],
                  ),
                  if (result['message'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      result['message'],
                      style: const TextStyle(color: Colors.grey),
                    ),
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
                  Icon(
                    _getRecommendationIcon(rec),
                    size: 16,
                    color: _getRecommendationColor(rec),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec)),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],
          
          // Основные ингредиенты
          if (basicAlternatives.isNotEmpty) ...[
            const Text(
              'Основные ингредиенты:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildIngredientSections(basicAlternatives),
          ] else if (result['basic_ingredients'] != null) ...[
            const Text(
              'Основные ингредиенты:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Ингредиенты не найдены в магазине: ${(result['basic_ingredients'] as List).join(', ')}',
                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          
          // Дополнительные ингредиенты
          if (additionalAlternatives.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Дополнительные ингредиенты:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildIngredientSections(additionalAlternatives),
          ] else if (result['additional_ingredients'] != null && 
                    (result['additional_ingredients'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Дополнительные ингредиенты:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Ингредиенты не найдены в магазине: ${(result['additional_ingredients'] as List).join(', ')}',
                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Кнопки действий
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    return Container(
      width: 60,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: confidence,
        child: Container(
          decoration: BoxDecoration(
            color: confidence > 0.7 ? Colors.green : 
                  confidence > 0.4 ? Colors.orange : Colors.red,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  IconData _getRecommendationIcon(String recommendation) {
    if (recommendation.contains('✅') || recommendation.contains('🎉')) {
      return Icons.check_circle;
    } else if (recommendation.contains('⚠️') || recommendation.contains('🔍')) {
      return Icons.info;
    } else if (recommendation.contains('❌')) {
      return Icons.warning;
    } else if (recommendation.contains('✨') || recommendation.contains('💡')) {
      return Icons.lightbulb;
    }
    return Icons.info_outline;
  }

  Color _getRecommendationColor(String recommendation) {
    if (recommendation.contains('✅') || recommendation.contains('🎉')) {
      return Colors.green;
    } else if (recommendation.contains('⚠️') || recommendation.contains('🔍')) {
      return Colors.orange;
    } else if (recommendation.contains('❌')) {
      return Colors.red;
    } else if (recommendation.contains('✨') || recommendation.contains('💡')) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  List<Widget> _buildIngredientSections(List<dynamic> alternatives) {
    return alternatives.map<Widget>((alt) {
      final ingredient = alt['ingredient'] ?? 'Неизвестный ингредиент';
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
              if (products.isNotEmpty) 
                ...products.map((product) => _buildProductItem(product))
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Товары не найдены',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    final productId = product['id'] ?? 0;
    final productName = product['name'] ?? 'Неизвестный товар';
    final price = (product['price'] ?? 0.0).toDouble();
    final imageUrl = product['image_url']?.toString() ?? '';
    final inFavorites = product['in_favorites'] == true;
    final stockQuantity = (product['stock_quantity'] ?? 0).toInt();
    final isOutOfStock = stockQuantity <= 0;

    return ListTile(
      leading: imageUrl.isNotEmpty
          ? CircleAvatar(
              backgroundImage: NetworkImage(
                '${ApiClient.baseUrl}/images/products/${product['id']}/image'
              ),
              onBackgroundImageError: (exception, stackTrace) {
                // Если изображение не загружается, показываем заглушку
              },
            )
          : const CircleAvatar(
              child: Icon(Icons.food_bank),
            ),
      title: Text(productName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$price ₽'),
          if (isOutOfStock)
            const Text(
              'Нет в наличии',
              style: TextStyle(color: Colors.red, fontSize: 12),
            )
          else if (stockQuantity < 10)
            Text(
              'Осталось: $stockQuantity шт.',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (inFavorites)
            const Icon(Icons.favorite, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isOutOfStock ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
              color: isOutOfStock ? Colors.grey : Theme.of(context).primaryColor,
            ),
            onPressed: isOutOfStock ? null : () => _addToCart(productId),
          ),
        ],
      ),
      onTap: () {
        // TODO: Переход на карточку товара
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (context) => ProductDetailScreen(productId: productId)
        // ));
      },
    );
  }

  Widget _buildActionButtons() {
    final hasProducts = _hasAvailableProducts();
    
    return Column(
      children: [
        if (hasProducts) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _addAllToCart,
              child: const Text('Добавить все в корзину'),
            ),
          ),
          const SizedBox(height: 8),
        ],
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

  bool _hasAvailableProducts() {
    final result = _analysisResult!;
    final basicAlts = List<dynamic>.from(result['basic_alternatives'] ?? []);
    final additionalAlts = List<dynamic>.from(result['additional_alternatives'] ?? []);
    
    for (final alt in [...basicAlts, ...additionalAlts]) {
      final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
      for (final product in products) {
        final stockQuantity = (product['stock_quantity'] ?? 1).toInt();
        if (stockQuantity > 0) {
          return true;
        }
      }
    }
    return false;
  }

  void _addToCart(int productId) async {
    try {
      await ApiClient.addToCart(productId, 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар добавлен в корзину')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _addAllToCart() async {
    try {
      final result = _analysisResult!;
      final basicAlts = List<dynamic>.from(result['basic_alternatives'] ?? []);
      final additionalAlts = List<dynamic>.from(result['additional_alternatives'] ?? []);
      
      int addedCount = 0;
      int skippedCount = 0;
      
      // Добавляем основные ингредиенты
      for (final alt in basicAlts) {
        final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
        for (final product in products) {
          final stockQuantity = (product['stock_quantity'] ?? 1).toInt();
          if (stockQuantity > 0) {
            await ApiClient.addToCart(product['id'], 1);
            addedCount++;
          } else {
            skippedCount++;
          }
        }
      }
      
      // Добавляем дополнительные ингредиенты
      for (final alt in additionalAlts) {
        final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
        for (final product in products) {
          final stockQuantity = (product['stock_quantity'] ?? 1).toInt();
          if (stockQuantity > 0) {
            await ApiClient.addToCart(product['id'], 1);
            addedCount++;
          } else {
            skippedCount++;
          }
        }
      }
      
      if (mounted) {
        String message = 'Добавлено $addedCount товаров в корзину';
        if (skippedCount > 0) {
          message += ' (пропущено $skippedCount - нет в наличии)';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении: $e')),
        );
      }
    }
  }
}