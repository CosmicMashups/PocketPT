import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import '../assessment/assessment_data.dart';
import '../assessment/local_muscle_video_player.dart';
import 'cameraPose.dart';
import 'painLevel.dart';

class InstructionVideoPage extends StatefulWidget {
  const InstructionVideoPage({super.key});

  @override
  State<InstructionVideoPage> createState() => _InstructionVideoPageState();
}

class _InstructionVideoPageState extends State<InstructionVideoPage> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    print('InstructionVideoPage: initState() called');
    print('InstructionVideoPage: Current AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
    print('InstructionVideoPage: Current UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
    print('InstructionVideoPage: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('InstructionVideoPage: build() called');
    print('InstructionVideoPage: Current AssessmentData.specificMuscle in build = "${AssessmentData.specificMuscle}"');
    print('InstructionVideoPage: Current UserAssess.specificMuscle in build = "${UserAssess.specificMuscle}"');
    
    try {
      return _buildPageContent(context);
    } catch (e) {
      print('InstructionVideoPage: ERROR in build() - $e');
      return Container(
        color: backgroundColor,
        child: Center(
          child: Text(
            'Error loading page: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildPageContent(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: Column(
        children: [
          _buildAppBar(context),
          Flexible(
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                    _buildQuestionSection(),
                    const SizedBox(height: 24),
                    _buildVideoSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(context),
                    const SizedBox(height: 16),
                    _buildSkipButton(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: mainColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              "Daily Assessment",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.refresh, color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment, color: Colors.black87, size: 20),
              const SizedBox(width: 8),
              Text(
                "Assessment Progress",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Step 1 of 3",
              style: GoogleFonts.ptSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: detailColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.33,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(mainColor),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_outline, color: Colors.black87, size: 24),
              const SizedBox(width: 12),
              Text(
                "Range of Motion",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Follow the guided video instructions to assess your ${UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle.toLowerCase() : 'muscle'}. This helps us understand your current range of motion and identify any limitations.",
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: detailColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    // Get the selected muscle with fallback logic
    final selectedMuscle = _getSelectedMuscle();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.video_library, color: Colors.black87, size: 20),
              const SizedBox(width: 8),
              Text(
                "Instructional Video",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Local video player with proper aspect ratio
          LocalMuscleVideoPlayer(
            muscleName: selectedMuscle,
            showMuscleInfo: false, // Info is already shown in the question section
            showControls: true,
            autoPlay: false,
          ),
        ],
      ),
    );
  }

  /// Get the selected muscle with proper fallback logic
  String _getSelectedMuscle() {
    // Try UserAssess first (most recent selection)
    if (UserAssess.specificMuscle.isNotEmpty) {
      return UserAssess.specificMuscle;
    }
    
    // Fallback to AssessmentData
    if (AssessmentData.specificMuscle.isNotEmpty) {
      return AssessmentData.specificMuscle;
    }
    
    // Final fallback to a default muscle
    return 'Deltoids';
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [mainColor, subColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const CameraPosePage(),
                    transitionsBuilder: (_, animation, __, child) => SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.easeInOut)),
                      ),
                      child: child,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Start Recording",
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const PainLevelPage(),
              transitionsBuilder: (_, animation, __, child) => SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: child,
              ),
            ),
          );
        },
        child: Text(
          "Skip Camera Assessment",
          style: GoogleFonts.ptSans(
            fontSize: 14,
            color: detailColor,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}