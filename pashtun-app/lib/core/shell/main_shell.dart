import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../../shared/widgets/app_badge.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(label: 'Home',     icon: Icons.home_outlined,        activeIcon: Icons.home,               route: '/'),
    _TabItem(label: 'Shop',     icon: Icons.grid_view_outlined,   activeIcon: Icons.grid_view,          route: '/shop'),
    _TabItem(label: 'Wishlist', icon: Icons.favorite_border,      activeIcon: Icons.favorite,           route: '/wishlist'),
    _TabItem(label: 'Orders',   icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,      route: '/orders'),
    _TabItem(label: 'Profile',  icon: Icons.person_outline,       activeIcon: Icons.person,             route: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount   = ref.watch(cartProvider).totalQuantity;
    final currentIdx  = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIdx,
        onTap: (i) => context.go(_tabs[i].route),
        items: _tabs.asMap().entries.map((entry) {
          final i    = entry.key;
          final tab  = entry.value;
          final icon = i == currentIdx ? tab.activeIcon : tab.icon;

          // Cart badge on Shop tab (index 1)
          Widget iconWidget = Icon(icon);
          if (i == 1 && cartCount > 0) {
            iconWidget = Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon),
                CartCountBadge(count: cartCount),
              ],
            );
          }

          return BottomNavigationBarItem(
            icon: iconWidget,
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
