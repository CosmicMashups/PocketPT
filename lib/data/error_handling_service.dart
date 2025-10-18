import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Error types for different scenarios
enum ErrorType {
  networkError,
  dataCorruption,
  syncFailure,
  migrationError,
  validationError,
  authenticationError,
  storageError,
  unknownError,
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Error information class
class ErrorInfo {
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String userMessage;
  final String? technicalDetails;
  final DateTime timestamp;
  final String? stackTrace;

  ErrorInfo({
    required this.type,
    required this.severity,
    required this.message,
    required this.userMessage,
    this.technicalDetails,
    required this.timestamp,
    this.stackTrace,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'userMessage': userMessage,
      'technicalDetails': technicalDetails,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'stackTrace': stackTrace,
    };
  }

  static ErrorInfo fromMap(Map<String, dynamic> map) {
    return ErrorInfo(
      type: ErrorType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ErrorType.unknownError,
      ),
      severity: ErrorSeverity.values.firstWhere(
        (s) => s.name == map['severity'],
        orElse: () => ErrorSeverity.medium,
      ),
      message: map['message'] as String,
      userMessage: map['userMessage'] as String,
      technicalDetails: map['technicalDetails'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      stackTrace: map['stackTrace'] as String?,
    );
  }
}

/// Service for handling errors and providing user-friendly error messages
class ErrorHandlingService {

  /// Handle and log errors with user-friendly messages
  static ErrorInfo handleError(
    dynamic error, {
    ErrorType? type,
    ErrorSeverity? severity,
    String? context,
    StackTrace? stackTrace,
  }) {
    try {
      // Determine error type if not provided
      final errorType = type ?? _determineErrorType(error);
      
      // Determine severity if not provided
      final errorSeverity = severity ?? _determineErrorSeverity(errorType);
      
      // Get error message
      final errorMessage = _getErrorMessage(error);
      
      // Get user-friendly message
      final userMessage = _getUserFriendlyMessage(errorType, errorMessage);
      
      // Create error info
      final errorInfo = ErrorInfo(
        type: errorType,
        severity: errorSeverity,
        message: errorMessage,
        userMessage: userMessage,
        technicalDetails: context != null ? 'Context: $context' : null,
        timestamp: DateTime.now(),
        stackTrace: stackTrace?.toString(),
      );
      
      // Log error
      _logError(errorInfo);
      
      return errorInfo;
    } catch (e) {
      // Fallback error handling
      debugPrint('ErrorHandlingService: Error in error handling: $e');
      return ErrorInfo(
        type: ErrorType.unknownError,
        severity: ErrorSeverity.critical,
        message: 'Unknown error occurred',
        userMessage: 'Something went wrong. Please try again.',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Show error dialog to user
  static void showErrorDialog(BuildContext context, ErrorInfo errorInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getErrorTitle(errorInfo.severity)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorInfo.userMessage),
            if (errorInfo.technicalDetails != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Technical Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                errorInfo.technicalDetails!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (errorInfo.severity == ErrorSeverity.critical)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showRecoveryOptions(context, errorInfo);
              },
              child: const Text('Recovery Options'),
            ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, ErrorInfo errorInfo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorInfo.userMessage),
        backgroundColor: _getErrorColor(errorInfo.severity),
        duration: Duration(seconds: errorInfo.severity == ErrorSeverity.critical ? 10 : 5),
        action: errorInfo.severity == ErrorSeverity.critical
            ? SnackBarAction(
                label: 'Details',
                onPressed: () => showErrorDialog(context, errorInfo),
              )
            : null,
      ),
    );
  }

