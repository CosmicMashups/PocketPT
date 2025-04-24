import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PoseProcessor {
  late PoseDetector _poseDetector;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      final options = PoseDetectorOptions();
      _poseDetector = PoseDetector(options: options);
      _isInitialized = true;
    }
  }

  Future<List<Pose>> processFrame(String videoPath, int timeMs) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final frameData = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 1280,
        maxHeight: 720,
        timeMs: timeMs,
      );

      if (frameData != null) {
        final inputImage = InputImage.fromBytes(
          bytes: frameData,
          metadata: InputImageMetadata(
            size: const ui.Size(1280, 720),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: 1280 * 4,
          ),
        );

        return await _poseDetector.processImage(inputImage);
      }
    } catch (e) {
      print('Error processing frame: $e');
    }
    return [];
  }

  Future<List<List<Pose>>> processVideo(String videoPath) async {
    if (!_isInitialized) {
      await initialize();
    }

    final videoFile = File(videoPath);
    if (!await videoFile.exists()) {
      throw Exception('Video file not found');
    }

    List<List<Pose>> allPoses = [];
    final frameInterval = 1000 ~/ 30; // 30 fps
    int currentTime = 0;

    while (true) {
      final poses = await processFrame(videoPath, currentTime);
      if (poses.isEmpty) break;
      
      allPoses.add(poses);
      currentTime += frameInterval;
    }

    return allPoses;
  }

  void dispose() {
    if (_isInitialized) {
      _poseDetector.close();
      _isInitialized = false;
    }
  }
} 