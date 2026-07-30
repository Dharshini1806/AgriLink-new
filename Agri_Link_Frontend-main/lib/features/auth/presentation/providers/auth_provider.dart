import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';

// ── Auth State ────────────────────────────────────────────
class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
  String get role => user?.role ?? '';

  AuthState copyWith({UserEntity? user, bool? isLoading, String? error}) =>
    AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );

  AuthState clearError() => AuthState(user: user, isLoading: isLoading);
}

// ── Providers ─────────────────────────────────────────────
final authLocalDataSourceProvider  = Provider<AuthLocalDataSource>((ref) => AuthLocalDataSourceImpl());
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(dioProvider))
);

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(
  (ref) => AuthNotifier(ref.watch(authLocalDataSourceProvider), ref.watch(authRemoteDataSourceProvider)),
);

// ── Notifier ──────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final AuthLocalDataSource  _local;
  final AuthRemoteDataSource _remote;

  AuthNotifier(this._local, this._remote)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _local.getCachedUser();
      if (user != null) {
        state = AsyncValue.data(AuthState(user: user));
      } else {
        state = const AsyncValue.data(AuthState());
      }
    } catch (e) {
      state = const AsyncValue.data(AuthState());
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    double? latitude,
    double? longitude,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _remote.register({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null) 'phone': phone,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      await _persist(result.accessToken, result.refreshToken, result.user!);
      await _uploadFcmToken();
      state = AsyncValue.data(AuthState(user: result.user!));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: _parseError(e)));
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _remote.login(email, password);
      await _persist(result.accessToken, result.refreshToken, result.user!);
      await _uploadFcmToken();
      state = AsyncValue.data(AuthState(user: result.user!));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: _parseError(e)));
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await _local.getRefreshToken();
      if (refresh != null) await _remote.logout(refresh);
    } catch (_) {}
    await _local.clearAll();
    state = const AsyncValue.data(AuthState());
  }

  Future<void> clearAuth() async {
    await _local.clearAll();
    state = const AsyncValue.data(AuthState());
  }

  Future<void> refreshUser() async {
    try {
      final user = await _remote.getMe();
      await _local.cacheUser(user);
      state = AsyncValue.data(AuthState(user: user));
    } catch (_) {}
  }

  void clearError() {
    final current = state.value;
    if (current != null) state = AsyncValue.data(current.clearError());
  }

  // ── Helpers ─────────────────────────────────────────────
  Future<void> _persist(String access, String refresh, UserModel user) async {
    await Future.wait([
      _local.cacheTokens(access, refresh),
      _local.cacheUser(user),
    ]);
  }

  Future<void> _uploadFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _remote.updateFcmToken(token);
    } catch (_) {}
  }

  String _parseError(Object e) {
    if (e is DioException) {
      if (e.error is AppException) {
        return (e.error as AppException).message;
      }
      final data = e.response?.data;
      if (data is Map) {
        return data['error']?.toString() ?? data['message']?.toString() ?? 'An error occurred';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Unable to connect to server. Please check your internet connection.';
      }
      if (e.response?.statusCode == 401) {
        return 'Invalid email or password. Please check your credentials and try again.';
      }
      return e.message ?? 'An unexpected error occurred';
    }
    if (e is AppException) {
      return e.message;
    }
    return e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
  }
}
