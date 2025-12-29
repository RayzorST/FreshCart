import 'package:client/api/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/analysis/bloc/analysis_history_bloc.dart';

class AnalysisHistoryScreen extends StatelessWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AnalysisHistoryView();
  }
}

class _AnalysisHistoryView extends StatefulWidget {
  const _AnalysisHistoryView();

  @override
  State<_AnalysisHistoryView> createState() => _AnalysisHistoryViewState();
}

class _AnalysisHistoryViewState extends State<_AnalysisHistoryView> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Это сохраняет состояние экрана

  final List<String> _sectionTitles = [
    'Мои анализы',
    'Все анализы',
  ];

  final List<IconData> _sectionIcons = [
    Icons.person,
    Icons.people,
  ];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisHistoryBloc>().add(AnalysisHistoryStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<AnalysisHistoryBloc, AnalysisHistoryState>(
      listener: (context, state) {
        if (state is AnalysisHistoryCartAction) {
          if (state.isSuccess) {
            AppSnackbar.showSuccess(context: context, message: state.message);
          } else {
            AppSnackbar.showError(context: context, message: state.message);
          }
        } else if (state is AnalysisHistoryDeleted) {
          AppSnackbar.showInfo(context: context, message: state.message);
        }
        else if (state is AnalysisHistoryNavigateToResult) {
          context.push(
            '/analysis/result',
            extra: {
              'result': state.resultData,
              'fromHistory': state.fromHistory,
            },
          );

          Future.microtask(() {
            context.read<AnalysisHistoryBloc>().add(AnalysisHistoryReturnedFromResult());
          });
        }
      },
      child: BlocBuilder<AnalysisHistoryBloc, AnalysisHistoryState>(
        builder: (context, state) {
          final selectedSection = state is AnalysisHistorySuccess 
              ? state.currentTab 
              : 0;

          if (state is AnalysisHistoryError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Ошибка загрузки')),
              body: Center(
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
                        context.read<AnalysisHistoryBloc>().add(AnalysisHistoryStarted());
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is AnalysisHistoryLoading) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'История анализов блюд', 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                )
              ),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(
                'История анализов блюд',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            body: Column(
              children: [
                _buildNavigationBar(context, selectedSection),
                _buildContent(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context, int selectedSection) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: List.generate(_sectionTitles.length, (index) {
          final isSelected = selectedSection == index;
          return Expanded(
            child: _buildNavItem(context, index, isSelected),
          );
        }),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _onSectionChanged(context, index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _sectionIcons[index],
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  _sectionTitles[index],
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AnalysisHistoryState state) {
    if (state is AnalysisHistorySuccess) {
      final analyses = state.currentTab == 0 
          ? state.myAnalysisHistory 
          : state.allUsersAnalysis;
      final isLoading = state.currentTab == 0 
          ? state.isLoadingMyHistory 
          : state.isLoadingAllUsers;
      final isMyAnalysis = state.currentTab == 0;

      if (isLoading) {
        return const Expanded(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (analyses.isEmpty) {
        return Expanded(
          child: _buildEmptyState(context, isMyAnalysis),
        );
      }

      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ],
            ),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: analyses.length,
            itemBuilder: (context, index) {
              final analysis = analyses[index];
              return _buildAnalysisCard(context, analysis, isMyAnalysis);
            },
          ),
        ),
      );
    }

    return const Expanded(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildAnalysisCard(BuildContext context, Map<String, dynamic> analysis, bool isMyAnalysis) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final dishName = analysis['detected_dish'] ?? 'Неизвестное блюдо';
    final confidence = (analysis['confidence'] ?? 0.0).toDouble();
    final date = DateTime.parse(analysis['created_at']);
    final ingredients = analysis['ingredients'] ?? {};
    final basicIngredients = List<String>.from(ingredients['basic'] ?? []);
    final additionalIngredients = List<String>.from(ingredients['additional'] ?? []);
    final imageUrl = '${ApiClient.baseUrl}/images/analysis/${analysis['id']}/image';
    final userName = analysis['user_name'] ?? 'Пользователь';
    final totalIngredients = basicIngredients.length + additionalIngredients.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.read<AnalysisHistoryBloc>().add(
            AnalysisHistoryOpenResult(
              analysis: analysis,
              isMyAnalysis: isMyAnalysis,
            ),
          );
        },
        onLongPress: isMyAnalysis ? () {
          _showAnalysisOptions(context, analysis);
        } : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение анализа
              _buildAnalysisImage(context, imageUrl, dishName),
              
              const SizedBox(width: 16),
              
              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Название и информация о пользователе
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dishName,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        if (!isMyAnalysis) ...[
                          const SizedBox(height: 4),
                          Text(
                            userName,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 8),
                        
                        // Информация об ингредиентах и дате
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalIngredients ингредиентов',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(date),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Индикатор уверенности
                    _buildConfidenceBar(confidence, colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisImage(BuildContext context, String? imageUrl, String dishName) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceVariant,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder(dishName, colorScheme);
                },
              )
            : _buildImagePlaceholder(dishName, colorScheme),
      ),
    );
  }

  Widget _buildImagePlaceholder(String dishName, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 32,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            dishName.substring(0, min(3, dishName.length)),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: confidence,
                backgroundColor: colorScheme.surfaceVariant,
                color: _getConfidenceColor(confidence, colorScheme),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getConfidenceColor(confidence, colorScheme),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getConfidenceText(confidence),
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence, ColorScheme colorScheme) {
    if (confidence > 0.7) return colorScheme.primary;
    if (confidence > 0.4) return colorScheme.secondary;
    return colorScheme.error;
  }

  String _getConfidenceText(double confidence) {
    if (confidence > 0.7) return 'Высокая уверенность';
    if (confidence > 0.4) return 'Средняя уверенность';
    return 'Низкая уверенность';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} д. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else {
      return '${difference.inMinutes} мин. назад';
    }
  }

  Widget _buildEmptyState(BuildContext context, bool isMyAnalysis) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isMyAnalysis 
                    ? colorScheme.primaryContainer 
                    : colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMyAnalysis ? Icons.photo_library : Icons.people_outline,
                size: 60,
                color: isMyAnalysis 
                    ? colorScheme.onPrimaryContainer 
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isMyAnalysis 
                  ? 'У вас пока нет анализов'
                  : 'Пока нет анализов других пользователей',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isMyAnalysis
                  ? 'Сфотографируйте ваше первое блюдо\nдля анализа ингредиентов'
                  : 'Здесь будут отображаться анализы всех пользователей приложения',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (isMyAnalysis) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Сделать первый анализ'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onSectionChanged(BuildContext context, int sectionIndex) {
    context.read<AnalysisHistoryBloc>().add(AnalysisHistoryTabChanged(sectionIndex));
  }

  void _navigateToAnalysisResult(BuildContext context, Map<String, dynamic> analysis, bool isMyAnalysis) {
    // Преобразуем данные анализа в формат для AnalysisResultScreen
    final resultData = {
      'detected_dish': analysis['detected_dish'],
      'confidence': analysis['confidence'],
      'basic_ingredients': analysis['ingredients']?['basic'] ?? [],
      'additional_ingredients': analysis['ingredients']?['additional'] ?? [],
      'basic_alternatives': _convertAlternativesToResultFormat(analysis['alternatives_found'], 'basic'),
      'additional_alternatives': _convertAlternativesToResultFormat(analysis['alternatives_found'], 'additional'),
    };
    
    // Переход на страницу результата анализа
    context.push(
      '/analysis/result',
      extra: {
        'result': resultData,
        'fromHistory': true,
      },
    );
  }

  List<Map<String, dynamic>> _convertAlternativesToResultFormat(Map<String, dynamic> alternatives, String type) {
    final List<Map<String, dynamic>> result = [];
    final List<dynamic> altList = alternatives[type] ?? [];
    
    for (final alt in altList) {
      if (alt is Map<String, dynamic>) {
        result.add({
          'ingredient': alt['ingredient'],
          'products': alt['products'] ?? [],
        });
      }
    }
    
    return result;
  }

  void _showAnalysisOptions(BuildContext context, Map<String, dynamic> analysis) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Действия с анализом',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.visibility, color: colorScheme.primary),
              title: const Text('Просмотреть детали'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAnalysisResult(context, analysis, true);
              },
            ),
            if (_hasAvailableProducts(analysis['alternatives_found'] ?? {}))
              ListTile(
                leading: Icon(Icons.shopping_cart, color: colorScheme.primary),
                title: const Text('Добавить в корзину'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AnalysisHistoryBloc>().add(
                    AnalysisHistoryAddAllToCart(analysis['alternatives_found'] ?? {}),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: colorScheme.error),
              title: Text(
                'Удалить анализ',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                context.read<AnalysisHistoryBloc>().add(
                  AnalysisHistoryDeleteRequested(analysis['id']),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _hasAvailableProducts(Map<String, dynamic> alternatives) {
    final basicAlts = List<dynamic>.from(alternatives['basic'] ?? []);
    final additionalAlts = List<dynamic>.from(alternatives['additional'] ?? []);
    
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

  int min(int a, int b) => a < b ? a : b;
}