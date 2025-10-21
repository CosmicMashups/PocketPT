import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // Import color constants

/// Main responsive loading screen with PocketPT branding
class ResponsiveLoadingScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? progress;
  final bool showLogo;
  final bool showProgress;
  final VoidCallback? onRetry;
  final bool isError;
  final String? errorMessage;

  const ResponsiveLoadingScreen({
    super.key,
    required this.title,
    this.subtitle = '',
    this.progress,
    this.showLogo = true,
    this.showProgress = false,
    this.onRetry,
    this.isError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1024;

    return Scaffold(
      backgroundColor: isDark 
          ? Theme.of(context).scaffoldBackgroundColor 
          : kBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? screenSize.width * 0.9 : 400,
              maxHeight: screenSize.height * 0.8,
            ),
            padding: EdgeInsets.all(isMobile ? 24 : 32),
            decoration: BoxDecoration(
              color: isDark 
                  ? Theme.of(context).colorScheme.surface 
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Section
                if (showLogo) ...[
                  _buildLogoSection(context, isDark, isMobile, isTablet),
                  SizedBox(height: isMobile ? 24 : 32),
                ],
                
                // Title Section
                _buildTitleSection(context, isDark, isMobile),
                
                // Subtitle Section
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildSubtitleSection(context, isDark, isMobile),
                ],
                
                // Progress Section
                if (showProgress && progress != null) ...[
                  SizedBox(height: isMobile ? 24 : 32),
                  _buildProgressSection(context, isDark, isMobile),
                ],
                
                // Error Section
                if (isError) ...[
                  SizedBox(height: isMobile ? 24 : 32),
                  _buildErrorSection(context, isDark, isMobile),
                ],
                
                // Loading Indicator
                if (!isError) ...[
                  SizedBox(height: isMobile ? 24 : 32),
                  _buildLoadingIndicator(context, isDark, isMobile),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, bool isDark, bool isMobile, bool isTablet) {
    final logoSize = isMobile ? 80.0 : (isTablet ? 100.0 : 120.0);
    
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [kMainColor, kSubColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kMainColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'assets/images/pocketpt.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.medical_services,
                color: Colors.white,
                size: logoSize * 0.6,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, bool isDark, bool isMobile) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: isMobile ? 20 : 24,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : kTextHeading,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitleSection(BuildContext context, bool isDark, bool isMobile) {
    return Text(
      subtitle,
      style: GoogleFonts.ptSans(
        fontSize: isMobile ? 14 : 16,
        color: isDark ? Colors.white70 : kTextNormal,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildProgressSection(BuildContext context, bool isDark, bool isMobile) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark ? Colors.white24 : Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
          minHeight: 8,
        ),
        const SizedBox(height: 12),
        Text(
          '${(progress! * 100).toInt()}%',
          style: GoogleFonts.ptSans(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: kMainColor,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection(BuildContext context, bool isDark, bool isMobile) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: kErrorColor,
          size: isMobile ? 48 : 56,
        ),
        const SizedBox(height: 16),
        Text(
          errorMessage ?? 'An error occurred',
          style: GoogleFonts.ptSans(
            fontSize: isMobile ? 14 : 16,
            color: isDark ? Colors.white70 : kTextNormal,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: kMainColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 32,
                vertical: isMobile ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.ptSans(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingIndicator(BuildContext context, bool isDark, bool isMobile) {
    return SizedBox(
      width: isMobile ? 40 : 48,
      height: isMobile ? 40 : 48,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
      ),
    );
  }
}

/// Loading overlay for in-page loading states
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final double? progress;
  final bool showLogo;
  final bool isError;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.progress,
    this.showLogo = true,
    this.isError = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    if (showLogo) ...[
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [kMainColor, kSubColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ClipOval(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              'assets/images/pocketpt.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.medical_services,
                                  color: Colors.white,
                                  size: 30,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Message
                    if (message != null) ...[
                      Text(
                        message!,
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : kTextHeading,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Progress or Loading Indicator
                    if (isError) ...[
                      Icon(
                        Icons.error_outline,
                        color: kErrorColor,
                        size: 40,
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          style: GoogleFonts.ptSans(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : kTextNormal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (onRetry != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.ptSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ] else if (progress != null) ...[
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                            ),
                            Center(
                              child: Text(
                                '${(progress! * 100).toInt()}%',
                                style: GoogleFonts.ptSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kMainColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
