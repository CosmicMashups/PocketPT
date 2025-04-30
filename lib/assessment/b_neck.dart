// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import 'b_focus1.dart';
import 'c_video.dart';
import '../functions.dart';

class AssessNeck extends StatefulWidget {
  const AssessNeck({super.key});

  @override
  State<AssessNeck> createState() => _AssessNeckState();
}

class _AssessNeckState extends State<AssessNeck> {
  String specificMuscle = UserAssess.specificMuscle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Focus Area: Neck & Upper Back",
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
              pageBuilder: (context, animation, secondaryAnimation) => AssessFocus1(),
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
                    "What particular muscle would you like to focus on?",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Custom Radio Tiles
                  CustomImageRadioTile<String>(
                    value: 'Neck',
                    groupValue: specificMuscle,
                    title: 'Cervical Muscles',
                    description: 'Muscles supporting head movement and maintaining posture.',
                    image: Image.asset(
                      'assets/images/muscle_region/upper_body.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    onChanged: (val) {
                      setState(() {
                        specificMuscle = val!;
                        UserAssess.specificMuscle = val;
                      });
                    },
                  ),
                  
                  CustomImageRadioTile<String>(
                    value: 'Upper Back',
                    groupValue: specificMuscle,
                    title: 'Thoracic Region',
                    description: 'Muscles like the trapezius that support shoulder movement and spinal alignment.',
                    image: Image.asset(
                      'assets/images/muscle_region/upper_body.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    onChanged: (val) {
                      setState(() {
                        specificMuscle = val!;
                        UserAssess.specificMuscle = val;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // Text(
                  //   'Selected Choice: $specificMuscle',
                  //   style: const TextStyle(
                  //     fontSize: 20,
                  //   ),
                  // ),

                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => AssessPainVideo(),
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