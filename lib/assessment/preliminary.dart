import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'a_goal1.dart';

class AssessPrelim extends StatelessWidget {
  const AssessPrelim({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with 50% opacity
          Opacity(
            opacity: 0.25,  // Set opacity to 50%
            child: Image.asset(
              'assets/images/welcome_2.jpg',  // Path to the background image
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          
          // Centered content using a Column inside a Stack
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Row 1: Text - "Before we proceed..."
                Text(
                  "Before we proceed...",
                  style: TextStyle(
                    fontFamily: 'Poppins', // Ensure Poppins font is added to pubspec.yaml
                    fontWeight: FontWeight.w800, // Poppins ExtraBold
                    fontSize: 30,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                
                // Row 2: Text - "We need to ask you a few questions first:"
                Text(
                  "We need to ask you a few questions first:",
                  style: TextStyle(
                    fontFamily: 'PT Sans', // Ensure PT Sans font is added to pubspec.yaml
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                
                // Row 3: Row with Image and Text for "Rehabilitation Goal"
                _buildRow('assets/images/check.png', "Rehabilitation Goal"),
                SizedBox(height: 20),
                
                // Row 4: Row with Image and Text for "Focus Area"
                _buildRow('assets/images/check.png', "Focus Area"),
                SizedBox(height: 20),
                
                // Row 5: Row with Image and Text for "Pain Description"
                _buildRow('assets/images/check.png', "Pain Description"),
                SizedBox(height: 20),
                
                // Row 6: Row with Image and Text for "Injury History"
                _buildRow('assets/images/check.png', "Injury History"),
                SizedBox(height: 30),
                
                // Row 7: ElevatedButton with "Proceed"
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
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
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800020),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  ),
                  child: Text("Proceed",
                      style: GoogleFonts.ptSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build rows with an image and text side-by-side
  Widget _buildRow(String imagePath, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Centers the image and text horizontally
      children: [
        Image.asset(imagePath, width: 30, height: 30),
        SizedBox(width: 10), // Add space between image and text
        Text(
          label,
          style: TextStyle(
            fontFamily: 'PT Sans',
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}