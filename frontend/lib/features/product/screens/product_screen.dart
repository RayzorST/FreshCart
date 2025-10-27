import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductScreen extends ConsumerWidget {
  final Map<String, dynamic> product;
  
  const ProductScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Убираем заглушку _getProductById и используем переданный продукт
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка товара'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение товара
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[200],
              child: const Icon(Icons.food_bank, size: 80, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'], // используем переданный продукт
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['category'], // используем переданный продукт
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${product['price']} ₽', // используем переданный продукт
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Описание товара',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['description'], // используем переданный продукт
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product['name']} добавлен в корзину')),
                        );
                      },
                      child: const Text('Добавить в корзину'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}