// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'globals.dart';
import '../functions.dart';

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
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Pain: Level (Camera)",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E1E1E)),
          onPressed: () {
            Widget nextPage;

            if (UserAssess.generalMuscle == "Upper Body") {
              nextPage = AssessUpperBody();
            } else if (UserAssess.generalMuscle == "Lower Body") {
              nextPage = AssessLowerBody();
            } else if (UserAssess.generalMuscle == "Core Area") {
              nextPage = AssessCore();
            } else if (UserAssess.generalMuscle == "Neck & Upper Back") {
              nextPage = AssessNeck();
            } else if (UserAssess.generalMuscle == "Joints") {
              nextPage = AssessJoints();
            } else {
              // Default
              nextPage = AssessFocus1();
            }

            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => nextPage,
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
        }),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress Line
            LinearProgressIndicator(
              value: 0.6,
              minHeight: 8,
              color: const Color(0xFF800020),
              backgroundColor: const Color(0xFF404040),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Question 3 of 5"
                  Text(
                    "Question 3 of 5",
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF800020),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Question Text
                  Text(
                    "Let's evaluate your pain by observing your range of movement.",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Question Text
                  Text(
                    "Record yourself as you follow the instructions in the provided video to assess the pain level of your ${UserAssess.specificMuscle}.",
                    style: GoogleFonts.ptSans(
                      fontSize: 18,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Video
                  Center(child: LocalVideoPlayer(videoPath: '../../assets/videos/arom_elbow.mp4')),                  
                  
                  const SizedBox(height: 30),

                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => AssessPainCamera(),
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
                        },  // Button press event
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF800020), // Button color
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt,  // Camera icon
                              size: 30,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap to record",  // Text below the icon
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}