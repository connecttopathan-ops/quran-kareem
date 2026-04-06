import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/wishlist_provider.dart';
import '../../shop/providers/products_provider.dart';
import '../../shop/presentation/widgets/product_card.dart';
import 'package:go_router/go_router.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistIds = ref.watch(wishlistProvider);

    if (wishlistIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Wishlist', style: AppTextStyles.headlineMedium),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border,
                  size: 72, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('Your wishlist is empty',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text('Save items you love for later.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              AppButton(
                label: 'Explore Collections',
                width: 200,
                onPressed: () => context.go('/shop'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wishlist (${wishlistIds.length})',
          style: AppTextStyles.headlineMedium,
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
        ),
        itemCount: wishlistIds.length,
        itemBuilder: (_, i) {
          final productId = wishlistIds.elementAt(i);
          // We show a product card by loading from cached provider
          // For simplicity, use a placeholder since we store IDs not handles
          return _WishlistItem(productId: productId);
        },
      ),
    );
  }
}

class _WishlistItem extends ConsumerWidget {
  final String productId;

  const _WishlistItem({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is a simplified display — in production you'd persist handles too
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image, size: 48, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(
            'Saved Item',
            style: AppTextStyles.bodySmall,
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: AppColors.saleRed),
            onPressed: () =>
                ref.read(wishlistProvider.notifier).toggle(productId),
          ),
        ],
      ),
    );
  }
}
