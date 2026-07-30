import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokensData> register(Map<String, dynamic> body);
  Future<AuthTokensData> login(String email, String password);
  Future<AuthTokensData> refreshToken(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<UserModel> getMe();
  Future<void> updateFcmToken(String token);
  Future<String> forgotPassword(String email);
  Future<bool> verifyOtp(String email, String otp);
  Future<String> resetPassword(String email, String otp, String newPassword);
}

class AuthTokensData {
  final String accessToken;
  final String refreshToken;
  final UserModel? user;
  AuthTokensData({required this.accessToken, required this.refreshToken, this.user});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<AuthTokensData> register(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiEndpoints.register, data: body);
    return _parseTokensResponse(res.data as Map<String, dynamic>);
  }

  @override
  Future<AuthTokensData> login(String email, String password) async {
    final res = await _dio.post(ApiEndpoints.login, data: {'email': email, 'password': password});
    return _parseTokensResponse(res.data as Map<String, dynamic>);
  }

  @override
  Future<AuthTokensData> refreshToken(String token) async {
    final res = await _dio.post(ApiEndpoints.refresh, data: {'refreshToken': token});
    return _parseTokensResponse(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _dio.post(ApiEndpoints.logout, data: {'refreshToken': refreshToken});
  }

  @override
  Future<UserModel> getMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateFcmToken(String token) async {
    await _dio.patch(ApiEndpoints.fcmToken, data: {'fcmToken': token});
  }

  @override
  Future<String> forgotPassword(String email) async {
    final res = await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
    return (res.data['message'] as String?) ?? 'OTP sent successfully';
  }

  @override
  Future<bool> verifyOtp(String email, String otp) async {
    final res = await _dio.post(ApiEndpoints.verifyOtp, data: {'email': email, 'otp': otp});
    return (res.data['valid'] as bool?) ?? false;
  }

  @override
  Future<String> resetPassword(String email, String otp, String newPassword) async {
    final res = await _dio.post(ApiEndpoints.resetPassword, data: {
      'email': email,
      'otp': otp,
      'password': newPassword,
    });
    return (res.data['message'] as String?) ?? 'Password reset successfully';
  }

  AuthTokensData _parseTokensResponse(Map<String, dynamic> data) {
    return AuthTokensData(
      accessToken:  data['accessToken']  as String,
      refreshToken: data['refreshToken'] as String,
      user: data['user'] != null ? UserModel.fromJson(data['user'] as Map<String, dynamic>) : null,
    );
  }
}
