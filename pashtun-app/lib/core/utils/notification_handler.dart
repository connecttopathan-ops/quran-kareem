import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationHandler {
  NotificationHandler._();

  /// Deep-link router based on FCM message data payload.
  static void handleTap(Map<String, dynamic> data, BuildContext context) {
    final type = data['type'] as String?;
    final id   = data['id']   as String?;

    switch (type) {
      case 'restock':
      case 'product':
        if (id != null) context.push('/product/$id');
      case 'order_update':
        if (id != null) context.push('/order/$id');
      case 'flash_sale':
      case 'new_arrival':
        context.push('/shop');
      case 'price_drop':
        if (id != null) context.push('/product/$id');
      case 'abandoned_cart':
        context.push('/cart');
      default:
        context.push('/notifications');
    }
  }
}
