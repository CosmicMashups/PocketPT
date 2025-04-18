// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'globals.dart';
import 'b_focus1.dart';
import 'c_video.dart';
import '../functions.dart';

class AssessCore extends StatefulWidget {
  const AssessCore({super.key});

  @override
  State<AssessCore> createState() => _AssessCoreState();
}

class _AssessCoreState extends State<AssessCore> {
  String specificMuscle = UserAssess.specificMuscle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Focus Area: Core Area",
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
                    value: 'Abdominals',
                    groupValue: specificMuscle,
                    title: 'Abdominals',
                    description: 'Muscles in the front of the abdomen that support trunk movement and maintain posture.',
                    image: Image.asset(
                      '../../assets/images/muscle_region/upper_body.png',
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
                    value: 'Obliques',
                    groupValue: specificMuscle,
                    title: 'Obliques',
                    description: 'Side abdominal muscles that assist in trunk rotation and lateral flexion.',
                    image: Image.asset(
                      '../../assets/images/muscle_region/upper_body.png',
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
                    value: 'Lower Back',
                    groupValue: specificMuscle,
                    title: 'Lower Back',
                    description: 'Muscles supporting spinal stability and helping with trunk extension.',
                    image: Image.asset(
                      '../../assets/images/muscle_region/upper_body.png',
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
                    value: 'Diaphragm',
                    groupValue: specificMuscle,
                    title: 'Diaphragm',
                    description: 'Dome-shaped muscle under the lungs essential for breathing.',
                    image: Image.asset(
                      '../../assets/images/muscle_region/upper_body.png',
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
                    value: 'Multifidus',
                    groupValue: specificMuscle,
                    title: 'Multifidus',
                    description: 'Deep spinal muscles that stabilize vertebrae during movement.',
                    image: Image.asset(
                      '../../assets/images/muscle_region/upper_body.png',
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
                        padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 16),
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