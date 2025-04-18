// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'globals.dart';
import 'preliminary.dart';
import 'b_focus1.dart';
import '../functions.dart';

class AssessGoal1 extends StatefulWidget {
  const AssessGoal1({super.key});

  @override
  State<AssessGoal1> createState() => _AssessGoal1State();
}

class _AssessGoal1State extends State<AssessGoal1> {
  String rehabGoal = UserAssess.rehabGoal; // <-- Load global value if already set

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Functional Goal",
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
              pageBuilder: (context, animation, secondaryAnimation) => AssessPrelim(),
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
              value: 0.2,
              minHeight: 8,
              color: const Color(0xFF800020),
              backgroundColor: const Color(0xFF404040),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Question 1 of 5"
                  Text(
                    "Question 1 of 5",
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF800020),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Question Text
                  Text(
                    "What specific goal would you like to prioritize?",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Custom Radio Tiles
                  CustomRadioTile<String>(
                    value: 'Alleviate Pain',
                    groupValue: rehabGoal,
                    title: 'Alleviate Pain',
                    description: 'Reduce discomfort through therapy or treatment.',
                    onChanged: (val) {
                      setState(() {
                        rehabGoal = val!;
                        UserAssess.rehabGoal = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Improve Mobility',
                    groupValue: rehabGoal,
                    title: 'Improve Mobility',
                    description: 'Enhance your ability to move with ease.',
                    onChanged: (val) {
                      setState(() {
                        rehabGoal = val!;
                        UserAssess.rehabGoal = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Regain Strength',
                    groupValue: rehabGoal,
                    title: 'Strengthening',
                    description: 'Focus on rebuilding physical strength.',
                    onChanged: (val) {
                      setState(() {
                        rehabGoal = val!;
                        UserAssess.rehabGoal = val;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // Text(
                  //   'Selected Choice: $rehabGoal',
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
                            pageBuilder: (context, animation, secondaryAnimation) => AssessFocus1(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              // SlideTransition with custom offset (slide left)
                              const begin = Offset(1.0, 0.0); // Starting from the right
                              const end = Offset.zero; // Ending at the normal position
                              const curve = Curves.easeInOut;

                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);

                              return SlideTransition(position: offsetAnimation, child: child);
                            },
                          ),
                          ).then((result) {
                            if (result != null) {
                              setState(() {
                                rehabGoal = result as String;
                              });
                            }
                          }
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