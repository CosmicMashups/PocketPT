// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'globals.dart';
import 'c_painlevel.dart';
import '../functions.dart';

import 'd_history.dart';

class AssessPainDuration extends StatefulWidget {
  const AssessPainDuration({super.key});

  @override
  State<AssessPainDuration> createState() => _AssessPainDurationState();
}

class _AssessPainDurationState extends State<AssessPainDuration> {
  String painDuration = UserAssess.painDuration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Pain: Duration",
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
              pageBuilder: (context, animation, secondaryAnimation) => AssessPainLevel(),
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
                    "How long have you been experiencing this issue?",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Custom Radio Tiles
                  CustomRadioTile<String>(
                    value: 'Less than 48 hours ago',
                    groupValue: painDuration,
                    title: 'Less than 48 hours ago',
                    description: 'Within the past two days',
                    onChanged: (val) {
                      setState(() {
                        painDuration = val!;
                        UserAssess.painDuration = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Within the past 3 weeks',
                    groupValue: painDuration,
                    title: 'Within the past 3 weeks',
                    description: 'One to three weeks ago',
                    onChanged: (val) {
                      setState(() {
                        painDuration = val!;
                        UserAssess.painDuration = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Within the past 6 weeks',
                    groupValue: painDuration,
                    title: 'Within the past 6 weeks',
                    description: 'Four to six weeks ago',
                    onChanged: (val) {
                      setState(() {
                        painDuration = val!;
                        UserAssess.painDuration = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'More than 2 months ago',
                    groupValue: painDuration,
                    title: 'More than 2 months ago',
                    description: 'Two months onwards',
                    onChanged: (val) {
                      setState(() {
                        painDuration = val!;
                        UserAssess.painDuration = val;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // Text(
                  //   'Selected Choice: $painDuration',
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
                            pageBuilder: (context, animation, secondaryAnimation) => AssessHistory(),
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