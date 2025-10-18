import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import 'assessment_data.dart';
import '../data/functions.dart';
import 'b_focus1.dart';
import 'c_camera.dart';
import 'c_painlevel.dart';
import 'b_upperbody.dart';
import 'b_lowerbody.dart';
import 'b_core.dart';
import 'b_neck.dart';
import 'b_joints.dart';

class AssessPainVideo extends StatefulWidget {
  const AssessPainVideo({super.key});

  @override
  State<AssessPainVideo> createState() => _AssessPainVideoState();
}

class _AssessPainVideoState extends State<AssessPainVideo> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    print('AssessPainVideo: initState() called');
    print('AssessPainVideo: Current AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
    print('AssessPainVideo: Current UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
    print('AssessPainVideo: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('AssessPainVideo: build() called');
    print('AssessPainVideo: Current AssessmentData.specificMuscle in build = "${AssessmentData.specificMuscle}"');
    print('AssessPainVideo: Current UserAssess.specificMuscle in build = "${UserAssess.specificMuscle}"');
    
    try {
      return _buildPageContent(context);
    } catch (e) {
      print('AssessPainVideo: ERROR in build() - $e');
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
            onPressed: () {
              Widget nextPage;
              switch (UserAssess.generalMuscle) {
                case "Upper Body":
                  nextPage = AssessUpperBody();
                  break;
                case "Lower Body":
                  nextPage = AssessLowerBody();
                  break;
                case "Core Area":
                  nextPage = AssessCore();
                  break;
                case "Neck & Upper Back":
                  nextPage = AssessNeck();
                  break;
                case "Joints":
                  nextPage = AssessJoints();
                  break;
                default:
                  nextPage = AssessFocus1();
              }

              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => nextPage,
                  transitionsBuilder: (_, animation, __, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                ),
              );
            },
          ),
          Expanded(
            child: Text(
              "ROM Assessment",
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
              const Spacer(),
              Text(
                "Step 3 of 5",
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: detailColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.6,
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
            "Range of Motion Assessment",
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
          Container(
            height: 200, // Fixed height to prevent size issues
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LocalVideoPlayer(videoPath: 'assets/videos/arom_elbow.mp4'),
            ),
          ),
        ],
      ),
    );
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
                    pageBuilder: (_, __, ___) => const AssessPainCamera(),
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
              pageBuilder: (_, __, ___) => const AssessPainLevel(),
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