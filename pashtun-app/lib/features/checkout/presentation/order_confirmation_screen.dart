import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie checkmark
              SizedBox(
                height: 200,
                child: Lottie.asset(
                  'assets/animations/order_success.json',
                  repeat: false,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 100,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Order Placed!',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 12),

              Text(
                'Your order #$orderId has been placed successfully.\n'
                'You\'ll receive a confirmation email shortly.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

              const SizedBox(height: 8),

              // Points earned
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🎉 You earned loyalty points on this order!',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

              const SizedBox(height: 48),

              AppButton(
                label: 'Track Order',
                onPressed: () => context.push('/order/$orderId'),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Continue Shopping',
                variant: AppButtonVariant.outlined,
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
