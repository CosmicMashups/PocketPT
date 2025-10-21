import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

/// Hero animation elements for shared UI components across pages
/// Provides consistent Hero animations for logos, profile images, and other shared elements
class HeroElements {
  static const String logoHeroTag = 'pocketpt_logo';
  static const String profileHeroTag = 'user_profile_image';
  static const String exerciseCardHeroTag = 'exercise_card';
  static const String progressHeroTag = 'progress_indicator';

  /// Animated logo with Hero transition
  static Widget animatedLogo({
    required String heroTag,
    double size = 60.0,
    bool showGlow = true,
  }) {
    return Hero(
      tag: heroTag,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [kMainColor, kSubColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: showGlow ? [
            BoxShadow(
              color: kMainColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ] : null,
        ),
        child: ClipOval(
          child: Container(
            padding: EdgeInsets.all(size * 0.1),
            child: Image.asset(
              'assets/images/pocketpt.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.medical_services,
                  color: Colors.white,
                  size: size * 0.6,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Animated profile image with Hero transition
  static Widget animatedProfileImage({
    required String heroTag,
    required String imagePath,
    double size = 80.0,
    bool showBorder = true,
    Color borderColor = const Color(0xFF557A95),
  }) {
    return Hero(
      tag: heroTag,
      child: Container(
        decoration: showBorder ? BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor.withOpacity(0.3),
            width: 2,
          ),
        ) : null,
        child: CircleAvatar(
          radius: size / 2,
          backgroundImage: AssetImage(imagePath),
          backgroundColor: Colors.grey[200],
        ),
      ),
    );
  }

  /// Animated exercise card with Hero transition
  static Widget animatedExerciseCard({
    required String heroTag,
    required String title,
    required String description,
    required VoidCallback onTap,
    String? imagePath,
    Color? accentColor,
    bool isCompleted = false,
  }) {
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isCompleted ? Border.all(
                color: kSuccessColor,
                width: 2,
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (imagePath != null) ...[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: (accentColor ?? kMainColor).withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: accentColor ?? kMainColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          color: kTextNormal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted) ...[
                  Icon(
                    Icons.check_circle,
                    color: kSuccessColor,
                    size: 24,
                  ),
                ] else ...[
                  Icon(
                    Icons.arrow_forward_ios,
                    color: kTextNormal,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Animated progress indicator with Hero transition
  static Widget animatedProgressIndicator({
    required String heroTag,
    required double progress,
    required String title,
    String? subtitle,
    Color? progressColor,
    double height = 8.0,
  }) {
    return Hero(
      tag: heroTag,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextHeading,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  color: kTextNormal,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? kMainColor,
                ),
                minHeight: height,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}% Complete',
              style: GoogleFonts.ptSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: progressColor ?? kMainColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Animated notification card with Hero transition
  static Widget animatedNotificationCard({
    required String heroTag,
    required String title,
    required String message,
    required VoidCallback onTap,
    IconData? icon,
    Color? accentColor,
    bool isUrgent = false,
  }) {
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.red[50] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isUrgent ? Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (accentColor ?? (isUrgent ? Colors.red : kMainColor)).withOpacity(0.1),
                  ),
                  child: Icon(
                    icon ?? (isUrgent ? Icons.warning : Icons.notifications),
                    color: accentColor ?? (isUrgent ? Colors.red : kMainColor),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextHeading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: GoogleFonts.ptSans(
                          fontSize: 12,
                          color: kTextNormal,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: kTextNormal,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Animated loading skeleton with Hero transition
  static Widget animatedLoadingSkeleton({
    required String heroTag,
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Hero(
      tag: heroTag,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
          ),
        ),
      ),
    );
  }
}
