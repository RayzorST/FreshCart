import 'package:client/domain/entities/product_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/product/bloc/product_bloc.dart';
import 'package:client/core/di/di.dart';
import 'package:client/domain/repositories/cart_repository.dart';
import 'package:client/domain/repositories/favorite_repository.dart';

class ProductScreen extends StatelessWidget {
  final ProductEntity product;
  
  const ProductScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductBloc(
        product, 
        getIt<CartRepository>(), 
        getIt<FavoriteRepository>()
      )
        ..add(ProductLoadFavoriteStatus())
        ..add(ProductLoadCartQuantity()),
      child: _ProductScreenContent(product: product),
    );
  }
}

class _ProductScreenContent extends StatelessWidget {
  final ProductEntity product;

  const _ProductScreenContent({required this.product});

  @override
  Widget build(BuildContext context) {
    final price = product.price;
    final stockQuantity = product.stockQuantity;
    final isAvailable = stockQuantity > 0;
    final maxQuantity = stockQuantity;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Детали товара',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppSnackbar.showError(context: context, message: state.errorMessage!);
            context.read<ProductBloc>().add(ProductLoadFavoriteStatus());
            context.read<ProductBloc>().add(ProductLoadCartQuantity());
          }
        },
        child: Column(
          children: [
            _buildProductCard(context),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
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
                      _buildHeaderSection(context),
                      
                      const SizedBox(height: 24),
                      
                      _buildPriceRatingSection(context, price),
                      
                      const SizedBox(height: 8),
                             
                      _buildStockInfo(isAvailable, stockQuantity),
                      
                      const SizedBox(height: 32),
                              
                      _buildDescriptionSection(context),
                      
                      // TODO: Добавить характеристики если они появятся в Product
                      // const SizedBox(height: 32),
                      // if (product.characteristics != null)
                      //   _buildCharacteristicsSection(context),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomPanel(context, isAvailable, maxQuantity),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.food_bank,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
    
          // TODO: Добавить скидку если она появится в Product
          // if (product.discount != null)
          //   Positioned(
          //     top: 20,
          //     left: 20,
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //       decoration: BoxDecoration(
          //         gradient: LinearGradient(
          //           colors: [Colors.red, Colors.orange],
          //           begin: Alignment.topLeft,
          //           end: Alignment.bottomRight,
          //         ),
          //         borderRadius: BorderRadius.circular(16),
          //         boxShadow: [
          //           BoxShadow(
          //             color: Colors.red.withOpacity(0.3),
          //             blurRadius: 8,
          //             offset: const Offset(0, 2),
          //           ),
          //         ],
          //       ),
          //       child: Text(
          //         '-${product.discount}%',
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 14,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              if (product.category != null && product.category!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    product.category!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.isLoadingFavorite ? null : () {
                context.read<ProductBloc>().add(ProductToggleFavorite());
                final message = state.isFavorite 
                    ? '${product.name} удален из избранного'
                    : '${product.name} добавлен в избранное';
                AppSnackbar.showInfo(context: context, message: message);
              },
              icon: state.isLoadingFavorite
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        state.isFavorite ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(state.isFavorite),
                        color: state.isFavorite 
                            ? Colors.red 
                            : Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceRatingSection(BuildContext context, double price) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$price ₽',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        // TODO: Добавить рейтинг если он появится в Product
        // if (product.rating != null)
        //   Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //     decoration: BoxDecoration(
        //       color: Colors.amber.withOpacity(0.1),
        //       borderRadius: BorderRadius.circular(8),
        //       border: Border.all(color: Colors.amber.withOpacity(0.3)),
        //     ),
        //     child: Row(
        //       children: [
        //         Icon(
        //           Icons.star,
        //           color: Colors.amber,
        //           size: 18,
        //         ),
        //         const SizedBox(width: 4),
        //         Text(
        //           product.rating.toString(),
        //           style: TextStyle(
        //             fontWeight: FontWeight.w600,
        //             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
      ],
    );
  }

  Widget _buildStockInfo(bool isAvailable, int stockQuantity) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isAvailable ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isAvailable 
              ? 'В наличии • $stockQuantity шт.' 
              : 'Нет в наличии',
          style: TextStyle(
            color: isAvailable ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Описание',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            product.description.isNotEmpty ? product.description : 'Описание отсутствует',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  // TODO: Восстановить если добавятся характеристики
  // Widget _buildCharacteristicsSection(BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Icon(
  //             Icons.list_alt,
  //             color: Theme.of(context).colorScheme.primary,
  //             size: 20,
  //           ),
  //           const SizedBox(width: 8),
  //           Text(
  //             'Характеристики',
  //             style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 12),
  //       Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: Theme.of(context).colorScheme.background,
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(
  //             color: Theme.of(context).dividerColor.withOpacity(0.3),
  //           ),
  //         ),
  //         child: Column(
  //           children: product.characteristics!.entries.map((entry) => 
  //             Padding(
  //               padding: const EdgeInsets.symmetric(vertical: 6),
  //               child: Row(
  //                 children: [
  //                   Expanded(
  //                     flex: 2,
  //                     child: Text(
  //                       '${entry.key}:',
  //                       style: TextStyle(
  //                         fontWeight: FontWeight.w600,
  //                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
  //                       ),
  //                     ),
  //                   ),
  //                   Expanded(
  //                     flex: 3,
  //                     child: Text(
  //                       entry.value.toString(),
  //                       style: TextStyle(
  //                         color: Theme.of(context).colorScheme.onSurface,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             )
  //           ).toList(),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildBottomPanel(BuildContext context, bool isAvailable, int maxQuantity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                color: state.quantity > 0 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: state.quantity > 0
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  IconButton(
                    onPressed: state.isLoadingCart || state.quantity == 0 ? null : () {
                      context.read<ProductBloc>().add(
                        ProductUpdateCartQuantity(state.quantity - 1)
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: state.quantity > 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 20,
                        color: state.quantity > 0
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ),
                  state.isLoadingCart
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.quantity > 0 ? '${_getQuantityText(state.quantity)}' : 'Добавить',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: state.quantity > 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            if (state.quantity > 0)
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
                    onPressed: state.isLoadingCart || !isAvailable || state.quantity >= maxQuantity ? null : () {
                      context.read<ProductBloc>().add(
                        ProductUpdateCartQuantity(state.quantity + 1)
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isAvailable && state.quantity < maxQuantity
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 20,
                        color: isAvailable && state.quantity < maxQuantity
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getQuantityText(int quantity) {
    if (quantity == 1) return '1 товар';
    if (quantity >= 2 && quantity <= 4) return '$quantity товара';
    return '$quantity товаров';
  }
}