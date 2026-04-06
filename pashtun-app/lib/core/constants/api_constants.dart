import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get shopifyStoreUrl =>
      dotenv.env['SHOPIFY_STORE_URL'] ?? 'pashtuncollections.myshopify.com';

  static String get shopifyStorefrontToken =>
      dotenv.env['SHOPIFY_STOREFRONT_TOKEN'] ?? '';

  static String get shopifyGraphqlEndpoint =>
      'https://$shopifyStoreUrl/api/2024-01/graphql.json';

  static String get razorpayKey =>
      dotenv.env['RAZORPAY_KEY'] ?? '';

  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  static String get mixpanelToken =>
      dotenv.env['MIXPANEL_TOKEN'] ?? '';

  static const shopifyApiVersion = '2024-01';
  static const productsPerPage = 12;
  static const collectionsLimit = 20;

  // WhatsApp enquiry number (update with real number)
  static const whatsappNumber = '919999999999';
}
