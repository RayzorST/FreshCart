// image_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'analysis_screen.dart';

class ImagePickerScreen extends StatelessWidget {
  const ImagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Анализ блюда'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Переход на историю анализов
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (context) => AnalysisHistoryScreen()
              // ));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_camera, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Сфотографируйте ваше блюдо',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ИИ определит блюдо и подберет\nнужные ингредиенты из магазина',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: FilledButton.icon(
                onPressed: () => _pickImage(ImageSource.camera, context),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Сфотографировать'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery, context),
                icon: const Icon(Icons.photo_library),
                label: const Text('Выбрать из галереи'),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                _showExampleResults(context);
              },
              child: const Text('Посмотреть пример анализа'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisScreen(imageFile: image),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _showExampleResults(BuildContext context) {
    // Показываем пример анализа для демонстрации
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisScreen(imagePath: 'example'),
      ),
    );
  }
}