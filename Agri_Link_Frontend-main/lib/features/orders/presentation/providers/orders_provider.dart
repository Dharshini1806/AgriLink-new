import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/seller/presentation/screens/seller_dashboard_screen.dart';

// ── Cart ──────────────────────────────────────────────────
class CartItem {
  final dynamic product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});

  double get subtotal => AppFormatters.parseDouble(product['price']) * quantity;
  String get productId => product['id'] as String;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void add(dynamic product, {int qty = 1}) {
    final idx = state.indexWhere((i) => i.productId == product['id']);
    if (idx >= 0) {
      final updated = List<CartItem>.from(state);
      updated[idx].quantity += qty;
      state = updated;
    } else {
      state = [...state, CartItem(product: product, quantity: qty)];
    }
  }

  void remove(String productId) {
    state = state.where((i) => i.productId != productId).toList();
  }

  void updateQty(String productId, int qty) {
    if (qty <= 0) { remove(productId); return; }
    state = state.map((i) => i.productId == productId
      ? (CartItem(product: i.product, quantity: qty))
      : i).toList();
  }

  void clear() => state = [];

  void addAll(List<Map<String, dynamic>> items) {
    for (final item in items) {
      add(item['product'] as Map<String, dynamic>, qty: (item['quantity'] as int?) ?? 1);
    }
  }

  double get subtotal => state.fold(0, (s, i) => s + i.subtotal);
  double get buyerFee  => 0.0;
  double get deliveryFee {
    double fee = 0.0;
    for (final entry in groupedBySeller.entries) {
      final items = entry.value;
      if (items.isNotEmpty) {
        final dist = AppFormatters.parseDouble(items.first.product['distance_km']);
        fee += dist * 2;
      }
    }
    return double.parse(fee.toStringAsFixed(2));
  }
  double get total     => subtotal + deliveryFee;
  int get itemCount    => state.fold(0, (s, i) => s + i.quantity);
  bool get isEmpty     => state.isEmpty;

  // Group by seller for display
  Map<String, List<CartItem>> get groupedBySeller {
    final map = <String, List<CartItem>>{};
    for (final item in state) {
      final key = '${item.product['seller_id']}_${item.product['seller_name']}';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (_) => CartNotifier(),
);

// ── Orders ────────────────────────────────────────────────
class OrdersNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final _dio;
  final Ref? _ref;
  final bool isSeller;

  OrdersNotifier(this._dio, {this.isSeller = false, Ref? ref})
      : _ref = ref,
        super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final endpoint = isSeller ? ApiEndpoints.sellerOrders : ApiEndpoints.buyerOrders;
      final res = await _dio.get(endpoint);
      final list = List<Map<String, dynamic>>.from(
        (res.data['data'] as List?) ?? [],
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> placeOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    String? notes,
  }) async {
    try {
      await _dio.post(ApiEndpoints.placeOrder, data: {
        'items': items,
        'deliveryAddress': deliveryAddress,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      await load();
      if (_ref != null) _ref!.invalidate(sellerAnalyticsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      await _dio.patch(ApiEndpoints.cancelOrder(orderId));
      await load();
      if (_ref != null) _ref!.invalidate(sellerAnalyticsProvider);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateStatus(String orderId, String status) async {
    try {
      await _dio.patch(ApiEndpoints.updateOrderStatus(orderId), data: {'status': status});
      await load();
      if (_ref != null) _ref!.invalidate(sellerAnalyticsProvider);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> submitReview({
    required String orderId,
    String? productId,
    String? revieweeId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _dio.post(ApiEndpoints.reviews, data: {
        'orderId': orderId,
        if (productId != null) 'productId': productId,
        if (revieweeId != null) 'revieweeId': revieweeId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final buyerOrdersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => OrdersNotifier(ref.watch(dioProvider), isSeller: false, ref: ref),
);

final sellerOrdersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => OrdersNotifier(ref.watch(dioProvider), isSeller: true, ref: ref),
);

final orderDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  final res = await ref.watch(dioProvider).get(ApiEndpoints.orderById(orderId));
  return res.data as Map<String, dynamic>;
});
