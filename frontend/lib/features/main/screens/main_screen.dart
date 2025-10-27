import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Добавь этот импорт
import 'package:client/features/cart/screens/cart_screen.dart';
import 'package:client/features/main/screens/favorites_screen.dart';
import 'package:client/features/profile/screens/profile_screen.dart';
import 'package:client/core/widgets/bottom_navigation_bar.dart';
import 'package:client/core/widgets/camera_fab.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  String _selectedCategory = 'Все';
  final List<String> _categories = [
    'Все',
    'Овощи',
    'Фрукты',
    'Молочные',
    'Мясо',
    'Рыба',
    'Бакалея',
  ];

  final List<Map<String, dynamic>> _promotions = [
    {
      'id': '1',
      'title': 'Скидка 20%',
      'color': Colors.green,
    },
    {
      'id': '2', 
      'title': 'Акция на мясо',
      'color': Colors.red,
    },
    {
      'id': '3',
      'title': 'Фруктовая неделя',
      'color': Colors.orange,
    },
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'Помидоры',
      'description': 'Свежие помидоры черри',
      'price': 299,
      'category': 'Овощи',
      'image': 'assets/products/tomatoes.jpg',
    },
    {
      'id': '2',
      'name': 'Яблоки Голден',
      'description': 'Сладкие яблоки из Краснодара',
      'price': 189,
      'category': 'Фрукты',
      'image': 'assets/products/apples.jpg',
    },
    {
      'id': '3',
      'name': 'Молоко',
      'description': 'Молоко 3.2%, 1л',
      'price': 89,
      'category': 'Молочные',
      'image': 'assets/products/milk.jpg',
    },
    {
      'id': '4',
      'name': 'Куриное филе',
      'description': 'Свежее куриное филе, 1кг',
      'price': 450,
      'category': 'Мясо',
      'image': 'assets/products/chicken.jpg',
    },
    {
      'id': '5',
      'name': 'Лосось',
      'description': 'Свежий лосось, 1кг',
      'price': 1200,
      'category': 'Рыба',
      'image': 'assets/products/salmon.jpg',
    },
    {
      'id': '6',
      'name': 'Рис',
      'description': 'Рис пропаренный, 1кг',
      'price': 150,
      'category': 'Бакалея',
      'image': 'assets/products/rice.jpg',
    },
  ];

  void _onProductTap(Map<String, dynamic> product) {
    context.push('/product/${product['id']}', extra: product);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentIndexProvider);
    
    final List<Widget> screens = [
      _buildHomeScreen(),
      const CartScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: const CustomBottomNavigationBar(),
      floatingActionButton: const CameraFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHomeScreen() {
    final filteredProducts = _selectedCategory == 'Все'
        ? _products
        : _products.where((p) => p['category'] == _selectedCategory).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(
            'Продуктовый маркет',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
          floating: true,
          snap: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Реализовать поиск
              },
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Акции',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_promotions.length}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _promotions.length,
                    itemBuilder: (context, index) {
                      final promotion = _promotions[index];
                      return _buildPromotionCard(promotion, context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Фильтр:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (String newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  surfaceTintColor: Colors.transparent,
                  constraints: const BoxConstraints(
                    minWidth: 150,
                    maxWidth: 150,
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.green, width: 1.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (BuildContext context) => _categories.map((String category) {
                    return PopupMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedCategory,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Все продукты',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${filteredProducts.length} товаров',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = filteredProducts[index];
                return _buildProductCard(product);
              },
              childCount: filteredProducts.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    int quantity = 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onProductTap(product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: Icon(
                  Icons.fastfood,
                  size: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product['name'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${product['price']} ₽',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                height: 35,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove,
                        size: 18,
                        color: quantity > 0 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      onPressed: quantity > 0 ? () {
                        setState(() {
                          quantity--;
                        });
                      } : null,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    
                    Container(
                      width: 30,
                      alignment: Alignment.center,
                      child: Text(
                        quantity > 0 ? quantity.toString() : '0',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          quantity++;
                        });
                      },
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion, BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/promotion/${promotion['id']}');
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              promotion['color'].withOpacity(0.2),
              promotion['color'].withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: promotion['color'].withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Icon(
                Icons.local_offer_outlined,
                size: 80,
                color: promotion['color'].withOpacity(0.2),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  promotion['title'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: promotion['color'],
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}