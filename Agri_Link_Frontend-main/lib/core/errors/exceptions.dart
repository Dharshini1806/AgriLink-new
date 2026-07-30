class AppException implements Exception {
  final String message;
  final int? statusCode;
  AppException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ServerException    extends AppException { ServerException([String msg = 'Server error', int? code]) : super(msg, code); }
class NetworkException   extends AppException { NetworkException([String msg = 'No internet']) : super(msg); }
class AuthException      extends AppException { AuthException([String msg = 'Unauthorized', int? code]) : super(msg, code ?? 401); }
class CacheException     extends AppException { CacheException([String msg = 'Cache error']) : super(msg); }
class ValidationException extends AppException { ValidationException(String msg) : super(msg, 422); }
class NotFoundException  extends AppException { NotFoundException([String msg = 'Not found']) : super(msg, 404); }
