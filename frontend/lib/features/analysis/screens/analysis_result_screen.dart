import 'package:flutter/material.dart';
import 'package:client/core/di/di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/analysis/bloc/analysis_result_bloc.dart';
import 'package:client/features/analysis/bloc/analysis_history_bloc.dart';
import 'package:client/domain/entities/product_entity.dart';

class AnalysisResultScreen extends StatelessWidget {
  final Map<String, dynamic>? resultData;
  final bool fromHistory;
  final String? imageData;
  
  const AnalysisResultScreen({
    super.key,
    this.resultData,
    this.fromHistory = false,
    this.imageData, 
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<AnalysisResultBloc>();
        
        // Сначала проверяем resultData (из истории)
        if (resultData != null) {
          bloc.add(AnalysisResultFromHistory(resultData!));
        } 
        // Затем проверяем imageData (из камеры/галереи)
        else if (imageData != null && imageData!.isNotEmpty) {
          bloc.add(AnalysisResultStarted(imageData!));
        }
        // Если оба null, ничего не делаем
        
        return bloc;
      },
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
      title: Text(
        'Результат анализа', 
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.read<AnalysisResultBloc>().add(AnalysisResultBackPressed());
          context.read<AnalysisHistoryBloc>().add(AnalysisHistoryRefreshed());
        },
      ),
      actions: [
        BlocBuilder<AnalysisResultBloc, AnalysisResultState>(
          builder: (context, state) {
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
    final basicAlternatives = List<dynamic>.from(result['basic_alternatives'] ?? []);
    final additionalAlternatives = List<dynamic>.from(result['additional_alternatives'] ?? []);
    
    // Проверяем, есть ли отсутствующие основные ингредиенты
    final missingBasicIngredients = result['basic_ingredients'] != null && 
        (result['basic_ingredients'] as List).isNotEmpty && 
        basicAlternatives.isEmpty;
    final missingAdditionalIngredients = result['additional_ingredients'] != null && 
        (result['additional_ingredients'] as List).isNotEmpty && 
        additionalAlternatives.isEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisHeader(dishName, confidence),
          
          const SizedBox(height: 16),

          if (missingBasicIngredients || missingAdditionalIngredients) 
            _buildMissingIngredientsWarning(
              context, 
              result['basic_ingredients'] as List<dynamic>?,
              result['additional_ingredients'] as List<dynamic>?,
              basicAlternatives.isEmpty,
              additionalAlternatives.isEmpty,
            ),
          
          const SizedBox(height: 16),

          if (basicAlternatives.isNotEmpty) 
            _buildIngredientSection(
              context, 
              'Основные ингредиенты', 
              basicAlternatives,
              state: state,
              isBasic: true,
            ),
          
          const SizedBox(height: 16),

          if (additionalAlternatives.isNotEmpty) 
            _buildIngredientSection(
              context, 
              'Дополнительные ингредиенты', 
              additionalAlternatives,
              state: state,
              isBasic: false,
            ),
          
          const SizedBox(height: 32),
          
          // Кнопки действий
          _buildActionButtons(context, state.hasSelectedProducts),
        ],
      ),
    );
  }

  Widget _buildAnalysisHeader(String dishName, double confidence) {
    final filterIcon = _getConfidenceFilterIcon(confidence);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Icon(
                  filterIcon,
                  size: 40,
                  color: _getConfidenceColor(confidence),
                ),
                const SizedBox(height: 4),
                _buildVerticalConfidenceIndicator(confidence),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalConfidenceIndicator(double confidence) {
    return Container(
      width: 8,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: confidence,
              child: Container(
                decoration: BoxDecoration(
                  color: confidence > 0.7 ? Colors.green : 
                        confidence > 0.4 ? Colors.orange : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getConfidenceFilterIcon(double confidence) {
    if (confidence <= 0.1) return Icons.filter_1;
    if (confidence <= 0.2) return Icons.filter_2;
    if (confidence <= 0.3) return Icons.filter_3;
    if (confidence <= 0.4) return Icons.filter_4;
    if (confidence <= 0.5) return Icons.filter_5;
    if (confidence <= 0.6) return Icons.filter_6;
    if (confidence <= 0.7) return Icons.filter_7;
    if (confidence <= 0.8) return Icons.filter_8;
    if (confidence <= 0.9) return Icons.filter_9;
    return Icons.filter_9_plus;
  }

  Color _getConfidenceColor(double confidence) {
    return confidence > 0.7 ? Colors.green : 
           confidence > 0.4 ? Colors.orange : Colors.red;
  }

  Widget _buildMissingIngredientsWarning(
    BuildContext context, 
    List<dynamic>? basicIngredients,
    List<dynamic>? additionalIngredients,
    bool missingBasic,
    bool missingAdditional,
  ) {
    List<String> missingList = [];
    
    if (missingBasic && basicIngredients != null) {
      missingList.addAll(basicIngredients.cast<String>());
    }
    
    if (missingAdditional && additionalIngredients != null) {
      missingList.addAll(additionalIngredients.cast<String>());
    }
    
    if (missingList.isEmpty) return const SizedBox.shrink();
    
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Предупреждение',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Не найдены в магазине: ${missingList.join(', ')}',
              style: const TextStyle(color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientSection(
    BuildContext context, 
    String title, 
    List<dynamic> alternatives,
    {
      required AnalysisResultSuccess state,
      required bool isBasic,
    }
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...alternatives.map<Widget>((alt) {
          return _buildIngredientCard(
            context, 
            alt, 
            state: state,
            isBasic: isBasic,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildIngredientCard(
    BuildContext context, 
    Map<String, dynamic> alt, 
    {
      required AnalysisResultSuccess state,
      required bool isBasic,
    }
  ) {
    final ingredient = alt['ingredient'] ?? 'Неизвестный ингредиент';
    final products = List<Map<String, dynamic>>.from(alt['products'] ?? []);
    
    if (products.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            Text(
              'Товары не найдены',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    
    // Находим начальную страницу для PageView (на основе выбранного товара)
    int getInitialPageIndex() {
      final selectedProduct = state.selectedProducts.firstWhere(
        (sp) => sp.ingredient == ingredient && sp.isBasic == isBasic,
        orElse: () => SelectedProduct(
          productId: 0,
          ingredient: '',
          isBasic: false,
          productData: {},
        ),
      );
      
      if (selectedProduct.productId != 0) {
        final index = products.indexWhere((p) => p['id'] == selectedProduct.productId);
        return index >= 0 ? index : 0;
      }
      
      return 0;
    }
    
    // Создаем контроллер PageView
    final pageController = PageController(initialPage: getInitialPageIndex());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название ингредиента
          Row(
            children: [
              Text(
                ingredient,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Показываем выбранный продукт если есть
              _buildSelectedProductBadge(state, ingredient, isBasic),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Галерея карточек продуктов (PageView)
          SizedBox(
            height: 140,
            child: PageView.builder(
              itemCount: products.length,
              controller: pageController,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index) {
                // При свайпе НЕ выбираем товар, только перелистываем
                // Ничего не делаем
              },
              itemBuilder: (context, index) {
                return Builder(
                  builder: (context) {
                    return _buildProductCard(
                      context, 
                      products[index], 
                      ingredient, 
                      isBasic,
                      state: state,
                      productIndex: index,
                      totalProducts: products.length,
                    );
                  },
                );
              },
            ),
          ),
          
          // Индикаторы страниц
          if (products.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                products.length,
                (index) {
                  return GestureDetector(
                    onTap: () {
                      // Клик по точке переключает на соответствующую страницу
                      pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pageController.hasClients && 
                              pageController.page?.round() == index
                            ? Theme.of(context).primaryColor 
                            : Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedProductBadge(AnalysisResultSuccess state, String ingredient, bool isBasic) {
    final selectedProduct = state.selectedProducts.firstWhere(
      (sp) => sp.ingredient == ingredient && sp.isBasic == isBasic,
      orElse: () => SelectedProduct(
        productId: 0,
        ingredient: '',
        isBasic: false,
        productData: {},
      ),
    );
    
    if (selectedProduct.productId != 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Выбран',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildProductCard(
    BuildContext context, 
    Map<String, dynamic> productMap, 
    String ingredient, 
    bool isBasic,
    {
      required AnalysisResultSuccess state,
      required int productIndex,
      required int totalProducts,
    }
  ) {
    final product = ProductEntity.fromJson(productMap);
    final productId = product.id;
    final productName = product.name;
    final price = product.price;
    final imageUrl = product.imageUrl;
    final isOutOfStock = product.stockQuantity != null && product.stockQuantity! <= 0;
    final stockQuantity = product.stockQuantity ?? 0;
    final inFavorites = productMap['in_favorites'] == true;
    
    // Проверяем, выбран ли этот продукт
    final isSelected = state.isProductSelected(productId, ingredient, isBasic);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение продукта
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.food_bank, size: 30, color: Colors.grey);
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Информация о продукте
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Название продукта
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Цена
                  Text(
                    '$price ₽',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                      fontSize: 18,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Статус наличия
                  if (isOutOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          const Text(
                            'Нет в наличии',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (stockQuantity < 10)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Осталось: $stockQuantity',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (inFavorites)
                  const Icon(Icons.favorite, color: Colors.red, size: 18),
                
                GestureDetector(
                  onTap: isOutOfStock ? null : () {
                    if (isSelected) {
                      context.read<AnalysisResultBloc>().add(
                        AnalysisResultProductDeselected(
                          productId: productId,
                          ingredient: ingredient,
                          isBasic: isBasic,
                        ),
                      );
                    } else {
                      context.read<AnalysisResultBloc>().add(
                        AnalysisResultProductSelected(
                          productId: productId,
                          ingredient: ingredient,
                          isBasic: isBasic,
                          product: productMap,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected 
                            ? Colors.green 
                            : (isOutOfStock ? Colors.grey : Colors.grey[400]!),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected ? Colors.green : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool hasSelectedProducts) {
    return Column(
      children: [
        if (hasSelectedProducts) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.shopping_cart_checkout),
              onPressed: () {

                context.read<AnalysisResultBloc>().add(AnalysisResultAddAllToCart());
                context.pushReplacement("/");
              },
              label: const Text('Добавить выбранные в корзину'),
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