  /// Get retry suggestion for error
  static String? getRetrySuggestion(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.networkError:
        return 'Check your internet connection and try again.';
      case ErrorType.syncFailure:
        return 'Try syncing your data again.';
      case ErrorType.migrationError:
        return 'Try restarting the app to retry migration.';
      case ErrorType.validationError:
        return 'Please check your input and try again.';
      case ErrorType.authenticationError:
        return 'Please log in again.';
      case ErrorType.storageError:
        return 'Try clearing app data and restarting.';
      case ErrorType.dataCorruption:
        return 'Your data may need to be repaired. Contact support if the problem persists.';
      case ErrorType.unknownError:
        return 'Try restarting the app.';
    }
  }

  /// Get recovery actions for critical errors
  static List<String> getRecoveryActions(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.dataCorruption:
        return [
          'Repair Data',
          'Restore from Backup',
          'Reset to Defaults',
        ];
      case ErrorType.migrationError:
        return [
          'Retry Migration',
          'Rollback Migration',
          'Reset to Defaults',
        ];
      case ErrorType.syncFailure:
        return [
          'Retry Sync',
          'Clear Sync Queue',
          'Reset Sync Status',
        ];
      case ErrorType.storageError:
        return [
          'Clear Cache',
          'Reset Storage',
          'Reinstall App',
        ];
      default:
        return [
          'Restart App',
          'Contact Support',
        ];
    }
  }

  /// Private helper methods

  static ErrorType _determineErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return ErrorType.networkError;
    } else if (errorString.contains('sync') || errorString.contains('synchronization')) {
      return ErrorType.syncFailure;
    } else if (errorString.contains('migration') || errorString.contains('migrate')) {
      return ErrorType.migrationError;
    } else if (errorString.contains('validation') || errorString.contains('validate')) {
      return ErrorType.validationError;
    } else if (errorString.contains('auth') || errorString.contains('login')) {
      return ErrorType.authenticationError;
    } else if (errorString.contains('storage') || errorString.contains('hive') || errorString.contains('firebase')) {
      return ErrorType.storageError;
    } else if (errorString.contains('corrupt') || errorString.contains('integrity')) {
      return ErrorType.dataCorruption;
    } else {
      return ErrorType.unknownError;
    }
  }

  static ErrorSeverity _determineErrorSeverity(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.dataCorruption:
      case ErrorType.migrationError:
        return ErrorSeverity.critical;
      case ErrorType.syncFailure:
      case ErrorType.storageError:
        return ErrorSeverity.high;
      case ErrorType.networkError:
      case ErrorType.authenticationError:
        return ErrorSeverity.medium;
      case ErrorType.validationError:
        return ErrorSeverity.low;
      case ErrorType.unknownError:
        return ErrorSeverity.medium;
    }
  }

  static String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString();
    } else if (error is String) {
      return error;
    } else {
      return 'Unknown error: $error';
    }
  }

  static String _getUserFriendlyMessage(ErrorType errorType, String errorMessage) {
    switch (errorType) {
      case ErrorType.networkError:
        return 'Unable to connect to the internet. Please check your connection and try again.';
      case ErrorType.syncFailure:
        return 'Failed to sync your data. Your information is saved locally and will sync when possible.';
      case ErrorType.migrationError:
        return 'There was a problem updating your data. Please restart the app to try again.';
      case ErrorType.validationError:
        return 'Please check your input and try again.';
      case ErrorType.authenticationError:
        return 'Please log in again to continue.';
      case ErrorType.storageError:
        return 'There was a problem saving your data. Please try again.';
      case ErrorType.dataCorruption:
        return 'Your data may be corrupted. We can help you repair it.';
      case ErrorType.unknownError:
        return 'Something went wrong. Please try again or contact support if the problem persists.';
    }
  }

  static String _getErrorTitle(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return 'Notice';
      case ErrorSeverity.medium:
        return 'Warning';
      case ErrorSeverity.high:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical Error';
    }
  }

  static Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  static void _logError(ErrorInfo errorInfo) {
    debugPrint('ErrorHandlingService: ${errorInfo.type.name} - ${errorInfo.message}');
    if (errorInfo.stackTrace != null) {
      debugPrint('ErrorHandlingService: Stack trace: ${errorInfo.stackTrace}');
    }
  }

  static void _showRecoveryOptions(BuildContext context, ErrorInfo errorInfo) {
    final recoveryActions = getRecoveryActions(errorInfo.type);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recovery Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: recoveryActions.map((action) => ListTile(
            title: Text(action),
            onTap: () {
              Navigator.of(context).pop();
              _performRecoveryAction(context, action, errorInfo);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static void _performRecoveryAction(BuildContext context, String action, ErrorInfo errorInfo) {
    // Implementation would depend on the specific recovery action
    debugPrint('ErrorHandlingService: Performing recovery action: $action');
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text('Are you sure you want to $action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Perform the actual recovery action here
              _executeRecoveryAction(action, errorInfo);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  static void _executeRecoveryAction(String action, ErrorInfo errorInfo) {
    // Implementation would depend on the specific recovery action
    debugPrint('ErrorHandlingService: Executing recovery action: $action for error: ${errorInfo.type.name}');
  }
}
