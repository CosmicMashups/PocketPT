import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'result.dart';

/// Centralized error handling service
/// This replaces the inconsistent error handling throughout the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();
  
  /// Handle and log errors with proper context
  void handleError(
    String context,
    Object error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  ]) {
    final errorMessage = _formatErrorMessage(context, error, additionalData);
    
    // Log to console in debug mode
    if (kDebugMode) {
      developer.log(
        errorMessage,
        error: error,
        stackTrace: stackTrace,
        name: 'ErrorHandler',
      );
    }
    
    // Log to crash reporting service in production
    if (kReleaseMode) {
      _logToCrashReporting(errorMessage, error, stackTrace, additionalData);
    }
  }
  
  /// Handle async errors with proper context
  Future<void> handleAsyncError(
    String context,
    Future<void> Function() operation, [
    Map<String, dynamic>? additionalData,
  ]) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      handleError(context, error, stackTrace, additionalData);
    }
  }
  
  /// Create a user-friendly error message
  String createUserFriendlyMessage(Object error) {
    if (error is String) {
      return error;
    }
    
    // Handle common error types
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('permission')) {
      return 'Permission denied. Please check your app permissions.';
    }
    
    if (errorString.contains('storage') || errorString.contains('disk')) {
      return 'Storage error. Please check available storage space.';
    }
    
    if (errorString.contains('authentication') || errorString.contains('unauthorized')) {
      return 'Authentication error. Please log in again.';
    }
    
    // Generic error message
    return 'An unexpected error occurred. Please try again.';
  }
  
  /// Format error message with context
  String _formatErrorMessage(
    String context,
    Object error,
    Map<String, dynamic>? additionalData,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Error in $context:');
    buffer.writeln('Error: $error');
    
    if (additionalData != null && additionalData.isNotEmpty) {
      buffer.writeln('Additional Data:');
      additionalData.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    return buffer.toString();
  }
  
  /// Log to crash reporting service (implement based on your crash reporting solution)
  void _logToCrashReporting(
    String message,
    Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  ) {
    // TODO: Implement crash reporting integration
    // Examples: Firebase Crashlytics, Sentry, Bugsnag, etc.
    developer.log(
      'CRASH_REPORT: $message',
      error: error,
      stackTrace: stackTrace,
      name: 'CrashReporting',
    );
  }
}

/// Global error handler instance
final errorHandler = ErrorHandler();

/// Extension for easy error handling on Result types
extension ResultErrorHandling<T> on Result<T> {
  /// Handle error with centralized error handler
  Result<T> handleError(String context) {
    if (isError) {
      errorHandler.handleError(
        context,
        error ?? errorMessage ?? 'Unknown error',
        stackTrace,
      );
    }
    return this;
  }
  
  /// Get user-friendly error message
  String get userFriendlyErrorMessage {
    if (isSuccess) return '';
    return errorHandler.createUserFriendlyMessage(error ?? errorMessage ?? 'Unknown error');
  }
}

/// Extension for easy error handling on Future<Result<T>>
extension FutureResultErrorHandling<T> on Future<Result<T>> {
  /// Handle error with centralized error handler
  Future<Result<T>> handleError(String context) async {
    final result = await this;
    return result.handleError(context);
  }
}

