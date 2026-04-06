import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/cart_item.dart';

const _freeShippingThresholdInr = 999.0;

class CartSummary extends StatelessWidget {
  final CartState cartState;

  const CartSummary({super.key, required this.cartState});

  @override
  Widget build(BuildContext context) {
    final currency = cartState.currencyCode;
    final isIndia = currency == 'INR';
    final shippingFree = isIndia &&
        cartState.subtotal >= _freeShippingThresholdInr;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          _Row(
            label: 'Subtotal',
            value: CurrencyFormatter.formatShopify(
              cartState.subtotal.toString(),
              currency,
            ),
          ),
          if (cartState.discount != null && cartState.discount! > 0)
            _Row(
              label: 'Discount',
              value: '− ${CurrencyFormatter.formatShopify(
                cartState.discount!.toString(),
                currency,
              )}',
              valueStyle: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.saleRed),
            ),
          _Row(
            label: 'Shipping',
            value: shippingFree ? 'FREE' : 'Calculated at checkout',
            valueStyle: shippingFree
                ? AppTextStyles.bodyMedium.copyWith(color: Colors.green)
                : null,
          ),
          if (isIndia && !shippingFree)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Free shipping on orders above ₹999',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          const Divider(height: 24),
          _Row(
            label: 'Total',
            value: CurrencyFormatter.formatShopify(
              cartState.total.toString(),
              currency,
            ),
            labelStyle: AppTextStyles.titleLarge,
            valueStyle: AppTextStyles.priceTag,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _Row({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle ?? AppTextStyles.bodyMedium),
          Text(value, style: valueStyle ?? AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
