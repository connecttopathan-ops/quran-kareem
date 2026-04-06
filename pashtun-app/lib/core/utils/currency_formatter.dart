import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const _config = {
    'IN': {'locale': 'en_IN', 'symbol': '₹',    'currency': 'INR'},
    'AE': {'locale': 'ar_AE', 'symbol': 'د.إ',  'currency': 'AED'},
    'GB': {'locale': 'en_GB', 'symbol': '£',     'currency': 'GBP'},
    'US': {'locale': 'en_US', 'symbol': '\$',    'currency': 'USD'},
  };

  static String format(double amount, String countryCode) {
    final cfg = _config[countryCode] ?? _config['IN']!;
    final formatter = NumberFormat.currency(
      locale: cfg['locale'],
      symbol: cfg['symbol'],
      decimalDigits: countryCode == 'IN' ? 0 : 2,
    );
    return formatter.format(amount);
  }

  /// Format a Shopify money string (e.g. "1299.00") with currency code.
  static String formatShopify(String amount, String currencyCode) {
    final value = double.tryParse(amount) ?? 0.0;
    final countryCode = _countryFromCurrency(currencyCode);
    return format(value, countryCode);
  }

  static String _countryFromCurrency(String currencyCode) {
    switch (currencyCode) {
      case 'INR': return 'IN';
      case 'AED': return 'AE';
      case 'GBP': return 'GB';
      case 'USD': return 'US';
      default:    return 'IN';
    }
  }

  /// Returns percentage discount between original and sale price.
  static int discountPercent(double original, double sale) {
    if (original <= 0) return 0;
    return ((original - sale) / original * 100).round();
  }
}
