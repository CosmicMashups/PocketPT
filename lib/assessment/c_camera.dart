// Import necessary packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

import 'globals.dart';
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
  CameraController? _controller;  // Make controller nullable
  late List<CameraDescription> cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _hasCameraError = false;  // Add error state

  // Start recording video
  Future<XFile?> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isRecordingVideo) {
      return null;
    }

    try {
      await _controller!.startVideoRecording();
      // Wait for 10 seconds or until user presses stop
      await Future.delayed(const Duration(seconds: 10));

      // Stop and return the recorded file
      XFile videoFile = await _controller!.stopVideoRecording();
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
    try {
      // Check if running on emulator
      final isEmulator = await _isEmulator();
      if (isEmulator) {
        print('Running on emulator - camera may not be available');
        setState(() {
          _hasCameraError = true;
        });
        return;
      }

      // Request camera permission
      final status = await Permission.camera.request();
      if (status.isDenied) {
        print('Camera permission denied');
        setState(() {
          _hasCameraError = true;
        });
        return;
      }

      // Get available cameras
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('No cameras available on this device');
        setState(() {
          _hasCameraError = true;
        });
        return;
      }

      // Initialize camera controller
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );

      await _controller!.initialize();
      if (!mounted) return;
      
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _hasCameraError = true;
      });
    }
  }

  // Helper method to check if running on emulator
  Future<bool> _isEmulator() async {
    try {
      final result = await Process.run('adb', ['shell', 'getprop', 'ro.kernel.qemu']);
      return result.exitCode == 0 && result.stdout.toString().trim() == '1';
    } catch (e) {
      return false;
    }
  }

  // Dispose of the camera controller when not needed
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top;

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
          onPressed: () async {
            await _controller?.dispose(); // Safe dispose
            if (context.mounted) {
              Navigator.push(
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
            backgroundColor: const Color(0xFF404040),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasCameraError)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.no_photography, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Camera not available',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can still upload a video',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_isCameraInitialized)
                  SizedBox(
                    height: screenHeight * 0.75,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                const SizedBox(height: 30),

                // Buttons Row (Upload, Record, Check)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Upload Button
                    ElevatedButton(
                      onPressed: () async {
                        await _controller?.dispose(); // Safe dispose
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AssessPainUpload()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                        backgroundColor: const Color(0xFF800020),
                      ),
                      child: const Icon(Icons.upload, size: 30, color: Colors.white),
                    ),

                    const SizedBox(width: 30), // Space between buttons

                    // Record Button - Only show if camera is available
                    if (!_hasCameraError)
                      ElevatedButton(
                        onPressed: () async {
                          setState(() => _isRecording = true); // Start visual change

                          XFile? videoFile = await _startRecording();

                          setState(() => _isRecording = false); // Reset after recording

                          if (videoFile != null) {
                            print('Video recorded to: ${videoFile.path}');
                            File file = File(videoFile.path);

                            // Store as File for future use
                            UserAssess.painVideo = file;

                            // Dispose camera before navigating to preview
                            await _controller?.dispose();

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssessPainVideoPreview(videoPath: file.path),
                                ),
                              );
                            }
                          } else {
                            print('Recording failed or was cancelled.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: _isRecording ? Colors.grey : Colors.red,
                        ),
                        child: _isRecording
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.videocam, color: Colors.white, size: 32),
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
