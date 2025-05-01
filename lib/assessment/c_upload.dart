// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../data/globals.dart';
import 'c_camera.dart';
import 'c_videopreview.dart';

class AssessPainUpload extends StatefulWidget {
  const AssessPainUpload({super.key});

  @override
  State<AssessPainUpload> createState() => _AssessPainUploadState();
}

class _AssessPainUploadState extends State<AssessPainUpload> {
  String painLevel = UserAssess.painLevel;
  int painScale = UserAssess.painScale;
  File? _selectedVideoFile = UserAssess.painVideo;

  Future<bool> uploadVideoFile() async {
    await Future.delayed(Duration(seconds: 2)); // Simulate upload delay
    return true; // Replace with actual upload logic
  }

  Widget buildVideoPreview() {
    if (_selectedVideoFile != null) {
      return Column(
        children: [
          const SizedBox(height: 10),
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(12),
          //   child: Container(
          //     color: Colors.black,
          //     width: 200,
          //     height: 140,
          //     child: const Center(
          //       child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 10),
          Text(
            "Selected: ${_selectedVideoFile!.path.split('/').last}",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Pain: Level (Upload)",
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
              pageBuilder: (context, animation, secondaryAnimation) => AssessPainCamera(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                var offsetAnimation = animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeInOut)),
                );
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LinearProgressIndicator(
              value: 0.6,
              minHeight: 8,
              color: const Color(0xFF800020),
              backgroundColor: const Color(0xFF404040),
            ),
            const SizedBox(height: 30),

            // Title with subtitle and icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, color: Color(0xFF800020), size: 28),
                const SizedBox(width: 10),
                Text(
                  'Upload Your Video',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Up to 200 MB, formats: .mp4, .mkv, .webm',
              style: GoogleFonts.ptSans(
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Dotted Upload Box
            DottedBorder(
              color: const Color(0xFF800020),
              dashPattern: [8, 4],
              strokeWidth: 2,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                color: const Color(0xFFD79691),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_call_rounded, size: 50, color: Colors.white),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
                        if (result != null && result.files.single.path != null) {
                          setState(() {
                            _selectedVideoFile = File(result.files.single.path!);
                          });
                        }
                      },
                      icon: const Icon(Icons.video_library, color: Colors.white),
                      label: Text('Choose Video',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Color(0xFFF8F6F4),
                          )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF800020),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Or drag and drop your video here',
                      style: GoogleFonts.ptSans(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    buildVideoPreview(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Upload Button
            ElevatedButton.icon(
              onPressed: () async {
                bool success = await uploadVideoFile();
                if (success) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => AssessPainVideoPreview(videoPath: _selectedVideoFile?.path ?? ''),
                      transitionsBuilder: (_, animation, __, child) {
                        return SlideTransition(
                          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeInOut))
                              .animate(animation),
                          child: child,
                        );
                      },
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 10),
                          Text("Upload Failed"),
                        ],
                      ),
                      content: Text("Your video could not be uploaded. Please check your connection or try again."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              },
              icon: const Icon(Icons.cloud_upload, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF800020),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              ),
              label: Text(
                'Upload Video',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFFF8F6F4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}