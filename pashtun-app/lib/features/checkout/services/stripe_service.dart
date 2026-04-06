import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/constants/api_constants.dart';

class StripeService {
  StripeService._();

  static void init() {
    Stripe.publishableKey = ApiConstants.stripePublishableKey;
    Stripe.merchantIdentifier = 'merchant.com.pashtuncollections.app';
  }

  /// Presents the Stripe payment sheet.
  /// [clientSecret] must be obtained from your backend (Shopify webhook / server).
  static Future<void> presentPaymentSheet({
    required String clientSecret,
    required String customerEmail,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Pashtun Collections',
        billingDetails: BillingDetails(email: customerEmail),
        style: ThemeMode.light,
        appearance: PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: 0xFFC8860A,
          ),
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }
}
