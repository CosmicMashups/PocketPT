import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

/// Base responsive dialog widget with overflow protection and consistent theming
class ResponsiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final IconData? icon;
  final bool barrierDismissible;
  final EdgeInsets? contentPadding;
  final double? maxWidth;
  final double? maxHeight;

  const ResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.icon,
    this.barrierDismissible = true,
    this.contentPadding,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate responsive dimensions
    final dialogMaxWidth = maxWidth ?? _calculateMaxWidth(screenSize);
    final dialogMaxHeight = maxHeight ?? _calculateMaxHeight(screenSize);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: _calculateHorizontalPadding(screenSize),
        vertical: _calculateVerticalPadding(screenSize),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: dialogMaxHeight,
        ),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, isDark),
            Flexible(
              child: _buildContent(context, isDark),
            ),
            if (actions.isNotEmpty) _buildActions(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: isDark 
            ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
            : kMainColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kMainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: kMainColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: _calculateTitleFontSize(MediaQuery.of(context).size),
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : kTextHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Container(
      padding: contentPadding ?? const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: SingleChildScrollView(
        child: content,
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isDark 
            ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
            : Colors.grey.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: action,
          );
        }).toList(),
      ),
    );
  }

  double _calculateMaxWidth(Size screenSize) {
    if (screenSize.width < 600) {
      return screenSize.width * 0.9;
    } else if (screenSize.width < 1024) {
      return 500;
    } else {
      return 600;
    }
  }

  double _calculateMaxHeight(Size screenSize) {
    return screenSize.height * 0.8;
  }

  double _calculateHorizontalPadding(Size screenSize) {
    if (screenSize.width < 600) {
      return 16;
    } else {
      return 24;
    }
  }

  double _calculateVerticalPadding(Size screenSize) {
    if (screenSize.height < 600) {
      return 16;
    } else {
      return 32;
    }
  }

  double _calculateTitleFontSize(Size screenSize) {
    if (screenSize.width < 600) {
      return 18;
    } else {
      return 20;
    }
  }
}

/// Specialized info dialog for displaying information
class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.buttonText = 'OK',
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog(
      title: title,
      icon: icon,
      content: Text(
        message,
        style: GoogleFonts.ptSans(
          fontSize: 16,
          height: 1.5,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white70 
              : kTextNormal,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: kMainColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            buttonText,
            style: GoogleFonts.ptSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Specialized confirmation dialog for user actions
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final IconData icon;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.icon = Icons.help_outline,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog(
      title: title,
      icon: icon,
      content: Text(
        message,
        style: GoogleFonts.ptSans(
          fontSize: 16,
          height: 1.5,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white70 
              : kTextNormal,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: kTextNormal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            cancelText,
            style: GoogleFonts.ptSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? kErrorColor : kMainColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmText,
            style: GoogleFonts.ptSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Specialized loading dialog for async operations
class LoadingDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool barrierDismissible;

  const LoadingDialog({
    super.key,
    this.title = 'Loading',
    this.message = 'Please wait...',
    this.barrierDismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog(
      title: title,
      icon: Icons.hourglass_empty,
      barrierDismissible: barrierDismissible,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : kTextNormal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: const [],
    );
  }
}

/// Utility functions for showing dialogs
class DialogUtils {
  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    String buttonText = 'OK',
    VoidCallback? onButtonPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => InfoDialog(
        title: title,
        message: message,
        icon: icon,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
      ),
    );
  }

  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    IconData icon = Icons.help_outline,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        icon: icon,
        isDestructive: isDestructive,
      ),
    );
  }

  static Future<void> showLoadingDialog({
    required BuildContext context,
    String title = 'Loading',
    String message = 'Please wait...',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => LoadingDialog(
        title: title,
        message: message,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}

