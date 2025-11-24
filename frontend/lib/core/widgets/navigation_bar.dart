import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:client/api/client.dart';
import 'package:go_router/go_router.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;
  final bool isVertical;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
    required this.isVertical,
  });

  @override
  Widget build(BuildContext context) {
    //final isWideScreen = MediaQuery.of(context).size.width > 600;

    return isVertical 
        ? _buildSideNavigation(context)
        : _buildBottomNavigation(context);
  }

  Widget _buildSideNavigation(BuildContext context) {
    final isWeb = kIsWeb;

    return SizedBox(
      width: isWeb ? 200 : 80,
      child: Column(
        children: [
          if (isWeb)
            Container(
              height: 80,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'FreshCart',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildWebNavItem(
                      context: context,
                      icon: Icons.home,
                      label: 'Главная',
                      index: 0,
                      currentIndex: currentIndex,
                      onTap: () => onItemTapped(0),
                    ),
                    _buildWebNavItem(
                      context: context,
                      icon: Icons.shopping_cart,
                      label: 'Корзина',
                      index: 1,
                      currentIndex: currentIndex,
                      onTap: () => onItemTapped(1),
                    ),
                    _buildWebNavItem(
                      context: context,
                      icon: Icons.favorite,
                      label: 'Избранное',
                      index: 2,
                      currentIndex: currentIndex,
                      onTap: () => onItemTapped(2),
                    ),
                    _buildWebNavItem(
                      context: context,
                      icon: Icons.person,
                      label: 'Профиль',
                      index: 3,
                      currentIndex: currentIndex,
                      onTap: () => onItemTapped(3),
                    ),
                    if (isWeb)
                      _buildWebNavItem(
                        context: context,
                        icon: Icons.photo,
                        label: 'Анализатор блюд',
                        index: 4,
                        currentIndex: currentIndex,
                        onTap: () => context.push('/analysis/camera'),
                      ),
                      FutureBuilder<bool>(
                        future: ApiClient.isUserAdmin(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox();
                          }
                          
                          if (snapshot.hasData && snapshot.data == true) {
                            return _buildWebNavItem(
                              context: context,
                              icon: Icons.admin_panel_settings,
                              label: 'Админ панель',
                              index: 4,
                              currentIndex: currentIndex,
                              onTap: () => onItemTapped(4),
                            );
                          }
                          
                          return const SizedBox();
                        },
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

  Widget _buildWebNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;
    final isWeb = kIsWeb;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  size: 20,
                ),
                if (isWeb) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 66,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home,
                  label: 'Главная',
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: () => onItemTapped(0),
                  isVertical: false,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.shopping_cart,
                  label: 'Корзина',
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: () => onItemTapped(1),
                  isVertical: false,
                ),
                
                const SizedBox(width: 60),
                
                _buildNavItem(
                  context: context,
                  icon: Icons.favorite,
                  label: 'Избранное',
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: () => onItemTapped(2),
                  isVertical: false,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person,
                  label: 'Профиль',
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: () => onItemTapped(3),
                  isVertical: false,
                ),
              ],
            ),
          ),
        ),
        // Область SafeArea с таким же цветом
        Container(
          height: bottomPadding,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
    required bool isVertical,
  }) {
    final isSelected = currentIndex == index;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Container(
              padding: isVertical 
                  ? const EdgeInsets.symmetric(vertical: 12, horizontal: 4)
                  : const EdgeInsets.symmetric(vertical: 8),
              child: isVertical
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}