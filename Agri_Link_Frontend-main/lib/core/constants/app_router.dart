import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/products/presentation/screens/product_feed_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/product_search_screen.dart';
import '../../features/products/presentation/screens/product_compare_screen.dart';
import '../../features/products/presentation/screens/wishlist_screen.dart';
import '../../features/products/presentation/screens/top_sellers_screen.dart';
import '../../features/products/presentation/screens/farmer_profile_screen.dart';
import '../../features/orders/presentation/screens/cart_screen.dart';
import '../../features/orders/presentation/screens/checkout_screen.dart';
import '../../features/orders/presentation/screens/orders_list_screen.dart';
import '../../features/orders/presentation/screens/order_tracking_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/smart/presentation/screens/recipe_picker_screen.dart';
import '../../features/seller/presentation/screens/seller_dashboard_screen.dart';
import '../../features/seller/presentation/screens/add_product_screen.dart';
import '../../features/seller/presentation/screens/seller_analytics_screen.dart';
import '../../features/seller/presentation/screens/seller_orders_screen.dart';
import '../../features/seller/presentation/screens/seller_products_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/role-select',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.value?.isAuthenticated ?? false;
      final role       = authState.value?.role ?? '';
      final location   = state.matchedLocation;

      final publicRoutes = ['/role-select', '/login', '/register', '/forgot-password'];
      final isPublic = publicRoutes.any((r) => location.startsWith(r));

      if (!isLoggedIn && !isPublic) return '/role-select';
      if (isLoggedIn && isPublic) {
        if (role == 'seller') return '/seller/dashboard';
        if (role == 'admin')  return '/admin/dashboard';
        return '/home';
      }
      // Role enforcement
      if (isLoggedIn && location.startsWith('/seller') && role != 'seller') return '/home';
      if (isLoggedIn && location.startsWith('/admin') && role != 'admin') return '/home';
      return null;
    },
    routes: [
      // ── Public ──────────────────────────────────────────
      GoRoute(path: '/role-select', builder: (c, s) => const RoleSelectionScreen()),
      GoRoute(path: '/login',   builder: (c, s) => LoginScreen(role: s.extra as String? ?? 'buyer')),
      GoRoute(path: '/register',builder: (c, s) => RegisterScreen(role: s.extra as String? ?? 'buyer')),
      GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),

      // ── Buyer Shell ───────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child, role: 'buyer'),
        routes: [
          GoRoute(path: '/home',         builder: (c, s) => const ProductFeedScreen()),
          GoRoute(path: '/search',        builder: (c, s) => const ProductSearchScreen()),
          GoRoute(path: '/orders',        builder: (c, s) => const OrdersListScreen()),
          GoRoute(path: '/profile',       builder: (c, s) => const ProfileScreen()),
          GoRoute(path: '/recipe',        builder: (c, s) => const RecipePickerScreen()),
          GoRoute(path: '/wishlist',      builder: (c, s) => const WishlistScreen()),
          GoRoute(path: '/top-sellers',   builder: (c, s) => const TopSellersScreen()),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        builder: (c, s) => ProductDetailScreen(productId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/farmer/:id',
        builder: (c, s) => FarmerProfileScreen(farmerId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/compare',
        builder: (c, s) => ProductCompareScreen(ids: s.extra as List<String>? ?? []),
      ),
      GoRoute(path: '/cart',     builder: (c, s) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (c, s) => const CheckoutScreen()),
      GoRoute(
        path: '/order/:id',
        builder: (c, s) => OrderTrackingScreen(orderId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (c, s) => ChatScreen(orderId: s.pathParameters['id']!),
          ),
        ],
      ),

      // ── Seller Shell ──────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child, role: 'seller'),
        routes: [
          GoRoute(path: '/seller/dashboard', builder: (c, s) => const SellerDashboardScreen()),
          GoRoute(path: '/seller/products',  builder: (c, s) => const SellerProductsScreen()),
          GoRoute(path: '/seller/orders',    builder: (c, s) => SellerOrdersScreen(initialStatus: s.uri.queryParameters['status'])),
          GoRoute(path: '/seller/analytics', builder: (c, s) => const SellerAnalyticsScreen()),
          GoRoute(path: '/seller/profile',   builder: (c, s) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/seller/add-product',  builder: (c, s) => const AddProductScreen()),
      GoRoute(
        path: '/seller/edit-product/:id',
        builder: (c, s) => AddProductScreen(editProductId: s.pathParameters['id']),
      ),

      // ── Admin ─────────────────────────────────────────────
      GoRoute(path: '/admin/dashboard', builder: (c, s) => const AdminDashboardScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  late final ProviderSubscription<AsyncValue<AuthState>> _subscription;

  GoRouterRefreshStream(Ref ref) {
    _subscription = ref.listen<AsyncValue<AuthState>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
