// Import necessary packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:io';

import '../data/globals.dart';
import 'c_video.dart';
import 'c_upload.dart';
import 'c_videopreview.dart';

class AssessPainCamera extends StatefulWidget {
  const AssessPainCamera({super.key});

  @override
  State<AssessPainCamera> createState() => _AssessPainCameraState();
}

class _AssessPainCameraState extends State<AssessPainCamera> {
  int painScale = UserAssess.painScale;
  late CameraController _controller;
  late List<CameraDescription> cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;

  // Start recording video
  Future<XFile?> _startRecording() async {
    if (!_controller.value.isInitialized || _controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await _controller.startVideoRecording();
      // Wait for 10 seconds or until user presses stop
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
    final screenHeight = MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Pain: Level",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            Text(
              "Camera",
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
          onPressed: () async {
            await _controller.dispose();
            if (context.mounted) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => AssessPainVideo(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                ),
              );
            }
          },
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: 0.6,
            minHeight: 8,
            color: const Color(0xFF800020),
            backgroundColor: const Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 10),

          // Camera preview container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: _isCameraInitialized
                  ? Column(
                      children: [
                        Text(
                          "Align your face in the frame below",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF800020), width: 3),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: _controller.value.aspectRatio,
                                child: CameraPreview(_controller),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),

          const SizedBox(height: 20),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Upload
                Tooltip(
                  message: "Upload a pre-recorded video",
                  child: ElevatedButton(
                    onPressed: () async {
                      await _controller.dispose();
                      if (context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AssessPainUpload()));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF800020),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      elevation: 4,
                    ),
                    child: const Icon(Icons.upload_file, size: 28, color: Colors.white),
                  ),
                ),

                // Record
                Tooltip(
                  message: "Record 10-second facial reaction",
                  child: ElevatedButton(
                    onPressed: _isRecording
                        ? null
                        : () async {
                            setState(() => _isRecording = true);
                            XFile? videoFile = await _startRecording();
                            setState(() => _isRecording = false);

                            if (videoFile != null) {
                              File file = File(videoFile.path);
                              UserAssess.painVideo = file;
                              await _controller.dispose();

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AssessPainVideoPreview(videoPath: file.path)),
                                );
                              }
                            } else {
                              print('Recording failed or was cancelled.');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.grey : Colors.red,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      elevation: 4,
                    ),
                    child: _isRecording
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : const Icon(Icons.videocam_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
