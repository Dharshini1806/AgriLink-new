import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../utils/storage_helper.dart';
import '../../constants/api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Ref _ref;
  bool _isRefreshing = false;

  static const _noAuthPaths = [
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.refresh,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.verifyOtp,
    ApiEndpoints.resetPassword,
  ];

  AuthInterceptor(this._dio, this._ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for auth endpoints
    if (_noAuthPaths.any((p) => options.path.contains(p))) {
      return handler.next(options);
    }

    final token = await StorageHelper.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Skip auth check for public/auth endpoints
    if (_noAuthPaths.any((p) => err.requestOptions.path.contains(p))) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await StorageHelper.read(key: 'refresh_token');
        if (refreshToken == null) {
          _isRefreshing = false;
          _ref.read(authStateProvider.notifier).clearAuth();
          return handler.next(err);
        }

        // Get new tokens
        final response = await Dio().post(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.refresh}',
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken  = response.data['accessToken']  as String;
        final newRefreshToken = response.data['refreshToken'] as String;

        await StorageHelper.write(key: 'access_token',  value: newAccessToken);
        await StorageHelper.write(key: 'refresh_token', value: newRefreshToken);

        // Retry original request
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (e) {
        _isRefreshing = false;
        // Clear tokens and auth state — user must re-login
        _ref.read(authStateProvider.notifier).clearAuth();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}
