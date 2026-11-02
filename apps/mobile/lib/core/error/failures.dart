/// Domain Failure Hierarchy — Type-safe, actionable domain errors.
abstract class AppFailure {
  final String message;
  final String? debugInfo;

  const AppFailure(this.message, [this.debugInfo]);

  @override
  String toString() => '$runtimeType: $message${debugInfo != null ? ' ($debugInfo)' : ''}';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([String message = 'Unable to connect. Please check your internet connection.', String? debugInfo])
      : super(message, debugInfo);
}

class ServerFailure extends AppFailure {
  final int? statusCode;
  const ServerFailure([String message = 'Server encountered an issue. Please try again later.', this.statusCode, String? debugInfo])
      : super(message, debugInfo);

  @override
  String toString() => '$runtimeType${statusCode != null ? ' ($statusCode)' : ''}: $message${debugInfo != null ? ' ($debugInfo)' : ''}';
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([String message = 'The requested item could not be found.', String? debugInfo])
      : super(message, debugInfo);
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([String message = 'Session expired. Please log in again.', String? debugInfo])
      : super(message, debugInfo);
}

class CacheFailure extends AppFailure {
  const CacheFailure([String message = 'Local cache error occurred.', String? debugInfo])
      : super(message, debugInfo);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([String message = 'An unexpected error occurred.', String? debugInfo])
      : super(message, debugInfo);
}
