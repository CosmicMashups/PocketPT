import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pose_bridge.dart';
import 'c_video2.dart';
import 'package:flutter/foundation.dart';

class AssessPainAnalyzing extends StatefulWidget {
  final String videoPath;

  const AssessPainAnalyzing({
    required this.videoPath,
    super.key,
  });

  @override
  State<AssessPainAnalyzing> createState() => _AssessPainAnalyzingState();
}

class _AssessPainAnalyzingState extends State<AssessPainAnalyzing> {
  String _status = "Initializing...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _analyzeVideo();
  }

  Future<String> _webPoseEstimation(String videoPath) async {
    // TODO: Replace this with real pose estimation for web (e.g. TensorFlow.js via JS interop)
    // For now, return dummy pose data so you can see the overlay
    await Future.delayed(const Duration(seconds: 1));
    return '''
    {
      "frames": [
        {
          "frame": 1,
          "landmarks": [
            {"x": 0.45, "y": 0.32, "name": "LEFT_SHOULDER"},
            {"x": 0.55, "y": 0.35, "name": "RIGHT_SHOULDER"},
            {"x": 0.50, "y": 0.60, "name": "MID_HIP"}
          ]
        }
      ]
    }
    ''';
  }

  Future<void> _analyzeVideo() async {
    try {
      setState(() => _status = "Processing video...");
      print("Analyzing video at path: ${widget.videoPath}");
      String poseData = '{}';
      if (!kIsWeb) {
        poseData = await PoseBridge.runPoseEstimation(widget.videoPath);
      } else {
        poseData = await _webPoseEstimation(widget.videoPath);
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AssessPainVideo2(
            videoPath: widget.videoPath,
            poseData: poseData,
          ),
        ),
      );
    } catch (e) {
      print("Pose analysis error: $e");
      if (!mounted) return;
      setState(() {
        _status = "Error analyzing video";
        _hasError = true;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "Analysis Error",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            "There was an error analyzing your video. Please try again.\n$e",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to video preview
              },
              child: Text(
                "OK",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF800020),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Analyzing Movement",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: null, // Indeterminate progress
            minHeight: 8,
            color: const Color(0xFF800020),
            backgroundColor: const Color(0xFF404040),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_hasError) ...[
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: Color(0xFF800020),
                        strokeWidth: 6,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _status,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "We're processing your video to understand your movement patterns.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Color(0xFF800020),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _status,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF800020),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 