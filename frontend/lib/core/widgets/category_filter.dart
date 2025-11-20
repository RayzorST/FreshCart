import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/api/client.dart';
import 'package:client/features/main/bloc/main_bloc.dart';

class CategoryFilterWidget extends StatelessWidget {
  const CategoryFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    
    return BlocBuilder<MainBloc, MainState>(
      builder: (context, state) {
        final isExpanded = isWideScreen ? true : state.isCategoriesExpanded;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                  if (!isWideScreen)
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                      ),
                      onPressed: () {
                        context.read<MainBloc>().add(
                          CategoriesExpandedToggled(!isExpanded),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                ],
              ),
            ),
            
            if (isExpanded)
              _buildCategoriesContent(state, context)
            else
              _buildCollapsedCategory(state, context),
          ],
        );
      },
    );
  }

  Widget _buildCollapsedCategory(MainState state, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4, top: 0),
      child: _buildSelectedCategoryCard(state, context),
    );
  }

  Widget _buildSelectedCategoryCard(MainState state, BuildContext context) {
    Map<String, dynamic> selectedCategoryData;
    
    if (state.selectedCategoryId == '0') {
      selectedCategoryData = {
        'id': 0,
        'name': 'Все',
        'image_url': null,
      };
    } else {
      final category = state.categories.firstWhere(
        (cat) => cat['id'].toString() == state.selectedCategoryId,
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
      color: null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.read<MainBloc>().add(const CategoriesExpandedToggled(true));
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

  Widget _buildCategoriesContent(MainState state, BuildContext context) {
    if (state.categoriesStatus == MainStatus.loading) {
      return _buildCategoriesLoading();
    }

    if (state.categoriesStatus == MainStatus.error) {
      return _buildCategoriesError(state.categoriesError ?? 'Ошибка загрузки', context);
    }

    return _buildCategoriesGrid(state, context);
  }

  Widget _buildCategoriesLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120,
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

  Widget _buildCategoriesError(String error, BuildContext context) {
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

  Widget _buildCategoriesGrid(MainState state, BuildContext context) {
    final allCategories = [
      {
        'id': 0,
        'name': 'Все',
        'image_url': null,
      },
      ...state.categories,
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120,
          crossAxisSpacing: 7,
          mainAxisSpacing: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = state.selectedCategoryId == category['id'].toString();
          return _buildCategoryCard(category, isSelected, context);
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category, 
    bool isSelected, 
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
          context.read<MainBloc>().add(CategorySelected(category['id'].toString()));
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