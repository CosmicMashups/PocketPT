// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'globals.dart';
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
    // Simulate file upload and return success (replace with actual file upload logic)
    await Future.delayed(Duration(seconds: 2));  // Simulate a delay
    return true;  // Return true if upload is successful, false if not
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Title Text
                    Center(
                      child: Text(
                        'Upload Media',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800, // ExtraBold
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                
                    // Row 2: Dashed Container with Button & Info
                    DottedBorder(
                      color: const Color(0xFF800020),
                      dashPattern: [8, 4],
                      strokeWidth: 2,
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(8),
                      child: Container(
                        width: 500,
                        height: 300,
                        color: const Color(0xFFD79691),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                
                            // a. Elevated Button
                            ElevatedButton.icon(
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker.platform.pickFiles(
                                  type: FileType.video,
                                );

                                if (result != null && result.files.single.path != null) {
                                  setState(() {
                                    _selectedVideoFile = File(result.files.single.path!);
                                  });

                                  print('Selected video path: ${_selectedVideoFile!.path}');
                                } else {
                                  print('No video selected.');
                                }
                              },
                              icon: const Icon(
                                Icons.video_library,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Choose Video',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                                backgroundColor: const Color(0xFF800020),
                              ),
                            ),
                            const SizedBox(height: 20),
                
                            // b. Instruction Text
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                'Drag and drop your videos here\n(.mp4, .mkv, .webm videos allowed)',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.ptSans(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                
                    // Row 3: Upload note
                    Center(
                      child: Text(
                        'Upload your video for self-assessment (up to 200 MB).',
                        style: GoogleFonts.ptSans(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                
                    // Row 4: Upload Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Simulate file upload process (Replace with actual file upload logic)
                          bool isUploadSuccessful = await uploadVideoFile();  // Replace with your actual file upload function

                          // If upload is successful, navigate to AssessPainVideoPreview
                          if (isUploadSuccessful) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => AssessPainVideoPreview(videoPath: 'path/to/video'),  // Replace with actual video path
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
                          } else {
                            // If upload fails, you can display an error message or handle it accordingly
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Upload Failed"),
                                content: Text("The video upload was not successful. Please try again."),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                          backgroundColor: const Color(0xFF800020),
                        ),
                        child: Text(
                          'Upload Video',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}