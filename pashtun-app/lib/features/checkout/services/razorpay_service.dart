import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/api_constants.dart';

typedef PaymentSuccessCallback = void Function(PaymentSuccessResponse response);
typedef PaymentErrorCallback   = void Function(PaymentFailureResponse response);

class RazorpayService {
  late final Razorpay _razorpay;

  PaymentSuccessCallback? onSuccess;
  PaymentErrorCallback?   onError;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,   _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required double amount, // in INR
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) {
    final options = {
      'key': ApiConstants.razorpayKey,
      'amount': (amount * 100).round(), // paise
      'name': 'Pashtun Collections',
      'description': 'Order #$orderId',
      'prefill': {
        'name': customerName,
        'email': customerEmail,
        'contact': customerPhone,
      },
      'theme': {'color': '#C8860A'},
      'send_sms_hash': true,
      'external': {
        'wallets': ['paytm', 'phonepe', 'gpay'],
      },
    };

    _razorpay.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response);
  }

  void _handleError(PaymentFailureResponse response) {
    onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet: ${response.walletName}');
  }

  void dispose() {
    _razorpay.clear();
  }
}
