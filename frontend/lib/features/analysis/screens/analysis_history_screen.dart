import 'package:flutter/material.dart';
import 'package:client/core/di/di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/analysis/bloc/analysis_history_bloc.dart';

class AnalysisHistoryScreen extends StatelessWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AnalysisHistoryBloc>()..add(AnalysisHistoryStarted()),
      child: const _AnalysisHistoryView(),
    );
  }
}

class _AnalysisHistoryView extends StatelessWidget {
  const _AnalysisHistoryView();

  @override
  Widget build(BuildContext context) {
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
      },
      child: BlocBuilder<AnalysisHistoryBloc, AnalysisHistoryState>(
        builder: (context, state) {
          final currentTab = state is AnalysisHistorySuccess 
              ? state.currentTab 
              : 0;

          return DefaultTabController(
            length: 2,
            initialIndex: currentTab,
            child: Scaffold(
              appBar: _buildAppBar(context),
              body: _buildBody(context),
            ),
          );
        }
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;

    return AppBar(
      title: Text(
        'История анализов',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      actions: [
        BlocBuilder<AnalysisHistoryBloc, AnalysisHistoryState>(
          builder: (context, state) {
            return IconButton(
              icon: Icon(Icons.refresh, color: colorScheme.primary),
              onPressed: () {
                context.read<AnalysisHistoryBloc>().add(AnalysisHistoryRefreshed());
              },
              tooltip: 'Обновить',
            );
          },
        ),
      ],
      bottom: _buildTabBar(context),
    );
  }

  PreferredSizeWidget _buildTabBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return PreferredSize(
      preferredSize: const Size.fromHeight(48.0),
      child: BlocBuilder<AnalysisHistoryBloc, AnalysisHistoryState>(
        builder: (context, state) {
          //final currentTab = state is AnalysisHistorySuccess 
          //    ? state.currentTab 
          //    : 0;

          return TabBar(
            onTap: (index) {
              context.read<AnalysisHistoryBloc>().add(AnalysisHistoryTabChanged(index));
            },
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.person),
                text: 'Мои анализы',
              ),
              Tab(
                icon: Icon(Icons.people),
                text: 'Все анализы',
              ),
            ],
          );
        },
      ),
    );
  }

