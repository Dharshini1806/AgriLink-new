import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, debugPrint;

class ApiEndpoints {
  ApiEndpoints._();

  static const String localUrl = 'http://localhost:10000';
  static const String renderUrl = 'https://agri-link-omib.onrender.com';

  static String _resolvedBaseUrl = renderUrl;

  /// Dynamically resolved base URL
  static String get baseUrl => _resolvedBaseUrl;

  /// Initializes base URL according to client environment:
  /// 1. Mobile App (APK / Android / iOS): Connects directly to online Render server.
  /// 2. Online Web (Release Mode): Connects directly to online Render server.
  /// 3. Local Web (Development Mode): Pings local server first (http://localhost:10000/health).
  ///    If local server is running -> Uses http://localhost:10000.
  ///    If local server is offline -> Falls back to online Render server.
  static Future<void> init() async {
    const envBaseUrl = String.fromEnvironment('BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      _resolvedBaseUrl = envBaseUrl;
      debugPrint('[ApiEndpoints] Explicit BASE_URL override: $_resolvedBaseUrl');
      return;
    }

    // 1. Mobile App (APK / Android / iOS) -> Connect directly to Render
    if (!kIsWeb) {
      _resolvedBaseUrl = renderUrl;
      debugPrint('[ApiEndpoints] Mobile App (APK): Connected directly to Render -> $_resolvedBaseUrl');
      return;
    }

    // 2. Online Web (Production build) -> Connect directly to Render
    if (kReleaseMode) {
      _resolvedBaseUrl = renderUrl;
      debugPrint('[ApiEndpoints] Online Web (Release): Connected directly to Render -> $_resolvedBaseUrl');
      return;
    }

    // 3. Local Web (Development mode) -> Check if local server is running, fallback to Render
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(milliseconds: 1500),
          receiveTimeout: const Duration(milliseconds: 1500),
        ),
      );
      final response = await dio.get('$localUrl/health');
      if (response.statusCode == 200) {
        _resolvedBaseUrl = localUrl;
        debugPrint('[ApiEndpoints] Local Web: Local backend is RUNNING -> Using $_resolvedBaseUrl');
      } else {
        _resolvedBaseUrl = renderUrl;
        debugPrint('[ApiEndpoints] Local Web: Local backend status ${response.statusCode} -> Falling back to Render -> $_resolvedBaseUrl');
      }
    } catch (e) {
      _resolvedBaseUrl = renderUrl;
      debugPrint('[ApiEndpoints] Local Web: Local backend offline -> Falling back to Render -> $_resolvedBaseUrl');
    }
  }

  // ── Auth ──────────────────────────────────────────────────
  static const String register       = '/api/auth/register';
  static const String login          = '/api/auth/login';
  static const String refresh        = '/api/auth/refresh';
  static const String logout         = '/api/auth/logout';
  static const String me             = '/api/auth/me';
  static const String fcmToken       = '/api/auth/fcm-token';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyOtp       = '/api/auth/verify-otp';
  static const String resetPassword   = '/api/auth/reset-password';

  // ── Products ──────────────────────────────────────────────
  static const String products     = '/api/products';
  static const String categories   = '/api/products/categories';
  static const String wishlist     = '/api/products/wishlist';
  static const String myProducts   = '/api/products/mine';
  static String productById(String id) => '/api/products/$id';
  static String toggleWishlist(String id) => '/api/products/$id/wishlist';
  static String productReviews(String id) => '/api/reviews/product/$id';

  // ── Orders ────────────────────────────────────────────────
  static const String placeOrder    = '/api/orders';
  static const String buyerOrders   = '/api/orders/buyer/mine';
  static const String sellerOrders  = '/api/orders/seller/mine';
  static String orderById(String id) => '/api/orders/$id';
  static String updateOrderStatus(String id) => '/api/orders/$id/status';
  static String cancelOrder(String id) => '/api/orders/$id/cancel';

  // ── Smart ─────────────────────────────────────────────────
  static const String compare       = '/api/smart/compare';
  static const String recipes       = '/api/smart/recipes';
  static const String recipeToCart  = '/api/smart/recipe-to-cart';
  static const String priceSuggest  = '/api/smart/price-suggestion';

  // ── Reviews ───────────────────────────────────────────────
  static const String reviews       = '/api/reviews';

  // ── Chat ──────────────────────────────────────────────────
  static String chatHistory(String orderId) => '/api/chat/$orderId/history';
  static const String unreadCount   = '/api/chat/unread/count';

  // ── Users ─────────────────────────────────────────────────
  static const String userProfile   = '/api/users/profile';
  static const String sellerAnalytics = '/api/users/analytics/seller';
  static String publicProfile(String id) => '/api/users/$id/profile';

  // ── Admin ─────────────────────────────────────────────────
  static const String adminDashboard  = '/api/admin/dashboard';
  static const String adminUsers      = '/api/admin/users';
  static const String adminPending    = '/api/admin/products/pending';
  static const String adminRevenue    = '/api/admin/analytics/revenue';
  static const String adminFraud      = '/api/admin/fraud-signals';
  static String banUser(String id) => '/api/admin/users/$id/ban';
  static String unbanUser(String id) => '/api/admin/users/$id/unban';
  static String moderateProduct(String id) => '/api/admin/products/$id/moderate';
}
