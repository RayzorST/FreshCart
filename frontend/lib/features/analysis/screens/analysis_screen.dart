import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/analysis/bloc/analysis_result_bloc.dart';

class AnalysisResultScreen extends StatelessWidget {
  final String? imageData;
  
  const AnalysisResultScreen({
    super.key,
    this.imageData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnalysisResultBloc()
        ..add(AnalysisResultStarted(imageData!)),
      child: const _AnalysisResultView(),
    );
  }
}

class _AnalysisResultView extends StatelessWidget {
  const _AnalysisResultView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnalysisResultBloc, AnalysisResultState>(
      listener: (context, state) {
        if (state is AnalysisResultCartAction) {
          if (state.isSuccess) {
            AppSnackbar.showSuccess(context: context, message: state.message);
          } else {
            AppSnackbar.showError(context: context, message: state.message);
          }
        } else if (state is AnalysisResultNavigateBack) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Результат анализа'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.read<AnalysisResultBloc>().add(AnalysisResultBackPressed());
        },
      ),
      actions: [
        BlocBuilder<AnalysisResultBloc, AnalysisResultState>(
          builder: (context, state) {
            if (state is AnalysisResultSuccess) {
              return IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  context.read<AnalysisResultBloc>().add(AnalysisResultAddAllToCart());
                },
                tooltip: 'Добавить все в корзину',
              );
            }
            
            if (state is AnalysisResultError) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<AnalysisResultBloc>().add(AnalysisResultRetried());
                },
                tooltip: 'Повторить анализ',
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<AnalysisResultBloc, AnalysisResultState>(
      builder: (context, state) {
        if (state is AnalysisResultLoading) {
          return _buildLoading();
        }
        
        if (state is AnalysisResultError) {
          return _buildError(context, state.message);
        }
        
        if (state is AnalysisResultSuccess) {
          return _buildResults(context, state);
        }
        
        return const SizedBox.shrink();
      },
    );
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

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: () {
                    context.read<AnalysisResultBloc>().add(AnalysisResultRetried());
                  },
                  child: const Text('Повторить'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    context.read<AnalysisResultBloc>().add(AnalysisResultBackPressed());
                  },
                  child: const Text('Назад'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, AnalysisResultSuccess state) {
    final result = state.result;
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
          
          if (basicAlternatives.isNotEmpty) ...[
            const Text(
              'Основные ингредиенты:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildIngredientSections(context, basicAlternatives),
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
            ..._buildIngredientSections(context, additionalAlternatives),
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
          
          _buildActionButtons(context, state.hasAvailableProducts),
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

  List<Widget> _buildIngredientSections(BuildContext context, List<dynamic> alternatives) {
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
                ...products.map((product) => _buildProductItem(context, product))
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

  Widget _buildProductItem(BuildContext context, Map<String, dynamic> product) {
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
              backgroundImage: NetworkImage(imageUrl),
              onBackgroundImageError: (exception, stackTrace) {},
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
            onPressed: isOutOfStock ? null : () {
              context.read<AnalysisResultBloc>().add(
                AnalysisResultAddToCart(productId),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool hasProducts) {
    return Column(
      children: [
        if (hasProducts) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                context.read<AnalysisResultBloc>().add(AnalysisResultAddAllToCart());
              },
              child: const Text('Добавить все в корзину'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              context.read<AnalysisResultBloc>().add(AnalysisResultBackPressed());
            },
            child: const Text('Сделать новый анализ'),
          ),
        ),
      ],
    );
  }
}