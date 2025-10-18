/// A Result type for handling success and error states in a type-safe manner
/// This replaces the inconsistent error handling throughout the application
sealed class Result<T> {
  const Result();
  
  /// Create a successful result with data
  const factory Result.success(T data) = Success<T>;
  
  /// Create an error result with error information
  const factory Result.error(String message, [Object? error, StackTrace? stackTrace]) = Error<T>;
  
  /// Check if the result is successful
  bool get isSuccess => this is Success<T>;
  
  /// Check if the result is an error
  bool get isError => this is Error<T>;
  
  /// Get the data if successful, null otherwise
  T? get data => isSuccess ? (this as Success<T>).data : null;
  
  /// Get the error message if error, null otherwise
  String? get errorMessage => isError ? (this as Error<T>).message : null;
  
  /// Get the error object if error, null otherwise
  Object? get error => isError ? (this as Error<T>).error : null;
  
  /// Get the stack trace if error, null otherwise
  StackTrace? get stackTrace => isError ? (this as Error<T>).stackTrace : null;
  
  /// Transform the data if successful
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => Result.success(transform(data)),
      Error<T>() => Result.error(
          (this as Error<T>).message,
          (this as Error<T>).error,
          (this as Error<T>).stackTrace,
        ),
    };
  }
  
  /// Transform the data if successful, or return a new error
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => transform(data),
      Error<T>() => Result.error(
          (this as Error<T>).message,
          (this as Error<T>).error,
          (this as Error<T>).stackTrace,
        ),
    };
  }
  
  /// Execute a function if successful
  Result<T> onSuccess(void Function(T data) callback) {
    if (isSuccess) {
      callback((this as Success<T>).data);
    }
    return this;
  }
  
  /// Execute a function if error
  Result<T> onError(void Function(String message, Object? error, StackTrace? stackTrace) callback) {
    if (isError) {
      final error = this as Error<T>;
      callback(error.message, error.error, error.stackTrace);
    }
    return this;
  }
  
  /// Get the data or throw an exception if error
  T getOrThrow() {
    return switch (this) {
      Success<T>(data: final data) => data,
      Error<T>() => throw Exception((this as Error<T>).message),
    };
  }
  
  /// Get the data or return a default value if error
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T>(data: final data) => data,
      Error<T>() => defaultValue,
    };
  }
}

/// Success result containing data
final class Success<T> extends Result<T> {
  final T data;
  
  const Success(this.data);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;
  
  @override
  int get hashCode => data.hashCode;
  
  @override
  String toString() => 'Success($data)';
}

/// Error result containing error information
final class Error<T> extends Result<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  
  const Error(this.message, [this.error, this.stackTrace]);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          error == other.error;
  
  @override
  int get hashCode => message.hashCode ^ error.hashCode;
  
  @override
  String toString() => 'Error($message)';
}

/// Extension methods for Future<Result<T>>
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Transform the data if successful
  Future<Result<R>> map<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }
  
  /// Transform the data if successful, or return a new error
  Future<Result<R>> flatMap<R>(Result<R> Function(T data) transform) async {
    final result = await this;
    return result.flatMap(transform);
  }
  
  /// Execute a function if successful
  Future<Result<T>> onSuccess(void Function(T data) callback) async {
    final result = await this;
    return result.onSuccess(callback);
  }
  
  /// Execute a function if error
  Future<Result<T>> onError(void Function(String message, Object? error, StackTrace? stackTrace) callback) async {
    final result = await this;
    return result.onError(callback);
  }
}

/// Helper functions for creating results
class ResultHelper {
  /// Execute a function and wrap the result
  static Result<T> tryCatch<T>(T Function() computation) {
    try {
      return Result.success(computation());
    } catch (e, stackTrace) {
      return Result.error('Computation failed: ${e.toString()}', e, stackTrace);
    }
  }
  
  /// Execute an async function and wrap the result
  static Future<Result<T>> tryCatchAsync<T>(Future<T> Function() computation) async {
    try {
      final result = await computation();
      return Result.success(result);
    } catch (e, stackTrace) {
      return Result.error('Async computation failed: ${e.toString()}', e, stackTrace);
    }
  }
  
  /// Convert a nullable value to a result
  static Result<T> fromNullable<T>(T? value, String errorMessage) {
    return value != null ? Result.success(value) : Result.error(errorMessage);
  }
}

