import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../data/datasources/products_remote_datasource.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';

// ── Remote Datasource Provider ─────────────────────────────
final productsRemoteDataSourceProvider = Provider<ProductsRemoteDataSource>((ref) {
  return ProductsRemoteDataSourceImpl(ref.watch(dioProvider));
});

// ── Categories ───────────────────────────────────────────
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final ds = ref.watch(productsRemoteDataSourceProvider);
  return ds.getCategories();
});

// ── Product Feed ─────────────────────────────────────────
class FeedState {
  final List<ProductModel> products;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;

  FeedState({
    this.products = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
  });

  FeedState copyWith({
    List<ProductModel>? products,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
  }) =>
      FeedState(
        products: products ?? this.products,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
      );
}

class ProductFeedNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ProductsRemoteDataSource _ds;
  FeedState _feed = FeedState();
  Map<String, dynamic> _lastParams = {};

  ProductFeedNotifier(this._ds) : super(const AsyncValue.loading());

  Future<void> load({
    double? lat,
    double? lng,
    String? category,
    String? grade,
    String? query,
  }) async {
    _lastParams = {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (category != null) 'category': category,
      if (grade != null) 'grade': grade,
      if (query != null && query.isNotEmpty) 'q': query,
      'limit': 20,
      'page': 1,
    };
    _feed = FeedState();
    state = const AsyncValue.loading();
    try {
      final items = await _ds.getFeed(_lastParams);
      _feed = FeedState(products: items, hasMore: items.length == 20, page: 1);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_feed.isLoadingMore || !_feed.hasMore) return;
    _feed = _feed.copyWith(isLoadingMore: true);
    try {
      final params = {..._lastParams, 'page': _feed.page + 1};
      final newItems = await _ds.getFeed(params);
      _feed = _feed.copyWith(
        products: [..._feed.products, ...newItems],
        isLoadingMore: false,
        hasMore: newItems.length == 20,
        page: _feed.page + 1,
      );
      state = AsyncValue.data(_feed.products);
    } catch (_) {
      _feed = _feed.copyWith(isLoadingMore: false);
    }
  }
}

final productFeedProvider =
    StateNotifierProvider<ProductFeedNotifier, AsyncValue<List<ProductModel>>>((ref) {
  return ProductFeedNotifier(ref.watch(productsRemoteDataSourceProvider));
});

// ── Compare Selection ────────────────────────────────────
class CompareNotifier extends StateNotifier<Set<String>> {
  CompareNotifier() : super({});

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else if (state.length < 5) {
      state = {...state, id};
    }
  }

  void clear() => state = {};
}

final compareSelectionProvider =
    StateNotifierProvider<CompareNotifier, Set<String>>((_) => CompareNotifier());

// ── Single Product ────────────────────────────────────────
final productDetailProvider =
    FutureProvider.family<ProductModel, String>((ref, id) async {
  final ds = ref.watch(productsRemoteDataSourceProvider);
  return ds.getProductById(id);
});

// ── Wishlist State Manager ─────────────────────────────────
class WishlistState {
  final Set<String> ids;
  final List<ProductModel> items;
  final bool isLoading;

  WishlistState({
    this.ids = const {},
    this.items = const [],
    this.isLoading = false,
  });

  WishlistState copyWith({
    Set<String>? ids,
    List<ProductModel>? items,
    bool? isLoading,
  }) =>
      WishlistState(
        ids: ids ?? this.ids,
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
      );
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  final ProductsRemoteDataSource _ds;

  WishlistNotifier(this._ds) : super(WishlistState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _ds.getWishlist();
      final ids = list.map((p) => p.id).toSet();
      state = WishlistState(ids: ids, items: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggle(dynamic product) async {
    final String productId = product is ProductModel ? product.id : (product['id'] as String);
    final isWishlisted = state.ids.contains(productId);

    // Optimistic UI update
    final newIds = Set<String>.from(state.ids);
    if (isWishlisted) {
      newIds.remove(productId);
    } else {
      newIds.add(productId);
    }
    state = state.copyWith(ids: newIds);

    try {
      await _ds.toggleWishlist(productId);
      load(); // Refresh full wishlist list
    } catch (_) {
      // Revert if request failed
      final revertedIds = Set<String>.from(state.ids);
      if (isWishlisted) {
        revertedIds.add(productId);
      } else {
        revertedIds.remove(productId);
      }
      state = state.copyWith(ids: revertedIds);
    }
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier(ref.watch(productsRemoteDataSourceProvider));
});

// ── Product Reviews ───────────────────────────────────────
final productReviewsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, productId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.productReviews(productId));
  return List<Map<String, dynamic>>.from((res.data['data'] as List?) ?? []);
});

// ── My Products (Seller) ──────────────────────────────────
final sellerProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final ds = ref.watch(productsRemoteDataSourceProvider);
  return ds.getSellerProducts();
});
