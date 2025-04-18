// Import necessary packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';  // Add the camera package import

import 'globals.dart';
import 'c_video.dart';
import 'c_upload.dart';
import 'c_painlevel.dart';

class AssessPainCamera extends StatefulWidget {
  const AssessPainCamera({super.key});

  @override
  State<AssessPainCamera> createState() => _AssessPainCameraState();
}

class _AssessPainCameraState extends State<AssessPainCamera> {
  String painType = UserAssess.painType;
  late CameraController _controller;  // Camera controller
  late List<CameraDescription> cameras;  // List of available cameras
  bool _isCameraInitialized = false;  // Flag to check if camera is initialized

  // Initialize the camera
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Initialize the camera and set the controller
  Future<void> _initializeCamera() async {
    cameras = await availableCameras();  // Get available cameras
    _controller = CameraController(
      cameras.first,  // Use the first available camera
      ResolutionPreset.high,  // Set the camera resolution
    );

    await _controller.initialize();  // Initialize the camera
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;  // Camera is initialized
    });
  }

  // Dispose of the camera controller when not needed
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Pain: Level (Camera)",
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
              pageBuilder: (context, animation, secondaryAnimation) => AssessPainVideo(),
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

                  // Camera Section
                  _isCameraInitialized
                      ? SizedBox(
                          height: 250,
                          width: double.infinity,
                          child: Center(child: CameraPreview(_controller)),  // Display the camera preview
                        )
                      : const CircularProgressIndicator(),  // Show loading indicator until the camera is initialized

                  const SizedBox(height: 30),

                  // Buttons
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,  // Center the buttons
                      children: [
                        // Upload Button (Circle)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => AssessPainUpload(),
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
                          },
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(20), // Adjust the size of the circle
                            backgroundColor: const Color(0xFF800020),
                          ),
                          child: Icon(
                            Icons.upload,  // Upload icon
                            size: 30,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 30),  // Space between buttons

                        // Check Button (Circle)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => AssessPainLevel(),
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
                          },
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(20), // Adjust the size of the circle
                            backgroundColor: const Color(0xFF800020),
                          ),
                          child: Icon(
                            Icons.check,  // Check icon
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ],
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