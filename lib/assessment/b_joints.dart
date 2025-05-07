// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import 'b_focus1.dart';
import 'c_video.dart';
import '../data/functions.dart';

class AssessJoints extends StatefulWidget {
  const AssessJoints({super.key});

  @override
  State<AssessJoints> createState() => _AssessJointsState();
}

class _AssessJointsState extends State<AssessJoints> {
  String specificMuscle = UserAssess.specificMuscle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Focus Area: Joints",
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
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: const Color(0xFF800020), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Question 2 of 5",
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF800020),
                        ),
                      ),
                    ],
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
                    value: 'Elbow',
                    groupValue: specificMuscle,
                    title: 'Elbow',
                    description: 'A hinge joint enabling arm bending and extension, supported by surrounding muscles and tendons.',
                    image: Image.asset(
                      'assets/images/muscle_region/joints.png',
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
                    value: 'Knee',
                    groupValue: specificMuscle,
                    title: 'Knee',
                    description: 'A complex joint that allows leg bending and straightening, vital for standing and movement.',
                    image: Image.asset(
                      'assets/images/muscle_region/joints.png',
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
                    value: 'Ankle',
                    groupValue: specificMuscle,
                    title: 'Ankle',
                    description: 'A flexible joint connecting the foot to the leg, essential for walking, running, and balance.',
                    image: Image.asset(
                      'assets/images/muscle_region/joints.png',
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