import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import '../data/functions.dart';

import 'b_focus1.dart';
import 'c_camera.dart';

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
  String painLevel = UserAssess.painLevel;
  int painScale = UserAssess.painScale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Pain Assessment",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E1E1E)),
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
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: 0.6,
              minHeight: 8,
              color: const Color(0xFF800020),
              backgroundColor: const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 20),

            // Header with icon
            Row(
              children: [
                const Icon(Icons.local_hospital, color: Color(0xFF800020)),
                const SizedBox(width: 8),
                Text(
                  "Question 3 of 5",
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF800020),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              "Observe Your Range of Motion",
              style: GoogleFonts.ptSans(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E1E1E),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "To better understand the intensity of your pain, follow the guided video instructions. This helps assess the condition of your ${UserAssess.specificMuscle}.",
              style: GoogleFonts.ptSans(
                fontSize: 18,
                color: const Color(0xFF3A3A3A),
              ),
            ),

            const SizedBox(height: 28),

            // Video container with label
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Instructional Video",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
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

            const SizedBox(height: 40),

            // Record button with gradient and icon
            Center(
              child: GestureDetector(
                onTap: () {
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
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB22222), Color(0xFF800020)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.videocam_rounded, color: Colors.white, size: 30),
                      SizedBox(height: 8),
                      Text(
                        "Tap to Record",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}