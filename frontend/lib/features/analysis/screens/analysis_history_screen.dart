// analysis_history_screen.dart
import 'package:flutter/material.dart';
import 'package:client/api/client.dart';

class AnalysisHistoryScreen extends StatefulWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  // Данные для вкладок
  List<dynamic> _myAnalysisHistory = [];
  List<dynamic> _allUsersAnalysis = [];
  bool _isLoadingMyHistory = true;
  bool _isLoadingAllUsers = true;
  String? _errorMyHistory;
  String? _errorAllUsers;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadMyAnalysisHistory();
    _loadAllUsersAnalysis();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTab = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyAnalysisHistory() async {
    try {
      final history = await ApiClient.getAnalysisHistory();
      setState(() {
        _myAnalysisHistory = history;
        _isLoadingMyHistory = false;
      });
    } catch (e) {
      setState(() {
        _errorMyHistory = 'Ошибка загрузки истории: $e';
        _isLoadingMyHistory = false;
      });
    }
  }

  Future<void> _loadAllUsersAnalysis() async {
    try {
      final allAnalysis = await ApiClient.getAnalysisHistory(); //ИСПРАВИТЬ
      setState(() {
        _allUsersAnalysis = allAnalysis;
        _isLoadingAllUsers = false;
      });
    } catch (e) {
      setState(() {
        _errorAllUsers = 'Ошибка загрузки анализов: $e';
        _isLoadingAllUsers = false;
      });
    }
  }

  void _refreshData() {
    if (_currentTab == 0) {
      setState(() {
        _isLoadingMyHistory = true;
        _errorMyHistory = null;
      });
      _loadMyAnalysisHistory();
    } else {
      setState(() {
        _isLoadingAllUsers = true;
        _errorAllUsers = null;
      });
      _loadAllUsersAnalysis();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История анализов'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: _refreshData,
            tooltip: 'Обновить',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.background,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Первая вкладка - Мои анализы
            _buildMyAnalysisTab(),
            
            // Вторая вкладка - Все анализы пользователей
            _buildAllUsersAnalysisTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyAnalysisTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _isLoadingMyHistory
        ? const Center(child: CircularProgressIndicator())
        : _errorMyHistory != null
            ? _buildErrorWidget(_errorMyHistory!, _loadMyAnalysisHistory)
            : _myAnalysisHistory.isEmpty
                ? _buildEmptyMyAnalysisState()
                : _buildAnalysisList(_myAnalysisHistory, isMyAnalysis: true);
  }

  Widget _buildAllUsersAnalysisTab() {
    return _isLoadingAllUsers
        ? const Center(child: CircularProgressIndicator())
        : _errorAllUsers != null
            ? _buildErrorWidget(_errorAllUsers!, _loadAllUsersAnalysis)
            : _allUsersAnalysis.isEmpty
                ? _buildEmptyAllUsersState()
                : _buildAnalysisList(_allUsersAnalysis, isMyAnalysis: false);
  }

  Widget _buildEmptyMyAnalysisState() {
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

  Widget _buildEmptyAllUsersState() {
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

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
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
              onPressed: onRetry,
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

  Widget _buildAnalysisList(List<dynamic> analyses, {required bool isMyAnalysis}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: analyses.length,
      itemBuilder: (context, index) {
        final analysis = analyses[index];
        return _buildAnalysisItem(analysis, isMyAnalysis: isMyAnalysis);
      },
    );
  }

  Widget _buildAnalysisItem(Map<String, dynamic> analysis, {required bool isMyAnalysis}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final dishName = analysis['detected_dish'] ?? 'Неизвестное блюдо';
    final confidence = (analysis['confidence'] ?? 0.0).toDouble();
    final date = DateTime.parse(analysis['created_at']);
    final ingredients = analysis['ingredients'] ?? {};
    final basicIngredients = List<String>.from(ingredients['basic'] ?? []);
    final userName = analysis['user_name'] ?? 'Пользователь';
    final userEmail = analysis['user_email'] ?? '';

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
          _showAnalysisDetails(analysis, isMyAnalysis: isMyAnalysis);
        },
        onLongPress: isMyAnalysis ? () {
          _showMyAnalysisOptions(analysis);
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

  void _showAnalysisDetails(Map<String, dynamic> analysis, {required bool isMyAnalysis}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final dishName = analysis['detected_dish'] ?? 'Неизвестное блюдо';
    final confidence = (analysis['confidence'] ?? 0.0).toDouble();
    final ingredients = analysis['ingredients'] ?? {};
    final basicIngredients = List<String>.from(ingredients['basic'] ?? []);
    final additionalIngredients = List<String>.from(ingredients['additional'] ?? []);
    final alternatives = analysis['alternatives_found'] ?? {};
    final userName = analysis['user_name'] ?? 'Пользователь';

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
                    onPressed: () => _addAllToCart(alternatives),
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
              onPressed: () => _deleteAnalysis(analysis['id']),
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
  }

  void _showMyAnalysisOptions(Map<String, dynamic> analysis) {
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
              leading: Icon(Icons.shopping_cart, color: colorScheme.primary),
              title: const Text('Добавить в корзину'),
              onTap: () {
                Navigator.pop(context);
                _addAllToCart(analysis['alternatives_found'] ?? {});
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
                _deleteAnalysis(analysis['id']);
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

  void _addAllToCart(Map<String, dynamic> alternatives) async {
    try {
      final basicAlts = List<dynamic>.from(alternatives['basic'] ?? []);
      final additionalAlts = List<dynamic>.from(alternatives['additional'] ?? []);
      
      int addedCount = 0;
      int skippedCount = 0;
      
      for (final alt in [...basicAlts, ...additionalAlts]) {
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
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при добавлении: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _deleteAnalysis(int analysisId) async {
    try {
      //await ApiClient.deleteAnalysisRecord(analysisId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Анализ удален'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _loadMyAnalysisHistory(); // Обновляем список
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}