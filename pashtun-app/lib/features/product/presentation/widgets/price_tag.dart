import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/product.dart';

class PriceTag extends StatelessWidget {
  final Money price;
  final Money? compareAtPrice;

  const PriceTag({super.key, required this.price, this.compareAtPrice});

  @override
  Widget build(BuildContext context) {
    final isOnSale = compareAtPrice != null &&
        compareAtPrice!.amount > price.amount;
    final percent = isOnSale
        ? CurrencyFormatter.discountPercent(
            compareAtPrice!.amount, price.amount)
        : 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          CurrencyFormatter.formatShopify(
            price.amount.toString(),
            price.currencyCode,
          ),
          style: AppTextStyles.displayMedium.copyWith(fontSize: 22),
        ),
        if (isOnSale) ...[
          const SizedBox(width: 10),
          Text(
            CurrencyFormatter.formatShopify(
              compareAtPrice!.amount.toString(),
              compareAtPrice!.currencyCode,
            ),
            style: AppTextStyles.priceSale,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.saleRed,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-$percent%',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
