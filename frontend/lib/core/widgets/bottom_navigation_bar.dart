import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentIndexProvider = StateProvider<int>((ref) => 0);

class CustomBottomNavigationBar extends ConsumerWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentIndexProvider);

    return Container(
      height: 77,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
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
              onTap: () => ref.read(currentIndexProvider.notifier).state = 0,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.shopping_cart,
              label: 'Корзина',
              index: 1,
              currentIndex: currentIndex,
              onTap: () => ref.read(currentIndexProvider.notifier).state = 1,
            ),
            
            const SizedBox(width: 60),
            
            _buildNavItem(
              context: context,
              icon: Icons.favorite,
              label: 'Избранное',
              index: 2,
              currentIndex: currentIndex,
              onTap: () => ref.read(currentIndexProvider.notifier).state = 2,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.person,
              label: 'Профиль',
              index: 3,
              currentIndex: currentIndex,
              onTap: () => ref.read(currentIndexProvider.notifier).state = 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
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