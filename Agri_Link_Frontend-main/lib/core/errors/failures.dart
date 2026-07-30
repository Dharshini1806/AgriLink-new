import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure    extends Failure { const NetworkFailure([String msg = 'No internet connection']) : super(msg); }
class ServerFailure     extends Failure { const ServerFailure([String msg = 'Server error'])   : super(msg); }
class AuthFailure       extends Failure { const AuthFailure([String msg = 'Authentication failed']) : super(msg); }
class ValidationFailure extends Failure { const ValidationFailure(String msg) : super(msg); }
class NotFoundFailure   extends Failure { const NotFoundFailure([String msg = 'Not found']) : super(msg); }
class ForbiddenFailure  extends Failure { const ForbiddenFailure([String msg = 'Access denied']) : super(msg); }
class CacheFailure      extends Failure { const CacheFailure([String msg = 'Cache error']) : super(msg); }
class UnknownFailure    extends Failure { const UnknownFailure([String msg = 'Unknown error occurred']) : super(msg); }
