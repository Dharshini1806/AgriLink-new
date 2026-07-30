import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: NetworkException('Unable to connect to server. Please check your internet connection.'),
        ),
      );
      return;
    }

    String message = 'An unexpected error occurred. Please try again.';
    final data = err.response?.data;
    if (data is Map) {
      message = data['error']?.toString() ?? data['message']?.toString() ?? message;
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    final status = err.response?.statusCode;
    AppException exception;

    switch (status) {
      case 400:
        exception = ValidationException(message);
        break;
      case 401:
        exception = AuthException(
          (message == 'An unexpected error occurred. Please try again.' || message == 'Unauthorized')
              ? 'Invalid email or password. Please check your credentials.'
              : message,
        );
        break;
      case 403:
        exception = AppException(message, 403);
        break;
      case 404:
        exception = NotFoundException(message);
        break;
      case 409:
        exception = AppException(message, 409);
        break;
      case 422:
        exception = ValidationException(message);
        break;
      case 500:
        exception = ServerException('Server error. Please try again later.');
        break;
      default:
        exception = AppException(message, status);
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
      ),
    );
  }
}
