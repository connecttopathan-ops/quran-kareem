import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/cart_provider.dart';
import 'widgets/cart_item_tile.dart';
import 'widgets/cart_summary.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cart (${cartState.totalQuantity})',
          style: AppTextStyles.headlineMedium,
        ),
      ),
      body: cartState.isEmpty
          ? _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Cart items
                      ...cartState.items.map(
                        (item) => CartItemTile(item: item),
                      ),

                      const SizedBox(height: 16),

                      // Coupon code
                      _CouponField(
                        controller: _couponController,
                        isApplicable: cartState.isCouponApplicable,
                        appliedCode: cartState.appliedCoupon,
                        onApply: () {
                          final code = _couponController.text.trim();
                          if (code.isNotEmpty) {
                            ref
                                .read(cartProvider.notifier)
                                .applyCoupon(code);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Order summary
                      CartSummary(cartState: cartState),

                      const SizedBox(height: 100), // space for sticky button
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cartState.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: AppButton(
                  label: 'Proceed to Checkout',
                  isLoading: cartState.isLoading,
                  onPressed: () => context.push('/checkout'),
                ),
              ),
            ),
    );
  }
}

class _CouponField extends StatelessWidget {
  final TextEditingController controller;
  final bool isApplicable;
  final String? appliedCode;
  final VoidCallback onApply;

  const _CouponField({
    required this.controller,
    required this.isApplicable,
    required this.appliedCode,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Coupon Code', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  suffixIcon: appliedCode != null && isApplicable
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onApply,
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
        if (appliedCode != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              isApplicable
                  ? '✓ "$appliedCode" applied'
                  : '✗ Code "$appliedCode" is not applicable',
              style: AppTextStyles.bodySmall.copyWith(
                color: isApplicable ? Colors.green : AppColors.saleRed,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 72,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Add some beautiful pieces to get started.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Shop Now',
            width: 180,
            onPressed: () => context.go('/shop'),
          ),
        ],
      ),
    );
  }
}
