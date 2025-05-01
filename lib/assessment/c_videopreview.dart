import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/functions.dart';
import 'c_camera.dart';
import 'c_painlevel.dart';

class AssessPainVideoPreview extends StatelessWidget {
  final String videoPath;

  const AssessPainVideoPreview({super.key, required this.videoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Pain: Level (Camera)",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            Text(
              "Video Review",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 10,
                  color: const Color(0xFF800020),
                  backgroundColor: const Color(0xFFE0E0E0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step 3 of 5",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF800020),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Preview your recorded video:",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LocalVideoPlayer(videoPath: videoPath),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      "Are you satisfied with the video?",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AssessPainCamera()),
                          );
                        },
                        icon: const Icon(Icons.replay, color: Color(0xFF800020)),
                        label: Text(
                          "Retake",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF800020),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 3,
                          side: const BorderSide(color: Color(0xFF800020), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => AssessPainLevel(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                final offsetAnimation = animation.drive(tween);

                                return SlideTransition(position: offsetAnimation, child: child);
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          "Use Video",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF800020),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}