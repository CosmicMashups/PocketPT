// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import 'c_painlevel.dart';
import '../functions.dart';

import 'c_painduration.dart';

class AssessPainType extends StatefulWidget {
  const AssessPainType({super.key});

  @override
  State<AssessPainType> createState() => _AssessPainTypeState();
}

class _AssessPainTypeState extends State<AssessPainType> {
  String painType = UserAssess.painType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Pain: Type",
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
                    "How would you characterize the pain you're currently dealing with?",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Custom Radio Tiles
                  CustomRadioTile<String>(
                    value: 'Nerve Pain',
                    groupValue: painType,
                    title: 'Nerve Pain',
                    description: 'tingling, burning, or like an electric shock shooting through your body.',
                    onChanged: (val) {
                      setState(() {
                        painType = val!;
                        UserAssess.painType = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Muscle Pain',
                    groupValue: painType,
                    title: 'Muscle Pain',
                    description: 'It feels like sore muscles, especially when you move or touch the area.',
                    onChanged: (val) {
                      setState(() {
                        painType = val!;
                        UserAssess.painType = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Bone Pain',
                    groupValue: painType,
                    title: 'Bone Pain',
                    description: "It feels like it's coming from deep inside the bone, not the muscle.",
                    onChanged: (val) {
                      setState(() {
                        painType = val!;
                        UserAssess.painType = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Joint Pain',
                    groupValue: painType,
                    title: 'Joint Pain',
                    description: 'It comes from a joint like your knee, shoulder, or fingers.',
                    onChanged: (val) {
                      setState(() {
                        painType = val!;
                        UserAssess.painType = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Inflammatory Pain',
                    groupValue: painType,
                    title: 'Inflammatory Pain',
                    description: 'The area is red, warm, or swollen.',
                    onChanged: (val) {
                      setState(() {
                        painType = val!;
                        UserAssess.painType = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Referred Pain',
                    groupValue: painType,
                    title: 'Referred Pain',
                    description: 'I feel pain somewhere even though that part doesn’t seem injured.',
                    onChanged: (val) {
                      setState(() {
                        painType = val!;
                        UserAssess.painType = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Cramping Pain',
                    groupValue: painType,
                    title: 'Cramping Pain',
                    description: 'My muscles or stomach are tightening or cramping up suddenly.',
                    onChanged: (val) {
                      setState(() {
                        painType = val!;
                        UserAssess.painType = val;
                      });
                    },
                  ),
                  
                  CustomRadioTile<String>(
                    value: 'Visceral Pain',
                    groupValue: painType,
                    title: 'Visceral Pain',
                    description: 'The pain is deep inside the body and hard to describe exactly where it is.',
                    onChanged: (val) {
                      setState(() {
                        painType = val!;
                        UserAssess.painType = val;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // Text(
                  //   'Selected Choice: $painType',
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