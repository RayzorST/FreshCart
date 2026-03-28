import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/features/analysis/bloc/image_picker_bloc.dart';
import 'package:client/data/repositories/analysis_repository_impl.dart';
import 'package:client/domain/entities/analysis_result_entity.dart';
import 'package:client/core/widgets/screen_modal.dart';
import 'package:client/features/analysis/screens/analysis_history_screen.dart';
import 'package:client/features/analysis/screens/analysis_result_screen.dart';

class ImagePickerScreen extends StatelessWidget {
  const ImagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ImagePickerBloc(
        analysisRepository: AnalysisRepositoryImpl(),
      ),
      child: const _ImagePickerView(),
    );
  }
}

class _ImagePickerView extends StatelessWidget {
  const _ImagePickerView();

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return BlocListener<ImagePickerBloc, ImagePickerState>(
      listener: (context, state) {
        if (state is ImagePickerCaptureSuccess) {
          // Преобразуем AnalysisResultEntity в Map так же как в history
          final analysisResult = state.analysisResult;
          final resultData = _convertAnalysisResultToMap(analysisResult);
          
          if (isWideScreen) {
            // Для широких экранов открываем результат в модальном окне
            ScreenToModal.show(
              context: context,
              child: _buildAnalysisResultScreen(resultData),
              height: 0.95,
            );
          } else {
            // Для мобильных переходим на страницу
            context.push(
              '/analysis/result',
              extra: state.base64Image,  // <--- передаем строку с imageData
            );
          }
          
          // Сбрасываем состояние после перехода
          Future.delayed(const Duration(milliseconds: 300), () {
            context.read<ImagePickerBloc>().add(const ImagePickerClear());
          });
        }
      },
      child: Scaffold(
        appBar: isWideScreen ? null : AppBar(
          title: Text(
            'Анализ блюда',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary),
          ),
        ),
        body: _buildBody(context, isWideScreen),
      ),
    );
  }

  // Метод для преобразования AnalysisResultEntity в Map
  Map<String, dynamic> _convertAnalysisResultToMap(AnalysisResultEntity analysisResult) {
    return {
      'detected_dish': analysisResult.detectedDish,
      'confidence': analysisResult.confidence,
      'basic_ingredients': analysisResult.basicIngredients,
      'additional_ingredients': analysisResult.additionalIngredients,
      'basic_alternatives': _convertAlternativesToMap(analysisResult.basicAlternatives),
      'additional_alternatives': _convertAlternativesToMap(analysisResult.additionalAlternatives),
    };
  }

  // Метод для преобразования альтернатив в формат Map
  List<Map<String, dynamic>> _convertAlternativesToMap(List<dynamic> alternatives) {
    return alternatives.map((alt) {
      if (alt is Map<String, dynamic>) {
        return alt;
      } else {
        return {'ingredient': alt.toString(), 'products': []};
      }
    }).toList();
  }

  Widget _buildAnalysisResultScreen(Map<String, dynamic> resultData) {
    return AnalysisResultScreen(
      resultData: resultData,
      fromHistory: false,
    );
  }

  Widget _buildBody(BuildContext context, bool isWideScreen) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
      child: BlocBuilder<ImagePickerBloc, ImagePickerState>(
        builder: (context, state) {
          if (state is ImagePickerLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ImagePickerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ImagePickerBloc>().add(const ImagePickerClear());
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _ImagePickerContent(isWideScreen: isWideScreen);
        },
      ),
    );
  }
}

class _ImagePickerContent extends StatelessWidget {
  final bool isWideScreen;
  
