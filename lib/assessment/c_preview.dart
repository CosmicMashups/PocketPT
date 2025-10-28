// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../data/globals.dart';
import '../widgets/enhanced_pose_skeleton_painter.dart';
import 'arom/assessment_result.dart';
import 'c_painlevel.dart';

/// Photo preview page for ROM assessment results
/// Displays captured/uploaded photo with pose skeleton overlay and assessment results
class AssessPhotoPreview extends StatefulWidget {
  final File? photoFile;
  final File? videoFile;
  final dynamic assessmentResult; // Can be AssessmentResult or Map
  final Map<String, Offset> landmarks;
  final String muscleGroup;
  final String side;
  final double? confidence;
  final String? imageQuality;
  final int? frameCount;
  final int? totalFrames;

  const AssessPhotoPreview({
    super.key,
    this.photoFile,
    this.videoFile,
    required this.assessmentResult,
    required this.landmarks,
    required this.muscleGroup,
    required this.side,
    this.confidence,
    this.imageQuality,
    this.frameCount,
    this.totalFrames,
  });

  @override
  State<AssessPhotoPreview> createState() => _AssessPhotoPreviewState();
}

class _AssessPhotoPreviewState extends State<AssessPhotoPreview> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  static const successColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);
  static const backgroundColor = Color(0xFFF8FAFC);

  bool _showSkeleton = true;
  double _adjustedPainLevel = 0;

  @override
  void initState() {
    super.initState();
    // Handle both AssessmentResult and Map types
    if (widget.assessmentResult is AssessmentResult) {
      _adjustedPainLevel = (widget.assessmentResult as AssessmentResult).painScore.toDouble();
    } else if (widget.assessmentResult is Map) {
      final result = widget.assessmentResult as Map<String, dynamic>;
      _adjustedPainLevel = (result['painScore'] ?? 5).toDouble();
    } else {
      _adjustedPainLevel = 5.0; // Default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: mainColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Assessment Preview",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            Text(
              "${widget.muscleGroup} (${widget.side} Side)",
              style: GoogleFonts.ptSans(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Skeleton toggle
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.scatter_plot, size: 16, color: mainColor),
                const SizedBox(width: 6),
                Text('Skeleton', style: GoogleFonts.ptSans(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF1F2937))),
                Switch(
                  value: _showSkeleton,
                  activeColor: mainColor,
                  onChanged: (val) => setState(() => _showSkeleton = val),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Photo display with skeleton overlay
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: mainColor.withOpacity(0.3), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: Stack(
                  children: [
                    // Media display (photo or video)
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: widget.photoFile != null
                          ? Image.file(
                              widget.photoFile!,
                              fit: BoxFit.cover,
                            )
                          : widget.videoFile != null
                              ? Container(
                                  color: Colors.black,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.video_library,
                                          size: 64,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Video Assessment',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (widget.frameCount != null && widget.totalFrames != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Processed ${widget.frameCount}/${widget.totalFrames} frames',
                                            style: GoogleFonts.ptSans(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Text(
                                      'No media available',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                    
                    // Skeleton overlay
                    if (_showSkeleton && widget.landmarks.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: EnhancedPoseSkeletonPainter(
                              landmarks: widget.landmarks,
                              showLandmarkLabels: false,
                              strokeWidth: 3.0,
                              pointRadius: 4.0,
                              showConfidence: false,
                            ),
                          ),
                        ),
                      ),
                    
                    // Assessment results overlay
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: mainColor.withOpacity(0.2), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics,
                                  color: mainColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Assessment Results",
                                  style: GoogleFonts.ptSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getAssessmentDisplayLabel(),
                              style: GoogleFonts.ptSans(
                                fontSize: 12,
                                color: _getAssessmentDisplayColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_getAssessmentAngle() != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Angle: ${_getAssessmentAngle()!.toStringAsFixed(1)}°',
                                style: GoogleFonts.ptSans(
                                  fontSize: 11,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                            if (widget.confidence != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Confidence: ${(widget.confidence! * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.ptSans(
                                  fontSize: 11,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pain level indicator and adjustment
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: mainColor.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Detected Pain Level",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: mainColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPainLevelColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getPainLevelColor(), width: 1),
                      ),
                      child: Text(
                        _getPainLevelCategory(),
                        style: GoogleFonts.ptSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getPainLevelColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      "Adjust if needed:",
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${_adjustedPainLevel.round()}/10",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _getPainLevelColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _adjustedPainLevel,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  activeColor: _getPainLevelColor(),
                  inactiveColor: const Color(0xFFE5E7EB),
                  onChanged: (value) {
                    setState(() {
                      _adjustedPainLevel = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: mainColor.withOpacity(0.1), width: 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 25,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Retake/Reselect button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: mainColor.withOpacity(0.3), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _retakePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, color: mainColor, size: 18),
                      label: Text(
                        "Retake Photo",
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: mainColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Proceed button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [mainColor, Color(0xFFC24A4A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: mainColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _proceedToAssessment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      label: Text(
                        "Proceed",
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPainLevelColor() {
    if (_adjustedPainLevel <= 3) return successColor;
    if (_adjustedPainLevel <= 6) return warningColor;
    return errorColor;
  }

  String _getPainLevelCategory() {
    if (_adjustedPainLevel <= 3) return "Low";
    if (_adjustedPainLevel <= 6) return "Moderate";
    return "Severe";
  }

  String _getAssessmentDisplayLabel() {
    if (widget.assessmentResult is AssessmentResult) {
      return (widget.assessmentResult as AssessmentResult).displayLabel;
    } else if (widget.assessmentResult is Map) {
      final result = widget.assessmentResult as Map<String, dynamic>;
      return result['clinicalContext'] ?? result['overallROMStatus'] ?? 'Assessment Complete';
    }
    return 'Assessment Complete';
  }

  Color _getAssessmentDisplayColor() {
    if (widget.assessmentResult is AssessmentResult) {
      return (widget.assessmentResult as AssessmentResult).displayColor;
    } else if (widget.assessmentResult is Map) {
      final result = widget.assessmentResult as Map<String, dynamic>;
      final romStatus = result['overallROMStatus'] ?? 'unknown';
      switch (romStatus) {
        case 'good':
          return successColor;
        case 'low':
          return warningColor;
        case 'moderate':
        case 'severe':
          return errorColor;
        default:
          return mainColor;
      }
    }
    return mainColor;
  }

  double? _getAssessmentAngle() {
    if (widget.assessmentResult is AssessmentResult) {
      final result = widget.assessmentResult as AssessmentResult;
      return result.additionalData['angle'] as double?;
    } else if (widget.assessmentResult is Map) {
      final result = widget.assessmentResult as Map<String, dynamic>;
      return result['angle'] as double?;
    }
    return null;
  }

  void _retakePhoto() {
    Navigator.pop(context);
  }

  void _proceedToAssessment() {
    // Update UserAssess with the adjusted pain level
    UserAssess.painScale = _adjustedPainLevel.round();
    
    // Determine pain level category
    String painLevel;
    if (_adjustedPainLevel <= 3) {
      painLevel = 'Low';
    } else if (_adjustedPainLevel <= 6) {
      painLevel = 'Moderate';
    } else {
      painLevel = 'Severe';
    }
    UserAssess.painLevel = painLevel;

    // Navigate to pain level screen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AssessPainLevel(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}
