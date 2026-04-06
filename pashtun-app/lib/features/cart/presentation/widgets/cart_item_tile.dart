import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/cart_item.dart';
import '../../providers/cart_provider.dart';

class CartItemTile extends ConsumerWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(item.lineId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.saleRed,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) =>
          ref.read(cartProvider.notifier).removeItem(item.lineId),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: 80,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.accent, width: 80, height: 100),
                    )
                  : Container(
                      width: 80,
                      height: 100,
                      color: AppColors.accent,
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productTitle,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.variantTitle != null &&
                      item.variantTitle != 'Default Title') ...[
                    const SizedBox(height: 4),
                    Text(
                      item.variantTitle!,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                  // Variant options
                  if (item.selectedOptions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.selectedOptions
                          .map((o) => '${o.name}: ${o.value}')
                          .join(' · '),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        CurrencyFormatter.formatShopify(
                          item.price.amount.toString(),
                          item.price.currencyCode,
                        ),
                        style: AppTextStyles.priceTag.copyWith(fontSize: 15),
                      ),
                      // Quantity controls
                      _QuantityControl(item: item),
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

class _QuantityControl extends ConsumerWidget {
  final CartItem item;

  const _QuantityControl({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _QtyButton(
          icon: Icons.remove,
          onTap: () => ref.read(cartProvider.notifier).updateQuantity(
                item.lineId,
                item.quantity - 1,
              ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '${item.quantity}',
            style: AppTextStyles.labelLarge,
          ),
        ),
        _QtyButton(
          icon: Icons.add,
          onTap: () => ref.read(cartProvider.notifier).updateQuantity(
                item.lineId,
                item.quantity + 1,
              ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
