import 'failures.dart';

/// Sealed-like Result type for expressive domain operations.
abstract class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(AppFailure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get dataOrNull => isSuccess ? (this as Success<T>).data : null;
  AppFailure? get failureOrNull => isFailure ? (this as FailureResult<T>).failure : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else if (this is FailureResult<T>) {
      return failure((this as FailureResult<T>).failure);
    }
    throw StateError('Unhandled Result subtype');
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class FailureResult<T> extends Result<T> {
  final AppFailure failure;
  const FailureResult(this.failure);
}
