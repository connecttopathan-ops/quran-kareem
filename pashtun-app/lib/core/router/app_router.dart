import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/shop/presentation/shop_screen.dart';
import '../../features/shop/presentation/collection_screen.dart';
import '../../features/product/presentation/product_detail_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/checkout/presentation/address_screen.dart';
import '../../features/checkout/presentation/order_confirmation_screen.dart';
import '../../features/wishlist/presentation/wishlist_screen.dart';
import '../../features/lookbook/presentation/lookbook_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/notifications/notification_screen.dart';
import '../shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) => _router);

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/shop',
          builder: (_, __) => const ShopScreen(),
        ),
        GoRoute(
          path: '/wishlist',
          builder: (_, __) => const WishlistScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (_, __) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfilePlaceholderScreen(),
        ),
      ],
    ),

    // Full-screen routes (no bottom nav)
    GoRoute(
      path: '/product/:handle',
      builder: (_, s) =>
          ProductDetailScreen(handle: s.pathParameters['handle']!),
    ),
    GoRoute(
      path: '/collection/:handle',
      builder: (_, s) =>
          CollectionScreen(handle: s.pathParameters['handle']!),
    ),
    GoRoute(
      path: '/cart',
      builder: (_, __) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (_, __) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/checkout/address',
      builder: (_, __) => const AddressScreen(),
    ),
    GoRoute(
      path: '/order-confirmation',
      builder: (_, s) => OrderConfirmationScreen(
        orderId: s.uri.queryParameters['orderId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/order/:id',
      builder: (_, s) =>
          OrderDetailScreen(orderId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/lookbook',
      builder: (_, __) => const LookbookScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationScreen(),
    ),
  ],
);

// Temporary profile placeholder until profile feature is built
class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile coming soon')),
    );
  }
}
