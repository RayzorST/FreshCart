import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/core/providers/products_provider.dart';
import 'package:client/api/client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CategoryFilterWidget extends ConsumerWidget {
  const CategoryFilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final sharedPrefsAsync = ref.watch(sharedPreferencesProvider);
    final isExpanded = kIsWeb ? true : ref.watch(isCategoriesExpandedProvider);

    if (!kIsWeb) {
      final sharedPrefsAsync = ref.watch(sharedPreferencesProvider);
      sharedPrefsAsync.whenData((sharedPrefs) {
        final savedState = sharedPrefs.getBool('categories_expanded');
        if (savedState != null) {
          final currentState = ref.read(isCategoriesExpandedProvider);
          if (currentState != savedState) {
            ref.read(isCategoriesExpandedProvider.notifier).state = savedState;
          }
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 0,
      children: [   
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              Text(
                'Категории',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (!kIsWeb)
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  onPressed: () {
                    _toggleExpandedState(ref, !isExpanded, sharedPrefsAsync);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
            ],
          ),
        ),
        
        
        if (isExpanded)
          categoriesAsync.when(
            loading: () => _buildCategoriesLoading(),
            error: (error, stack) => _buildCategoriesError(error, context),
            data: (categories) => _buildCategoriesGrid(categories, selectedCategory, ref, context),
          )
        else
          _buildCollapsedCategory(categoriesAsync, selectedCategory, ref, context),
      ],
    );
  }
  
  void _toggleExpandedState(WidgetRef ref, bool newState, AsyncValue<SharedPreferences> sharedPrefsAsync) {
    if (kIsWeb) return;
    
    ref.read(isCategoriesExpandedProvider.notifier).state = newState;
    
    sharedPrefsAsync.whenData((sharedPrefs) {
      sharedPrefs.setBool('categories_expanded', newState);
    });
  }
  
  Widget _buildCollapsedCategory(
    AsyncValue<List<dynamic>> categoriesAsync,
    String selectedCategory,
    WidgetRef ref,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4, top: 0),
      child: categoriesAsync.when(
        loading: () => _buildCollapsedLoading(),
        error: (error, stack) => Container(),
        data: (categories) => _buildSelectedCategoryCard(categories, selectedCategory, ref, context),
      ),
    );
  }

  
  Widget _buildCollapsedLoading() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Text(
                'Загрузка категорий...',
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            Icon(Icons.arrow_drop_down, size: 24),
          ],
        ),
      ),
    );
  }

  
  Widget _buildSelectedCategoryCard(
    List<dynamic> categories,
    String selectedCategory,
    WidgetRef ref,
    BuildContext context,
  ) {
    
    Map<String, dynamic> selectedCategoryData;
    
    if (selectedCategory == '0') {
      
      selectedCategoryData = {
        'id': 0,
        'name': 'Все',
        'image_url': null,
      };
    } else {
      
      final category = categories.firstWhere(
        (cat) => cat['id'].toString() == selectedCategory,
        orElse: () => {
          'id': 0,
          'name': 'Все',
          'image_url': null,
        },
      );
      selectedCategoryData = category;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          
          final sharedPrefsAsync = ref.read(sharedPreferencesProvider);
          _toggleExpandedState(ref, true, sharedPrefsAsync);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: selectedCategoryData['id'] == 0
                    ? Center(
                        child: Icon(
                          Icons.all_inclusive,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      )
                    : selectedCategoryData['image_url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              '${ApiClient.baseUrl}/images/categories/${selectedCategoryData['id']}/image',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.category,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.category,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Text(
                  selectedCategoryData['name'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildCategoriesLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120, // Максимальная ширина категории
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: 1.0,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  height: 80,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 50,
                  color: Colors.grey[200],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesError(Object error, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 32),
              const SizedBox(height: 8),
              Text(
                'Ошибка загрузки',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red[700],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(
    List<dynamic> categories, 
    String selectedCategory, 
    WidgetRef ref, 
    BuildContext context,
  ) {
    
    final allCategories = [
      {
        'id': 0,
        'name': 'Все',
        'image_url': null,
      },
      ...categories,
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120,
          crossAxisSpacing: 7,
          mainAxisSpacing: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          
          final isSelected = selectedCategory == category['id'].toString();
          
          return _buildCategoryCard(category, isSelected, ref, context);
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category, 
    bool isSelected, 
    WidgetRef ref, 
    BuildContext context,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(selectedCategoryProvider.notifier).state = category['id'].toString();
          ref.read(searchQueryProvider.notifier).state = '';
          ref.refresh(productsProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: category['id'] == 0
                    ? Center(
                        child: Icon(
                          Icons.all_inclusive,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                      )
                    : category['image_url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              '${ApiClient.baseUrl}/images/categories/${category['id']}/image',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.category,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                    size: 28,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.category,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 28,
                            ),
                          ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  category['name'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}