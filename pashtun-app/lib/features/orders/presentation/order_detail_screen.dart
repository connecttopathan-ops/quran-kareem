import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/order.dart';
import 'orders_screen.dart' show ordersProvider;

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details', style: AppTextStyles.headlineMedium),
      ),
      body: ordersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
        data: (orders) {
          final order = orders.firstWhere(
            (o) => o.id == orderId,
            orElse: () => orders.first,
          );
          return _OrderDetailBody(order: order);
        },
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  final Order order;

  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Text(
          'Order #${order.orderNumber}',
          style: AppTextStyles.headlineLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Placed on ${order.processedAt.day}/${order.processedAt.month}/${order.processedAt.year}',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 16),

        // Status
        Row(
          children: [
            const Text('Status: '),
            Text(
              order.fulfillmentStatus.label,
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.primary),
            ),
          ],
        ),

        const Divider(height: 32),

        // Items
        Text('Items', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        ...order.lineItems.map((item) => _LineItemTile(item: item)),

        const Divider(height: 32),

        // Shipping address
        if (order.shippingAddress != null) ...[
          Text('Shipping Address', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          Text(order.shippingAddress!.formatted,
              style: AppTextStyles.bodyMedium),
          const Divider(height: 32),
        ],

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Order Total', style: AppTextStyles.titleLarge),
            Text(
              CurrencyFormatter.formatShopify(
                order.totalPrice.amount.toString(),
                order.totalPrice.currencyCode,
              ),
              style: AppTextStyles.priceTag,
            ),
          ],
        ),
      ],
    );
  }
}

class _LineItemTile extends StatelessWidget {
  final OrderLineItem item;

  const _LineItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 60,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 60,
                    height: 72,
                    color: AppColors.accent,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                if (item.variantTitle != null)
                  Text(item.variantTitle!,
                      style: AppTextStyles.bodySmall),
                Text('Qty: ${item.quantity}',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (item.price != null)
            Text(
              CurrencyFormatter.formatShopify(
                item.price!.amount.toString(),
                item.price!.currencyCode,
              ),
              style: AppTextStyles.labelLarge,
            ),
        ],
      ),
    );
  }
}
