import 'package:flutter/material.dart';

/// Navigation service for consistent page transitions and workflow optimization
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get current context
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate to a page with slide transition
  static Future<T?> navigateWithSlide<T extends Object?>(
    Widget page, {
    bool replace = false,
    bool clearStack = false,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);

    final route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );

    if (clearStack) {
      return Navigator.pushAndRemoveUntil(
        context,
        route,
        (route) => false,
      );
    } else if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Navigate to a page with fade transition
  static Future<T?> navigateWithFade<T extends Object?>(
    Widget page, {
    bool replace = false,
    bool clearStack = false,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);

    final route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );

    if (clearStack) {
      return Navigator.pushAndRemoveUntil(
        context,
        route,
        (route) => false,
      );
    } else if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Navigate to a page with scale transition
  static Future<T?> navigateWithScale<T extends Object?>(
    Widget page, {
    bool replace = false,
    bool clearStack = false,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);

    final route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
    );

    if (clearStack) {
      return Navigator.pushAndRemoveUntil(
        context,
        route,
        (route) => false,
      );
    } else if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }

  /// Navigate back
  static void goBack<T extends Object?>([T? result]) {
    final context = currentContext;
    if (context != null && Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  /// Navigate back to a specific route
  static void goBackTo(String routeName) {
    final context = currentContext;
    if (context != null) {
      Navigator.popUntil(context, (route) => route.settings.name == routeName);
    }
  }

  /// Show a dialog with consistent styling
  static Future<T?> showCustomDialog<T extends Object?>(
    Widget dialog, {
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      builder: (context) => dialog,
    );
  }

  /// Show a bottom sheet with consistent styling
  static Future<T?> showCustomBottomSheet<T extends Object?>(
    Widget bottomSheet, {
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
  }) {
    final context = currentContext;
    if (context == null) return Future.value(null);

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => bottomSheet,
    );
  }

  /// Show a snackbar with consistent styling
  static void showSnackBar(
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final context = currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF8B2E2E),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show loading dialog
  static void showLoadingDialog({String message = 'Loading...'}) {
    final context = currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog() {
    final context = currentContext;
    if (context != null && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Show error dialog
  static Future<void> showErrorDialog({
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    final context = currentContext;
    if (context == null) return Future.value();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: onPressed ?? () => Navigator.pop(context),
            child: Text(buttonText ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) {
    final context = currentContext;
    if (context == null) return Future.value(false);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText ?? 'Confirm'),
          ),
        ],
      ),
    ).then((result) => result ?? false);
  }
}
