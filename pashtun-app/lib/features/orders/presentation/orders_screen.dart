import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/graphql/client.dart';
import '../../../core/graphql/queries.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/order.dart';
import '../../auth/providers/auth_provider.dart';

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated || auth.accessToken == null) return [];

  final data = await ShopifyGraphQLClient.query(
    document: getCustomerOrdersQuery,
    variables: {
      'customerAccessToken': auth.accessToken!,
      'first': 20,
    },
  );

  final customer = data['customer'] as Map<String, dynamic>?;
  if (customer == null) return [];
  final edges = (customer['orders'] as Map)['edges'] as List? ?? [];
  return edges
      .map((e) => Order.fromJson((e as Map)['node'] as Map<String, dynamic>))
      .toList();
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth       = ref.watch(authProvider);
    final ordersAsync = ref.watch(ordersProvider);

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Orders', style: AppTextStyles.headlineMedium),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('Sign in to view orders',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: AppTextStyles.headlineMedium),
      ),
      body: ordersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Failed to load orders: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _OrderTile(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/order/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: AppTextStyles.labelLarge,
                ),
                _StatusChip(status: order.fulfillmentStatus),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${order.processedAt.day}/${order.processedAt.month}/${order.processedAt.year}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.lineItems.length} item(s)',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  CurrencyFormatter.formatShopify(
                    order.totalPrice.amount.toString(),
                    order.totalPrice.currencyCode,
                  ),
                  style: AppTextStyles.priceTag.copyWith(fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderFulfillmentStatus status;

  const _StatusChip({required this.status});

  Color get _color => switch (status) {
    OrderFulfillmentStatus.delivered     => Colors.green,
    OrderFulfillmentStatus.inTransit     => AppColors.primary,
    OrderFulfillmentStatus.outForDelivery => AppColors.primary,
    OrderFulfillmentStatus.fulfilled     => Colors.blue,
    _                                    => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(color: _color),
      ),
    );
  }
}
