import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/app_button.dart';
import '../../cart/providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/razorpay_service.dart';
import 'address_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  ShippingAddress? _address;
  String _paymentMethod = 'razorpay'; // 'razorpay' | 'stripe' | 'cod'
  bool _isProcessing = false;

  late final RazorpayService _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = RazorpayService()
      ..onSuccess = _onRazorpaySuccess
      ..onError   = _onRazorpayError;
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  void _onRazorpaySuccess(PaymentSuccessResponse response) {
    ref.read(cartProvider.notifier).clearCart();
    context.pushReplacement(
      '/order-confirmation?orderId=${response.orderId ?? 'PC${DateTime.now().millisecondsSinceEpoch}'}',
    );
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: AppColors.saleRed,
      ),
    );
    setState(() => _isProcessing = false);
  }

  Future<void> _placeOrder() async {
    if (_address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a shipping address.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final cart = ref.read(cartProvider);
    final auth = ref.read(authProvider);

    if (_paymentMethod == 'razorpay') {
      _razorpay.openCheckout(
        amount: cart.total,
        orderId: 'PC${DateTime.now().millisecondsSinceEpoch}',
        customerName: auth.displayName ?? 'Guest',
        customerEmail: auth.email ?? '',
        customerPhone: _address!.phone ?? '',
      );
    } else if (_paymentMethod == 'stripe') {
      // TODO: get client secret from backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Stripe integration requires backend setup.')),
      );
      setState(() => _isProcessing = false);
    } else {
      // COD
      ref.read(cartProvider.notifier).clearCart();
      context.pushReplacement(
        '/order-confirmation?orderId=PC${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: AppTextStyles.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Address
          Text('Shipping Address', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          if (_address != null)
            _AddressTile(
              address: _address!,
              onEdit: _pickAddress,
            )
          else
            OutlinedButton.icon(
              onPressed: _pickAddress,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Shipping Address'),
            ),

          const SizedBox(height: 24),

          // Payment method
          Text('Payment Method', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          _PaymentSelector(
            selected: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
            total: cart.total,
            currency: cart.currencyCode,
          ),

          const SizedBox(height: 24),

          // Order summary
          _SummaryCard(cart: cart),

          const SizedBox(height: 32),

          AppButton(
            label: 'Place Order',
            isLoading: _isProcessing,
            onPressed: _placeOrder,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _pickAddress() async {
    final result = await context.push<ShippingAddress>('/checkout/address');
    if (result != null) setState(() => _address = result);
  }
}

class _AddressTile extends StatelessWidget {
  final ShippingAddress address;
  final VoidCallback onEdit;

  const _AddressTile({required this.address, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(address.formatted,
                style: AppTextStyles.bodyMedium),
          ),
          TextButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final double total;
  final String currency;

  const _PaymentSelector({
    required this.selected,
    required this.onChanged,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isIndia = currency == 'INR';

    return Column(
      children: [
        if (isIndia) ...[
          _tile('razorpay', 'UPI / Cards / Net Banking',
              Icons.payment, selected, onChanged),
          _tile('cod', 'Cash on Delivery', Icons.money,
              selected, onChanged),
        ] else
          _tile('stripe', 'Credit / Debit Card (Stripe)',
              Icons.credit_card, selected, onChanged),
      ],
    );
  }

  Widget _tile(String value, String label, IconData icon,
      String selected, ValueChanged<String> onChanged) {
    return RadioListTile<String>(
      value: value,
      groupValue: selected,
      onChanged: (v) => onChanged(v!),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final dynamic cart;

  const _SummaryCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items (${cart.totalQuantity})',
                  style: AppTextStyles.bodyMedium),
              Text(
                CurrencyFormatter.formatShopify(
                  cart.subtotal.toString(),
                  cart.currencyCode,
                ),
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.titleLarge),
              Text(
                CurrencyFormatter.formatShopify(
                  cart.total.toString(),
                  cart.currencyCode,
                ),
                style: AppTextStyles.priceTag,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
