import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/api/client.dart';

class ProductScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;
  
  const ProductScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  int _quantity = 0;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  bool _isLoadingCart = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadCartQuantity();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      setState(() => _isLoadingFavorite = true);
      final response = await ApiClient.checkFavorite(widget.product['id']);
      setState(() => _isFavorite = response['is_favorite'] ?? false);
    } catch (e) {
      print('Error checking favorite: $e');
    } finally {
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _loadCartQuantity() async {
    try {
      final cartResponse = await ApiClient.getCart();
      final cartItems = cartResponse['items'] ?? [];
      
      final cartItem = cartItems.firstWhere(
        (item) => item['product_id'] == widget.product['id'],
        orElse: () => null,
      );
      
      if (cartItem != null) {
        setState(() => _quantity = cartItem['quantity'] ?? 0);
      }
    } catch (e) {
      print('Error loading cart quantity: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      setState(() => _isLoadingFavorite = true);
      
      if (_isFavorite) {
        await ApiClient.removeFromFavorites(widget.product['id']);
        setState(() => _isFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product['name']} удален из избранного'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await ApiClient.addToFavorites(widget.product['id']);
        setState(() => _isFavorite = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product['name']} добавлен в избранное'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _updateCartQuantity(int newQuantity) async {
    if (_isLoadingCart) return;
    
    try {
      setState(() => _isLoadingCart = true);
      
      if (newQuantity == 0) {
        await ApiClient.removeFromCart(widget.product['id']);
      } else if (_quantity == 0) {
        await ApiClient.addToCart(widget.product['id'], newQuantity);
      } else {
        await ApiClient.updateCartItem(widget.product['id'], newQuantity);
      }
      
      setState(() => _quantity = newQuantity);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при обновлении корзины: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoadingCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.product['price'] is int ? 
        (widget.product['price'] as int).toDouble() : 
        (widget.product['price'] as num).toDouble();
    
    final stockQuantity = widget.product['stock_quantity'] ?? 0;
    final isAvailable = stockQuantity > 0;
    final maxQuantity = stockQuantity;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Детали товара'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: widget.product['image_url'] != null
                        ? Image.network(
                            '${ApiClient.baseUrl}${widget.product['image_url']}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.food_bank,
                                size: 80,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              );
                            },
                          )
                        : Icon(
                            Icons.food_bank,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ),
                  ),
                ),
                if (widget.product['discount'] != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-${widget.product['discount']}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product['name'],
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.product['category']?['name'] ?? 'Без категории',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                          icon: _isLoadingFavorite
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: _isFavorite 
                                      ? Colors.red 
                                      : Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Text(
                          '$price ₽',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (widget.product['rating'] != null)
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.product['rating'].toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: isAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAvailable 
                              ? 'В наличии ($stockQuantity шт.)' 
                              : 'Нет в наличии',
                          style: TextStyle(
                            color: isAvailable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Описание',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.product['description'] ?? 'Описание отсутствует',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    if (widget.product['characteristics'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Характеристики',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.product['characteristics'].entries.map((entry) => 
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    '${entry.key}: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                  Text(entry.value.toString()),
                                ],
                              ),
                            )
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity, 
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _isLoadingCart || _quantity == 0 ? null : () {
                        _updateCartQuantity(_quantity - 1);
                      },
                      icon: Icon(
                        Icons.remove,
                        size: 24,
                        color: _isLoadingCart || _quantity == 0
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      padding: const EdgeInsets.all(16),
                    ),

                    _isLoadingCart
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_quantity',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _quantity > 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              Text(
                                'в корзине',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),

                    IconButton(
                      onPressed: _isLoadingCart || !isAvailable || _quantity >= maxQuantity ? null : () {
                        _updateCartQuantity(_quantity + 1);
                      },
                      icon: Icon(
                        Icons.add,
                        size: 24,
                        color: _isLoadingCart || !isAvailable || _quantity >= maxQuantity
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}