// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import 'c_camera.dart';
import 'c_paintype.dart';

class AssessPainLevel extends StatefulWidget {
  const AssessPainLevel({super.key});

  @override
  State<AssessPainLevel> createState() => _AssessPainLevelState();
}

class _AssessPainLevelState extends State<AssessPainLevel> {
  String painLevel = UserAssess.painLevel;
  int painScale = UserAssess.painScale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Pain: Level",
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
                    "On a scale of 1 to 10, does this accurately reflect your current pain level? If not, please adjust it using the slider.",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Custom Slider
                  StatefulBuilder(
                    builder: (context, setState) {
                      double sliderValue = UserAssess.painScale.toDouble(); // Use your class value here

                      String getPainDescription(double value) {
                        if (value <= 3) return "Low";
                        if (value <= 7) return "Moderate";
                        return "Severe";
                      }

                      return Column(
                        children: [
                          SizedBox(
                            height: 250,
                            child: RotatedBox(
                              quarterTurns: -1,
                              child: Slider(
                                min: 0,
                                max: 10,
                                divisions: 10,
                                value: sliderValue,
                                label: sliderValue.toInt().toString(),
                                activeColor: const Color(0xFF800020),
                                inactiveColor: Colors.grey[300],
                                onChanged: (value) {
                                  setState(() {
                                    sliderValue = value;
                                    UserAssess.painScale = value.toInt();
                                    UserAssess.painLevel = getPainDescription(value);
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                sliderValue.toInt().toString(),
                                style: GoogleFonts.ptSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF800020),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                getPainDescription(sliderValue),
                                style: GoogleFonts.ptSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
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
                            pageBuilder: (context, animation, secondaryAnimation) => AssessPainType(),
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
                            "Confirm",
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