import 'dart:convert';
import '../../../../core/utils/storage_helper.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheTokens(String accessToken, String refreshToken);
  Future<void> cacheUser(UserModel user);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<UserModel?> getCachedUser();
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _keyAccess  = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyUser    = 'cached_user';

  @override
  Future<void> cacheTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      StorageHelper.write(key: _keyAccess,  value: accessToken),
      StorageHelper.write(key: _keyRefresh, value: refreshToken),
    ]);
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await StorageHelper.write(key: _keyUser, value: jsonEncode(user.toJson()));
  }

  @override
  Future<String?> getAccessToken()  => StorageHelper.read(key: _keyAccess);
  @override
  Future<String?> getRefreshToken() => StorageHelper.read(key: _keyRefresh);

  @override
  Future<UserModel?> getCachedUser() async {
    final json = await StorageHelper.read(key: _keyUser);
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<void> clearAll() => StorageHelper.deleteAll();
}
