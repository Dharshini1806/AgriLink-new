import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

abstract class ProductsRemoteDataSource {
  Future<List<ProductModel>> getFeed(Map<String, dynamic> params);
  Future<ProductModel> getProductById(String id);
  Future<List<ProductModel>> getSellerProducts();
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getWishlist();
  Future<bool> toggleWishlist(String productId);
  Future<ProductModel> createProduct(Map<String, dynamic> body);
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> body);
  Future<void> deleteProduct(String id);
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final Dio _dio;

  ProductsRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ProductModel>> getFeed(Map<String, dynamic> params) async {
    final res = await _dio.get(ApiEndpoints.products, queryParameters: params);
    final rawList = (res.data['data'] as List?) ?? (res.data is List ? res.data as List : []);
    return rawList.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final res = await _dio.get(ApiEndpoints.productById(id));
    return ProductModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<ProductModel>> getSellerProducts() async {
    final res = await _dio.get(ApiEndpoints.myProducts);
    final rawList = (res.data['data'] as List?) ?? [];
    return rawList.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final res = await _dio.get(ApiEndpoints.categories);
    final rawList = res.data as List;
    return rawList.map((item) => CategoryModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ProductModel>> getWishlist() async {
    final res = await _dio.get(ApiEndpoints.wishlist);
    final rawList = (res.data['data'] as List?) ?? [];
    return rawList.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<bool> toggleWishlist(String productId) async {
    final res = await _dio.post(ApiEndpoints.toggleWishlist(productId));
    return (res.data['wishlisted'] as bool?) ?? false;
  }

  @override
  Future<ProductModel> createProduct(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiEndpoints.products, data: body);
    return ProductModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> body) async {
    final res = await _dio.put(ApiEndpoints.productById(id), data: body);
    return ProductModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _dio.delete(ApiEndpoints.productById(id));
  }
}
