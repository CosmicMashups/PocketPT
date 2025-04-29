import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';

class AssessPainVideo2 extends StatefulWidget {
  final String videoPath;
  final String poseData; // JSON of landmarks

  const AssessPainVideo2({
    required this.videoPath,
    required this.poseData,
    super.key,
  });

  @override
  State<AssessPainVideo2> createState() => _AssessPainVideo2State();
}

class _AssessPainVideo2State extends State<AssessPainVideo2> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  List<dynamic> frames = [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _parsePoseData();
  }

  Future<void> _initializeVideo() async {
    if (kIsWeb) {
      _controller = VideoPlayerController.network(widget.videoPath);
    } else {
      _controller = VideoPlayerController.file(File(widget.videoPath));
    }
    await _controller.initialize();
    _duration = _controller.value.duration;
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _position = _controller.value.position;
          _isPlaying = _controller.value.isPlaying;
        });
      }
    });
    setState(() {});
  }

  void _parsePoseData() {
    try {
      final decoded = jsonDecode(widget.poseData);
      frames = decoded['frames'] ?? [];
    } catch (e) {
      print('Error parsing pose data: $e');
      frames = [];
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F6F4),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF800020),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        title: Text(
          "Movement Analysis",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: 1.0, // Analysis complete
            minHeight: 8,
            color: const Color(0xFF800020),
            backgroundColor: const Color(0xFF404040),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              VideoPlayer(_controller),
                              if (frames.isNotEmpty)
                                CustomPaint(
                                  painter: PosePainter(
                                    frames: frames,
                                    currentTime: _position.inMilliseconds,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Video controls
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Progress bar
                        Slider(
                          value: _position.inMilliseconds.toDouble(),
                          min: 0,
                          max: _duration.inMilliseconds.toDouble(),
                          activeColor: const Color(0xFF800020),
                          inactiveColor: Colors.grey[300],
                          onChanged: (value) {
                            final newPosition = Duration(milliseconds: value.toInt());
                            _controller.seekTo(newPosition);
                            setState(() => _position = newPosition);
                          },
                        ),
                        // Play/Pause button
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 48,
                            color: const Color(0xFF800020),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPlaying = !_isPlaying;
                              _isPlaying ? _controller.play() : _controller.pause();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<dynamic> frames;
  final int currentTime;

  PosePainter({
    required this.frames,
    required this.currentTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connections first (underneath points)
    final connectionPaint = Paint()
      ..color = Colors.red.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw landmark points
    final pointPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 8
      ..style = PaintingStyle.fill;

    if (frames.isNotEmpty) {
      var frame = frames[0]; // For now, just show first frame
      final landmarks = frame['landmarks'] as List;

      // Draw connections between landmarks (customize these based on your needs)
      final connections = [
        [0, 1], // Example: Connect point 0 to point 1
        [1, 2], // Example: Connect point 1 to point 2
        // Add more connections as needed
      ];

      for (var connection in connections) {
        if (connection[0] < landmarks.length && connection[1] < landmarks.length) {
          final start = landmarks[connection[0]];
          final end = landmarks[connection[1]];
          
          canvas.drawLine(
            Offset(start['x'] * size.width, start['y'] * size.height),
            Offset(end['x'] * size.width, end['y'] * size.height),
            connectionPaint,
          );
        }
      }

      // Draw landmark points
      for (var landmark in landmarks) {
        final x = landmark['x'] * size.width;
        final y = landmark['y'] * size.height;
        canvas.drawCircle(Offset(x, y), 4, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.currentTime != currentTime;
  }
} 