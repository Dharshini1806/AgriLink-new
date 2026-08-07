import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  final String role;
  const MainShell({super.key, required this.child, required this.role});

  static const _buyerItems = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded, 'Recipes'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  static const _sellerItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Products'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Analytics'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  static const _buyerRoutes  = ['/home', '/recipe', '/orders', '/profile'];
  static const _sellerRoutes = [
    '/seller/dashboard', '/seller/products', '/seller/orders',
    '/seller/analytics', '/seller/profile',
  ];

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
    const ordersIndex = 2;
    final currentIndex = _currentIndex(context);
    final items = role == 'seller' ? _sellerItems : _buyerItems;

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _FloatingNavBar(
        items: items,
        currentIndex: currentIndex,
        unreadCount: unread,
        ordersIndex: ordersIndex,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _FloatingNavBar extends StatefulWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final int unreadCount;
  final int ordersIndex;
  final void Function(int) onTap;

  const _FloatingNavBar({
    required this.items,
    required this.currentIndex,
    required this.unreadCount,
    required this.ordersIndex,
    required this.onTap,
  });

  @override
  State<_FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<_FloatingNavBar> {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(widget.items.length, (i) {
                final item = widget.items[i];
                final isActive = i == widget.currentIndex;
                final hasUnread = i == widget.ordersIndex && widget.unreadCount > 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  key: ValueKey(isActive),
                                  color: isActive ? AppColors.primary : AppColors.textHint,
                                  size: 22,
                                ),
                              ),
                              if (hasUnread)
                                Positioned(
                                  top: -4, right: -4,
                                  child: Container(
                                    width: 16, height: 16,
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${widget.unreadCount}',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                              color: isActive ? AppColors.primary : AppColors.textHint,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
