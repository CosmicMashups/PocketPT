// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import 'b_focus1.dart';
import 'c_video.dart';
import '../data/functions.dart';

class AssessLowerBody extends StatefulWidget {
  const AssessLowerBody({super.key});

  @override
  State<AssessLowerBody> createState() => _AssessLowerBodyState();
}

class _AssessLowerBodyState extends State<AssessLowerBody> {
  String specificMuscle = UserAssess.specificMuscle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Focus Area: Lower Body",
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
                    value: 'Quadriceps',
                    groupValue: specificMuscle,
                    title: 'Quadriceps',
                    description: 'Front thigh muscles that extend the knee and help with walking, running, and jumping.',
                    image: Image.asset(
                      'assets/images/muscle_region/lower_body.png',
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
                    value: 'Hamstrings',
                    groupValue: specificMuscle,
                    title: 'Hamstrings',
                    description: 'Back thigh muscles responsible for knee flexion and hip extension.',
                    image: Image.asset(
                      'assets/images/muscle_region/lower_body.png',
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
                    value: 'Calf',
                    groupValue: specificMuscle,
                    title: 'Calf',
                    description: 'Muscles at the back of the lower leg that allow for ankle movement and push-off during walking.',
                    image: Image.asset(
                      'assets/images/muscle_region/lower_body.png',
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
                    description: 'Composed of muscles and tendons that enable foot movement and balance.',
                    image: Image.asset(
                      'assets/images/muscle_region/lower_body.png',
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
                    value: 'Gluteals',
                    groupValue: specificMuscle,
                    title: 'Gluteals',
                    description: 'Buttock muscles that extend and rotate the hip, crucial for walking, climbing, and posture.',
                    image: Image.asset(
                      'assets/images/muscle_region/lower_body.png',
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