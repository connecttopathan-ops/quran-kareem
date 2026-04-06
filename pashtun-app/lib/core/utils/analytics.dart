import 'package:firebase_analytics/firebase_analytics.dart';

class Analytics {
  Analytics._();

  static final _fa = FirebaseAnalytics.instance;

  static Future<void> track(
    String event,
    Map<String, dynamic> properties,
  ) async {
    // Firebase Analytics
    await _fa.logEvent(
      name: event,
      parameters: properties.map((k, v) => MapEntry(k, v.toString())),
    );
    // Mixpanel would be called here via the mixpanel_flutter package
    // Mixpanel.getInstance().track(event, properties);
  }

  // ── Named event helpers ────────────────────────────────────────────────────

  static Future<void> productViewed({
    required String productId,
    required String title,
    required double price,
    String? collection,
  }) =>
      track('product_viewed', {
        'productId': productId,
        'title': title,
        'price': price,
        if (collection != null) 'collection': collection,
      });

  static Future<void> addToCart({
    required String productId,
    required String variantId,
    required double price,
    required int quantity,
  }) =>
      track('add_to_cart', {
        'productId': productId,
        'variantId': variantId,
        'price': price,
        'quantity': quantity,
      });

  static Future<void> checkoutStarted({
    required double cartValue,
    required int itemCount,
  }) =>
      track('checkout_started', {
        'cartValue': cartValue,
        'itemCount': itemCount,
      });

  static Future<void> orderCompleted({
    required String orderId,
    required double revenue,
    required String paymentMethod,
  }) =>
      track('order_completed', {
        'orderId': orderId,
        'revenue': revenue,
        'paymentMethod': paymentMethod,
      });

  static Future<void> notificationTapped({
    required String type,
    String? productId,
  }) =>
      track('notification_tapped', {
        'type': type,
        if (productId != null) 'productId': productId,
      });

  static Future<void> lookbookViewed(String lookName) =>
      track('lookbook_viewed', {'lookName': lookName});

  static Future<void> shareTapped({
    required String productId,
    required String platform,
  }) =>
      track('share_tapped', {'productId': productId, 'platform': platform});
}
