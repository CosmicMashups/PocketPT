import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  String getPainEmoji(int value) {
    if (value <= 3) return "🙂";
    if (value <= 7) return "😟";
    return "😖";
  }

  String getPainDescription(int value) {
    if (value <= 3) return "Low";
    if (value <= 7) return "Moderate";
    return "Severe";
  }

  @override
  Widget build(BuildContext context) {
    int sliderValue = UserAssess.painScale;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          "Pain Assessment",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 22,
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
                pageBuilder: (_, __, ___) => const AssessPainCamera(),
                transitionsBuilder: (_, anim, __, child) {
                  return SlideTransition(
                    position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: 0.6,
              minHeight: 6,
              color: const Color(0xFF800020),
              backgroundColor: const Color(0xFFE0E0E0),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question count
                      Text(
                        "Question 3 of 5",
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF800020),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Main question
                      Text(
                        "How intense is your current pain?",
                        style: GoogleFonts.ptSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Adjust the slider to describe your pain level.",
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Emoji + Description
                      Center(
                        child: Column(
                          children: [
                            Text(
                              getPainEmoji(sliderValue),
                              style: const TextStyle(fontSize: 60),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "$sliderValue - ${getPainDescription(sliderValue)}",
                              style: GoogleFonts.ptSans(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF800020),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Horizontal slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF800020),
                          inactiveTrackColor: Colors.grey[300],
                          thumbColor: const Color(0xFF800020),
                          overlayColor: const Color(0x30800020),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                        ),
                        child: Slider(
                          min: 0,
                          max: 10,
                          divisions: 10,
                          value: sliderValue.toDouble(),
                          label: sliderValue.toString(),
                          onChanged: (value) {
                            setState(() {
                              sliderValue = value.toInt();
                              UserAssess.painScale = sliderValue;
                              UserAssess.painLevel = getPainDescription(sliderValue);
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Confirm Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const AssessPainType(),
                                transitionsBuilder: (_, anim, __, child) {
                                  return SlideTransition(
                                    position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          label: Text(
                            "Confirm",
                            style: GoogleFonts.ptSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF8F6F4),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF800020),
                            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}