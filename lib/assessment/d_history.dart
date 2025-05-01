// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import 'c_painduration.dart';
import 'e_summary.dart';
import '../data/functions.dart';

class AssessHistory extends StatefulWidget {
  const AssessHistory({super.key});

  @override
  State<AssessHistory> createState() => _AssessHistoryState();
}

class _AssessHistoryState extends State<AssessHistory> {
  bool isInjured = UserAssess.isInjured;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Injury History",
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
              pageBuilder: (context, animation, secondaryAnimation) => AssessPainDuration(),
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
              value: 0.8,
              minHeight: 8,
              color: const Color(0xFF800020),
              backgroundColor: const Color(0xFF404040),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Question 4 of 5"
                  Text(
                    "Question 4 of 5",
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF800020),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Question Text
                  Text(
                    "Have you had any previous injuries or conditions that may currently affect your mobility?",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Custom Radio Tiles
                  CustomRadioTile<bool>(
                    value: true,
                    groupValue: isInjured,
                    title: 'Yes',
                    description: '',
                    onChanged: (val) {
                      setState(() {
                        isInjured = val!;
                        UserAssess.isInjured = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<bool>(
                    value: false,
                    groupValue: isInjured,
                    title: 'No',
                    description: '',
                    onChanged: (val) {
                      setState(() {
                        isInjured = val!;
                        UserAssess.isInjured = val;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // Text(
                  //   'Selected Choice: $isInjured',
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
                            pageBuilder: (context, animation, secondaryAnimation) => AssessSummary(),
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