import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 80,
    );
    
    if (photo != null && mounted) {
      // TODO: Переход на экран анализа с передачей фото
      context.push('/analysis', extra: photo.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    
    if (image != null && mounted) {
      // TODO: Переход на экран анализа с передачей фото
      context.push('/analysis', extra: image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сфотографируйте блюдо'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Сфотографируйте блюдо для анализа',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: FilledButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera),
                label: const Text('Сделать фото'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Из галереи'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}