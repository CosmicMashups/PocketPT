import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enhanced design system for camera and recording interface
/// Provides medical-grade styling with professional aesthetics
class RecordingDesignSystem {
  // Enhanced color palette with medical-grade aesthetics
  static const Color primaryMedical = Color(0xFF8B2E2E);
  static const Color secondaryMedical = Color(0xFFC24A4A);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Neutral palette for professional appearance
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F1012);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF111315);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);

  // Spacing system (8px grid)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacingXXXL = 64.0;

  // Border radius system
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;

  // Typography scale
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.25,
  );

  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.ptSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.ptSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.ptSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get labelLarge => GoogleFonts.ptSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.ptSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // Shadow system for depth and hierarchy
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowXLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // Medical-themed shadows with brand colors
  static List<BoxShadow> get medicalShadow => [
    BoxShadow(
      color: primaryMedical.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 2,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get medicalShadowLarge => [
    BoxShadow(
      color: primaryMedical.withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 12),
      spreadRadius: 3,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Animation timing constants
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Animation curves
  static const Curve animationCurve = Curves.easeInOutCubic;
  static const Curve animationCurveFast = Curves.easeOutCubic;

  // Adaptive color helper
  static Color getAdaptiveColor(BuildContext context, Color lightColor, Color darkColor) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }

  // Get semantic colors based on context
  static Color getSuccessColor(BuildContext context) => getAdaptiveColor(
    context, 
    successColor, 
    const Color(0xFF34D399),
  );

  static Color getWarningColor(BuildContext context) => getAdaptiveColor(
    context, 
    warningColor, 
    const Color(0xFFFBBF24),
  );

  static Color getErrorColor(BuildContext context) => getAdaptiveColor(
    context, 
    errorColor, 
    const Color(0xFFF87171),
  );

  static Color getInfoColor(BuildContext context) => getAdaptiveColor(
    context, 
    infoColor, 
    const Color(0xFF60A5FA),
  );

  // Get background colors
  static Color getBackgroundColor(BuildContext context) => getAdaptiveColor(
    context, 
    backgroundLight, 
    backgroundDark,
  );

  static Color getSurfaceColor(BuildContext context) => getAdaptiveColor(
    context, 
    surfaceLight, 
    surfaceDark,
  );

  static Color getTextPrimaryColor(BuildContext context) => getAdaptiveColor(
    context, 
    textPrimary, 
    Colors.white,
  );

  static Color getTextSecondaryColor(BuildContext context) => getAdaptiveColor(
    context, 
    textSecondary, 
    const Color(0xFF9CA3AF),
  );

  static Color getBorderColor(BuildContext context) => getAdaptiveColor(
    context, 
    borderLight, 
    borderDark,
  );
}