  const _ImagePickerContent({required this.isWideScreen});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isWideScreen) {
      return _buildWideLayout(context, colorScheme, textTheme);
    } else {
      return _buildMobileLayout(context, colorScheme, textTheme);
    }
  }

  Widget _buildMobileLayout(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.photo_camera_outlined,
                size: 60,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Анализ блюда по фото',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            Text(
              'Сфотографируйте блюдо и ИИ определит его состав,\nа также подберет нужные ингредиенты из магазина',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            
            _buildImageSelectionButtons(context, isWideScreen: false),
            const SizedBox(height: 24),
            
            _buildAdditionalButtons(context, isWideScreen: false),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Заголовок
                Text(
                  'Анализ блюда по фото',
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Описание
                Text(
                  'Загрузите фото блюда и ИИ определит его состав,\nа также подберет нужные ингредиенты из магазина',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Кнопка загрузки из галереи
                Container(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ImagePickerBloc>().add(const ImagePickerGalleryRequested());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 4,
                      shadowColor: colorScheme.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.photo_library, size: 20, color: colorScheme.onPrimary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Загрузить фото из галереи',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Преимущества
                _buildFeaturesGrid(context, colorScheme, textTheme),
                const SizedBox(height: 40),
                
                // Инфо-блок
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Как это работает',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildStepItem(
                        context,
                        number: 1,
                        title: 'Загрузите фото',
                        description: 'Выберите фото блюда из галереи',
                      ),
                      const SizedBox(height: 12),
                      
                      _buildStepItem(
                        context,
                        number: 2,
                        title: 'ИИ анализирует',
                        description: 'Искусственный интеллект определит блюдо и ингредиенты',
                      ),
                      const SizedBox(height: 12),
                      
                      _buildStepItem(
                        context,
                        number: 3,
                        title: 'Получите результат',
                        description: 'Просмотрите анализ и добавьте продукты в корзину',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, {
    required int number,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelectionButtons(BuildContext context, {required bool isWideScreen}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isWideScreen) {
      // Только кнопка загрузки из галереи для веб-версии
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                context.read<ImagePickerBloc>().add(const ImagePickerGalleryRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 4,
                shadowColor: colorScheme.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library, size: 20, color: colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Загрузить фото из галереи',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Для мобильных: обе кнопки
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 60,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: () {
                context.read<ImagePickerBloc>().add(const ImagePickerCameraRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 4,
                shadowColor: colorScheme.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt, size: 20, color: colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Сфотографировать',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Container(
            width: double.infinity,
            height: 60,
            child: OutlinedButton(
              onPressed: () {
                context.read<ImagePickerBloc>().add(const ImagePickerGalleryRequested());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library, size: 20, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Выбрать из галереи',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFeaturesGrid(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Преимущества',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.auto_awesome,
              title: 'ИИ анализ',
              description: 'Определение блюда и ингредиентов',
              color: Colors.blue,
            ),
            _buildFeatureCard(
              context,
              icon: Icons.shopping_basket,
              title: 'Подбор продуктов',
              description: 'Найдет нужные ингредиенты в магазине',
              color: Colors.green,
            ),
            _buildFeatureCard(
              context,
              icon: Icons.history,
              title: 'История',
              description: 'Сохраняет все ваши анализы',
              color: Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              ScreenToModal.show(
                context: context,
                child: const AnalysisHistoryScreen(),
                height: 0.85,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              elevation: 2,
              shadowColor: colorScheme.shadow.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Открыть историю анализов',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.open_in_new, size: 16, color: colorScheme.primary.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalButtons(BuildContext context, {required bool isWideScreen}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          margin: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton(
            onPressed: () {
              if (isWideScreen) {
                // Для широких экранов открываем историю в модальном окне
                ScreenToModal.show(
                  context: context,
                  child: const AnalysisHistoryScreen(),
                  height: 0.85,
                );
              } else {
                // Для мобильных используем стандартный переход
                context.push('/analysis/history');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              elevation: 2,
              shadowColor: colorScheme.shadow.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'История блюд',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isWideScreen) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.open_in_new, size: 16, color: colorScheme.primary.withOpacity(0.7)),
                ],
              ],
            ),
          ),
        ),
        
        if (!isWideScreen) ...[
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ИИ анализирует изображение и определяет блюдо',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.shopping_basket, size: 16, color: colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Подбирает подходящие ингредиенты из магазина',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.history, size: 16, color: colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Сохраняет историю для быстрого доступа',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}