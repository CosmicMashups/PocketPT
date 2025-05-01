// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import 'a_goal1.dart';
import '../data/functions.dart';

import 'b_upperbody.dart';
import 'b_lowerbody.dart';
import 'b_core.dart';
import 'b_neck.dart';
import 'b_joints.dart';

class AssessFocus1 extends StatefulWidget {
  const AssessFocus1({super.key});

  @override
  State<AssessFocus1> createState() => _AssessFocus1State();
}

class _AssessFocus1State extends State<AssessFocus1> {
  String generalMuscle = UserAssess.generalMuscle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Focus Area",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => AssessGoal1(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // SlideTransition
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress Line
            LinearProgressIndicator(
              value: 0.4,
              minHeight: 8,
              color: const Color(0xFF800020),
              backgroundColor: const Color(0xFF404040),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Question 2 of 5"
                  Text(
                    "Question 2 of 5",
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF800020),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Question Text
                  Text(
                    "Which general muscle region are you aiming to target?",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Custom Radio Tiles
                  CustomImageRadioTile<String>(
                    value: 'Upper Body',
                    groupValue: generalMuscle,
                    title: 'Upper Body',
                    description: 'Shoulders, arms, and hands',
                    image: Image.asset(
                      'assets/images/muscle_region/upper_body.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    onChanged: (val) {
                      setState(() {
                        generalMuscle = val!;
                        UserAssess.generalMuscle = val;
                      });
                    },
                  ),
                  
                  CustomImageRadioTile<String>(
                    value: 'Lower Body',
                    groupValue: generalMuscle,
                    title: 'Lower Body',
                    description: 'Hips, legs, and feet',
                    image: Image.asset(
                      'assets/images/muscle_region/lower_body.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    onChanged: (val) {
                      setState(() {
                        generalMuscle = val!;
                        UserAssess.generalMuscle = val;
                      });
                    },
                  ),
                  
                  CustomImageRadioTile<String>(
                    value: 'Core Area',
                    groupValue: generalMuscle,
                    title: 'Core Area',
                    description: 'Stomach, and lower back muscles',
                    image: Image.asset(
                      'assets/images/muscle_region/upper_body.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    onChanged: (val) {
                      setState(() {
                        generalMuscle = val!;
                        UserAssess.generalMuscle = val;
                      });
                    },
                  ),
                  
                  CustomImageRadioTile<String>(
                    value: 'Neck & Upper Back',
                    groupValue: generalMuscle,
                    title: 'Neck & Upper Back',
                    description: 'Neck, shoulder blade',
                    image: Image.asset(
                      'assets/images/muscle_region/upper_body.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    onChanged: (val) {
                      setState(() {
                        generalMuscle = val!;
                        UserAssess.generalMuscle = val;
                      });
                    },
                  ),
                  
                  CustomImageRadioTile<String>(
                    value: 'Joints',
                    groupValue: generalMuscle,
                    title: 'Joints',
                    description: 'Elbow, knee, ankle',
                    image: Image.asset(
                      'assets/images/muscle_region/lower_body.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    onChanged: (val) {
                      setState(() {
                        generalMuscle = val!;
                        UserAssess.generalMuscle = val;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // Text(
                  //   'Selected Choice: $generalMuscle',
                  //   style: const TextStyle(
                  //     fontSize: 20,
                  //   ),
                  // ),

                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Widget nextPage;

                        if (generalMuscle == "Upper Body") {
                          nextPage = AssessUpperBody();
                        } else if (generalMuscle == "Lower Body") {
                          nextPage = AssessLowerBody();
                        } else if (generalMuscle == "Core Area") {
                          nextPage = AssessCore();
                        } else if (generalMuscle == "Neck & Upper Back") {
                          nextPage = AssessNeck();
                        } else if (generalMuscle == "Joints") {
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF800020),
                        padding: const EdgeInsets.symmetric(horizontal: 125, vertical: 16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Next",
                            style: GoogleFonts.ptSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}