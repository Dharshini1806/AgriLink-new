import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  final String role;
  const MainShell({super.key, required this.child, required this.role});

  static const _buyerItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), activeIcon: Icon(Icons.restaurant_menu_rounded), label: 'Recipes'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
  ];

  static const _sellerItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2_rounded), label: 'Products'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
  ];

  static const _buyerRoutes  = ['/home', '/recipe', '/orders', '/profile'];
  static const _sellerRoutes = ['/seller/dashboard', '/seller/products', '/seller/orders', '/seller/analytics', '/seller/profile'];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final routes = role == 'seller' ? _sellerRoutes : _buyerRoutes;
    for (int i = 0; i < routes.length; i++) {
      if (loc.startsWith(routes[i])) return i;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    final routes = role == 'seller' ? _sellerRoutes : _buyerRoutes;
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    // For seller: Orders is index 2; for buyer: Orders is index 2.
    const ordersIndex = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) => _onTap(context, i),
        items: (role == 'seller' ? _sellerItems : _buyerItems).asMap().entries.map((entry) {
          // Show unread badge on Orders tab
          if (entry.key == ordersIndex && unread > 0) {
            return BottomNavigationBarItem(
              icon: Badge(label: Text('$unread'), child: entry.value.icon),
              activeIcon: Badge(label: Text('$unread'), child: entry.value.activeIcon),
              label: entry.value.label,
            );
          }
          return entry.value;
        }).toList(),
      ),
    );
  }
}
