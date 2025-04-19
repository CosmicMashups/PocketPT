// Import necessary packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';

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
  int painScale = UserAssess.painScale;
  late CameraController _controller;  // Camera controller
  late List<CameraDescription> cameras;  // List of available cameras
  bool _isCameraInitialized = false;  // Flag to check if camera is initialized

  Future<XFile?> _startRecording() async {
    if (!_controller.value.isInitialized || _controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await _controller.startVideoRecording();

      // Wait 10 seconds before stopping recording
      await Future.delayed(const Duration(seconds: 10));

      // Stop and return the recorded file
      XFile videoFile = await _controller.stopVideoRecording();
      return videoFile;
    } catch (e) {
      print('Error recording video: $e');
      return null;
    }
  }

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
    final screenHeight = MediaQuery.of(context).size.height -
        AppBar().preferredSize.height -
        MediaQuery.of(context).padding.top;

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
      body: Column(
        children: [
          LinearProgressIndicator(
            value: 0.6,
            minHeight: 8,
            color: const Color(0xFF800020),
            backgroundColor: const Color(0xFF404040),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isCameraInitialized
                    ? SizedBox(
                        height: screenHeight * 0.75,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: CameraPreview(_controller),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),

                const SizedBox(height: 30),

                // Buttons Row (Upload & Check)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AssessPainUpload()),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                        backgroundColor: const Color(0xFF800020),
                      ),
                      child: const Icon(Icons.upload, size: 30, color: Colors.white),
                    ),

                    // Record Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          XFile? videoFile = await _startRecording();
                          if (videoFile != null) {
                            print('Video recorded to: ${videoFile.path}');
                            // Do something with the video file here if needed
                          } else {
                            print('Recording failed or was cancelled.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.red,
                        ),
                        child: const Icon(Icons.videocam, color: Colors.white, size: 32),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AssessPainLevel()),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                        backgroundColor: const Color(0xFF800020),
                      ),
                      child: const Icon(Icons.check, size: 30, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}