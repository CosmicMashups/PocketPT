import 'package:flutter/material.dart';

/// Medical Design System for PocketPT
/// Provides comprehensive medical styling, colors, typography, and components
/// for professional healthcare interfaces
class MedicalDesignSystem {
  // Medical Color Palette
  static const Color primaryBrand = Color(0xFF8B2E2E); // Deep medical red - main application color
  static const Color primaryLight = Color(0xFFA03A3A); // Lighter red for gradients
  static const Color primaryDark = Color(0xFF6B1F1F); // Darker red for emphasis
  static const Color secondaryMedical = Color(0xFF1E3A8A); // Deep professional blue for secondary actions
  static const Color accentTeal = Color(0xFF0D9488); // Medical teal for highlights and success states
  static const Color successGreen = Color(0xFF059669); // For positive health indicators and completed states
  static const Color warningOrange = Color(0xFFD97706); // For pain levels and caution states
  static const Color dangerRed = Color(0xFFDC2626); // For high pain levels and critical alerts
  static const Color brandAccent = Color(0xFFC1574F); // Complementary red-orange for highlights
  
  // Neutral Grays
  static const Color textPrimary = Color(0xFF374151);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color backgroundClean = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Medical Typography
  static const TextStyle headerStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.bold,
    fontSize: 28,
    color: primaryBrand,
    letterSpacing: 0.5,
  );

  static const TextStyle subheaderStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    color: textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.normal,
    fontSize: 16,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle labelStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: textMuted,
  );

  static const TextStyle medicalDisclaimerStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 12,
    color: textSecondary,
    fontStyle: FontStyle.italic,
  );

  // Medical Card Styling
  static BoxDecoration medicalCardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
    border: Border.all(
      color: primaryBrand.withOpacity(0.1),
      width: 1,
    ),
  );

  static BoxDecoration medicalCardAccentDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: primaryBrand.withOpacity(0.15),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
    border: Border.all(
      color: primaryBrand,
      width: 2,
    ),
  );

  // Medical Button Styling
  static ButtonStyle primaryMedicalButton = ElevatedButton.styleFrom(
    backgroundColor: primaryBrand,
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: primaryBrand.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  );

  static ButtonStyle secondaryMedicalButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: primaryBrand,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: primaryBrand, width: 2),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  );

  static ButtonStyle warningMedicalButton = ElevatedButton.styleFrom(
    backgroundColor: warningOrange,
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: warningOrange.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  );

  // Medical Progress Indicators
  static Widget medicalProgressIndicator({
    required double value,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: medicalCardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: labelStyle),
              Text('${(value * 100).toInt()}%', style: subheaderStyle),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            backgroundColor: primaryBrand.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color ?? primaryBrand),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  // Medical Status Badges
  static Widget medicalStatusBadge({
    required String text,
    required MedicalStatus status,
  }) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case MedicalStatus.success:
        backgroundColor = successGreen.withOpacity(0.1);
        textColor = successGreen;
        break;
      case MedicalStatus.warning:
        backgroundColor = warningOrange.withOpacity(0.1);
        textColor = warningOrange;
        break;
      case MedicalStatus.danger:
        backgroundColor = dangerRed.withOpacity(0.1);
        textColor = dangerRed;
        break;
      case MedicalStatus.info:
        backgroundColor = accentTeal.withOpacity(0.1);
        textColor = accentTeal;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Medical Disclaimer Banner
  static Widget medicalDisclaimerBanner({
    required String text,
    bool isWarning = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning ? warningOrange.withOpacity(0.1) : accentTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? warningOrange : accentTeal,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isWarning ? warningOrange : accentTeal,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isWarning ? warningOrange : accentTeal,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Medical Gradient Background
  static BoxDecoration medicalGradientBackground = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryBrand, primaryLight],
    ),
  );

  // Medical Card with Header
  static Widget medicalCardWithHeader({
    required String title,
    required Widget content,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      decoration: medicalCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryBrand.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: iconColor ?? primaryBrand,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: subheaderStyle.copyWith(color: primaryBrand),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: content,
          ),
        ],
      ),
    );
  }
}

enum MedicalStatus {
  success,
  warning,
  danger,
  info,
}

/// Medical Icons for healthcare contexts
class MedicalIcons {
  static const IconData medicalServices = Icons.medical_services;
  static const IconData healthAndSafety = Icons.health_and_safety;
  static const IconData localHospital = Icons.local_hospital;
  static const IconData fitnessCenter = Icons.fitness_center;
  static const IconData sportsGymnastics = Icons.sports_gymnastics;
  static const IconData directionsRun = Icons.directions_run;
  static const IconData checkCircle = Icons.check_circle;
  static const IconData warning = Icons.warning;
  static const IconData info = Icons.info;
  static const IconData trendingUp = Icons.trending_up;
  static const IconData schedule = Icons.schedule;
  static const IconData timer = Icons.timer;
  static const IconData calendarToday = Icons.calendar_today;
  static const IconData accessibility = Icons.accessibility;
  static const IconData emergency = Icons.emergency;
  static const IconData report = Icons.report;
  static const IconData contactSupport = Icons.contact_support;
}
