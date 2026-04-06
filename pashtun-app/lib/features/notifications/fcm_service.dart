import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../core/utils/notification_handler.dart';
import 'notification_screen.dart';

enum NotificationType {
  flashSale,      // "Eid sale is LIVE! 40% off bridal wear"
  restock,        // "Your wishlist item is back in stock"
  orderUpdate,    // "Your order #1234 has been shipped"
  abandonedCart,  // "You left something behind..."
  newArrival,     // "New collection just dropped"
  priceDrop,      // "Price dropped on your wishlist item"
}

@pragma('vm:entry-point')
Future<void> _handleBackground(RemoteMessage message) async {
  // Background handler runs in a separate isolate
  // Firebase is already initialized via FirebaseOptions in main.dart
  await storeNotification(NotificationItem(
    id: message.messageId ?? DateTime.now().toIso8601String(),
    title: message.notification?.title ?? '',
    body: message.notification?.body ?? '',
    type: message.data['type'] as String?,
    dataId: message.data['id'] as String?,
    receivedAt: DateTime.now(),
  ));
}

class FCMService {
  final GlobalKey<NavigatorState> navigatorKey;

  FCMService({required this.navigatorKey});

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(_handleTap);
    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    FirebaseMessaging.onBackgroundMessage(_handleBackground);
  }

  void _handleForeground(RemoteMessage message) {
    // Store in Hive for in-app notification center
    storeNotification(NotificationItem(
      id: message.messageId ?? DateTime.now().toIso8601String(),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: message.data['type'] as String?,
      dataId: message.data['id'] as String?,
      receivedAt: DateTime.now(),
    ));
    // Show a SnackBar in foreground
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message.notification?.title ?? 'New notification'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _handleTap(message),
          ),
        ),
      );
    }
  }

  void _handleTap(RemoteMessage? message) {
    if (message == null) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    NotificationHandler.handleTap(message.data, ctx);
  }

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  Future<void> subscribeToTopic(String topic) =>
      FirebaseMessaging.instance.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      FirebaseMessaging.instance.unsubscribeFromTopic(topic);
}
