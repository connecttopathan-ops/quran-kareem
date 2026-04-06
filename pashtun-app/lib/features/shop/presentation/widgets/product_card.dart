import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../wishlist/providers/wishlist_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final isWishlisted = wishlist.contains(product.id);

    return GestureDetector(
      onTap: () => context.push('/product/${product.handle}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: product.firstImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.firstImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: AppColors.accent),
                            errorWidget: (_, __, ___) =>
                                Container(color: AppColors.accent),
                          )
                        : Container(
                            color: AppColors.accent,
                            child: const Icon(Icons.image_not_supported,
                                color: AppColors.textHint),
                          ),
                  ),
                  // Badges
                  Positioned(
                    top: 8,
                    left: 8,
                    child: product.isOnSale
                        ? SaleBadge(percent: product.discountPercent)
                        : const SizedBox.shrink(),
                  ),
                  // Wishlist button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _WishlistButton(
                      productId: product.id,
                      isWishlisted: isWishlisted,
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.formatShopify(
                          product.minPrice.amount.toString(),
                          product.minPrice.currencyCode,
                        ),
                        style: AppTextStyles.priceTag,
                      ),
                      if (product.isOnSale) ...[
                        const SizedBox(width: 6),
                        Text(
                          CurrencyFormatter.formatShopify(
                            product.compareAtMinPrice!.amount.toString(),
                            product.compareAtMinPrice!.currencyCode,
                          ),
                          style: AppTextStyles.priceSale,
                        ),
                      ],
                    ],
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

class _WishlistButton extends ConsumerWidget {
  final String productId;
  final bool isWishlisted;

  const _WishlistButton({
    required this.productId,
    required this.isWishlisted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(wishlistProvider.notifier).toggle(productId),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isWishlisted ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isWishlisted ? AppColors.saleRed : AppColors.textSecondary,
        ),
      ),
    );
  }
}
