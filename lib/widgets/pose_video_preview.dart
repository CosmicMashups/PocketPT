import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../services/mediapipe_service.dart';

class PoseVideoPreview extends StatefulWidget {
  final String videoPath;
  final bool showPoseOverlay;

  const PoseVideoPreview({
    Key? key,
    required this.videoPath,
    this.showPoseOverlay = true,
  }) : super(key: key);

  @override
  State<PoseVideoPreview> createState() => _PoseVideoPreviewState();
}

class _PoseVideoPreviewState extends State<PoseVideoPreview> {
  late VideoPlayerController _controller;
  final MediaPipeService _mediaPipeService = MediaPipeService();
  List<List<Pose>> _allPoses = [];
  int _currentFrameIndex = 0;
  bool _isProcessing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _processVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    await _controller.initialize();
    _controller.addListener(_updateCurrentFrame);
    setState(() {
      _isInitialized = true;
    });
    _controller.play();
  }

  void _updateCurrentFrame() {
    if (!_controller.value.isInitialized || _allPoses.isEmpty) return;
    
    final currentTime = _controller.value.position.inMilliseconds;
    final frameInterval = 1000 ~/ 30; // 30 fps
    final newFrameIndex = (currentTime / frameInterval).floor();
    
    if (newFrameIndex != _currentFrameIndex && newFrameIndex < _allPoses.length) {
      setState(() {
        _currentFrameIndex = newFrameIndex;
      });
    }
  }

  Future<void> _processVideo() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      await _mediaPipeService.initialize();
      _allPoses = await _mediaPipeService.processVideo(widget.videoPath);
    } catch (e) {
      print('Error processing video: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        if (widget.showPoseOverlay && _allPoses.isNotEmpty && _currentFrameIndex < _allPoses.length)
          CustomPaint(
            painter: PosePainter(_allPoses[_currentFrameIndex], _controller.value.size),
            size: Size(_controller.value.size.width, _controller.value.size.height),
          ),
        if (_isProcessing)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCurrentFrame);
    _controller.dispose();
    _mediaPipeService.dispose();
    super.dispose();
  }
}

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size size;
  final Paint _paint = Paint()
    ..color = Colors.red
    ..strokeWidth = 4.0
    ..style = PaintingStyle.stroke;

  PosePainter(this.poses, this.size);

  @override
  void paint(Canvas canvas, Size size) {
    for (final pose in poses) {
      // Draw pose landmarks
      for (final landmark in pose.landmarks.values) {
        canvas.drawCircle(
          Offset(landmark.x * size.width, landmark.y * size.height),
          4.0,
          _paint,
        );
      }

      // Draw connections between landmarks
      _drawConnections(canvas, pose);
    }
  }

  void _drawConnections(Canvas canvas, Pose pose) {
    // Define connections between landmarks
    final connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    for (final connection in connections) {
      final start = pose.landmarks[connection[0]];
      final end = pose.landmarks[connection[1]];
      if (start != null && end != null) {
        canvas.drawLine(
          Offset(start.x * size.width, start.y * size.height),
          Offset(end.x * size.width, end.y * size.height),
          _paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    return oldDelegate.poses != poses;
  }
} 