Widget _buildBody(BuildContext context) {
  return Container(
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
    child: BlocBuilder<AnalysisHistoryBloc, AnalysisHistoryState>(
      builder: (context, state) {
        if (state is AnalysisHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AnalysisHistoryError) {
          return _buildErrorWidget(context, state.message, state.currentTab);
        }

        if (state is AnalysisHistoryShowDetailsState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showAnalysisDetails(context, state.analysis, state.isMyAnalysis);
          });
        }

        if (state is AnalysisHistoryShowOptionsState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMyAnalysisOptions(context, state.analysis);
          });
        }

        return _buildTabBarView(context, state);
      },
    ),
  );
}

  Widget _buildTabBarView(BuildContext context, AnalysisHistoryState state) {
    if (state is AnalysisHistorySuccess) {
      return TabBarView(
        children: [
          _buildMyAnalysisTab(context, state),
          _buildAllUsersAnalysisTab(context, state),
        ],
      );
    }

    return TabBarView(
      children: [
        Container(),
        Container(),
      ],
    );
  }

  Widget _buildMyAnalysisTab(BuildContext context, AnalysisHistorySuccess state) {
    if (state.isLoadingMyHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.myAnalysisHistory.isEmpty) {
      return _buildEmptyMyAnalysisState(context);
    }

    return _buildAnalysisList(context, state.myAnalysisHistory, isMyAnalysis: true);
  }

  Widget _buildAllUsersAnalysisTab(BuildContext context, AnalysisHistorySuccess state) {
    if (state.isLoadingAllUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.allUsersAnalysis.isEmpty) {
      return _buildEmptyAllUsersState(context);
    }

    return _buildAnalysisList(context, state.allUsersAnalysis, isMyAnalysis: false);
  }

  Widget _buildEmptyMyAnalysisState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library,
                size: 50,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'У вас пока нет анализов',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Сфотографируйте ваше первое блюдо\nдля анализа ингредиентов',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('Сделать первый анализ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAllUsersState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 50,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Пока нет анализов других пользователей',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Здесь будут отображаться анализы всех пользователей приложения',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error, int currentTab) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ошибка загрузки',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<AnalysisHistoryBloc>().add(AnalysisHistoryRefreshed());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisList(BuildContext context, List<dynamic> analyses, {required bool isMyAnalysis}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: analyses.length,
      itemBuilder: (context, index) {
        final analysis = analyses[index];
        return _buildAnalysisItem(context, analysis, isMyAnalysis: isMyAnalysis);
      },
    );
  }

  Widget _buildAnalysisItem(BuildContext context, Map<String, dynamic> analysis, {required bool isMyAnalysis}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final dishName = analysis['detected_dish'] ?? 'Неизвестное блюдо';
    final confidence = (analysis['confidence'] ?? 0.0).toDouble();
    final date = DateTime.parse(analysis['created_at']);
    final ingredients = analysis['ingredients'] ?? {};
    final basicIngredients = List<String>.from(ingredients['basic'] ?? []);
    final userName = analysis['user_name'] ?? 'Пользователь';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getConfidenceColor(confidence, colorScheme),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(confidence * 100).toInt()}',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          dishName,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMyAnalysis) ...[
              Text(
                userName,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              '${basicIngredients.length} основных ингредиентов',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(date),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          context.read<AnalysisHistoryBloc>().add(
            AnalysisHistoryShowDetails(
              analysis: analysis,
              isMyAnalysis: isMyAnalysis,
            ),
          );
        },
        onLongPress: isMyAnalysis ? () {
          context.read<AnalysisHistoryBloc>().add(
            AnalysisHistoryShowOptions(analysis),
          );
        } : null,
      ),
    );
  }

  Color _getConfidenceColor(double confidence, ColorScheme colorScheme) {
    if (confidence > 0.7) return colorScheme.primary;
    if (confidence > 0.4) return colorScheme.secondary;
    return colorScheme.error;
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

  void _showAnalysisDetails(BuildContext context, Map<String, dynamic> analysis, bool isMyAnalysis) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final dishName = analysis['detected_dish'] ?? 'Неизвестное блюдо';
    final confidence = (analysis['confidence'] ?? 0.0).toDouble();
    final ingredients = analysis['ingredients'] ?? {};
    final basicIngredients = List<String>.from(ingredients['basic'] ?? []);
    final additionalIngredients = List<String>.from(ingredients['additional'] ?? []);
    final alternatives = analysis['alternatives_found'] ?? {};
    final userName = analysis['user_name'] ?? 'Пользователь';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          title: Text(
            dishName,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMyAnalysis) ...[
                  Text(
                    'Пользователь: $userName',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(confidence, colorScheme).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Уверенность: ${(confidence * 100).toStringAsFixed(1)}%',
                        style: textTheme.bodySmall?.copyWith(
                          color: _getConfidenceColor(confidence, colorScheme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                const Text(
                  'Основные ингредиенты:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...basicIngredients.map((ingredient) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text('• $ingredient'),
                )),
                
                if (additionalIngredients.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Дополнительные ингредиенты:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...additionalIngredients.map((ingredient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text('• $ingredient'),
                  )),
                ],
                
                if (isMyAnalysis && _hasAvailableProducts(alternatives)) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.read<AnalysisHistoryBloc>().add(
                          AnalysisHistoryAddAllToCart(alternatives),
                        );
                      },
                      child: const Text('Добавить все в корзину'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (isMyAnalysis) 
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<AnalysisHistoryBloc>().add(
                    AnalysisHistoryDeleteRequested(analysis['id']),
                  );
                },
                child: Text(
                  'Удалить',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    });
  }

  void _showMyAnalysisOptions(BuildContext context, Map<String, dynamic> analysis) {
    final colorScheme = Theme.of(context).colorScheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
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
}