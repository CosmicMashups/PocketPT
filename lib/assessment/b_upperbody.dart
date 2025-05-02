// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import 'b_focus1.dart';
import 'c_video.dart';
import '../data/functions.dart';

class AssessUpperBody extends StatefulWidget {
  const AssessUpperBody({super.key});

  @override
  State<AssessUpperBody> createState() => _AssessUpperBodyState();
}

class _AssessUpperBodyState extends State<AssessUpperBody> {
  String specificMuscle = UserAssess.specificMuscle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Focus Area: Upper Body",
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
                    value: 'Deltoids',
                    groupValue: specificMuscle,
                    title: 'Deltoids',
                    description: 'Shoulder muscles responsible for lifting the arm and giving the shoulder its range of motion.',
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
                    value: 'Rotator Cuff Muscles',
                    groupValue: specificMuscle,
                    title: 'Rotator Cuff Muscles',
                    description: 'A group of muscles and tendons that stabilize the shoulder joint and enable arm rotation.',
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
                    value: 'Biceps',
                    groupValue: specificMuscle,
                    title: 'Biceps',
                    description: 'Front upper arm muscles involved in elbow flexion and forearm supination.',
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
                    value: 'Triceps',
                    groupValue: specificMuscle,
                    title: 'Triceps',
                    description: 'Back upper arm muscles responsible for extending the elbow.',
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
                    value: 'Forearm Muscles',
                    groupValue: specificMuscle,
                    title: 'Forearm Muscles',
                    description: 'Muscles controlling wrist, hand, and finger movements.',
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
                    value: 'Hand Muscles',
                    groupValue: specificMuscle,
                    title: 'Hand Muscles',
                    description: 'Small muscles that manage fine motor skills and grip strength in the hand.',
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
                    value: 'Wrist Flexors/Extensors',
                    groupValue: specificMuscle,
                    title: 'Wrist Flexors/Extensors',
                    description: 'Muscles that bend (flex) or straighten (extend) the wrist.',
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
                    value: 'Chest',
                    groupValue: specificMuscle,
                    title: 'Pectorals',
                    description: 'Large muscles across the chest that aid in arm movement and shoulder stability.',
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