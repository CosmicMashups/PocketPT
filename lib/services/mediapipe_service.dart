import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';

class MediaPipeService {
  late PoseDetector _poseDetector;
  bool _isInitialized = false;
  VideoPlayerController? _videoController;

  Future<void> initialize() async {
    if (!_isInitialized) {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.accurate,
      );
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
        quality: 100,
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

    // Initialize video controller to get duration
    _videoController = VideoPlayerController.file(videoFile);
    await _videoController!.initialize();
    final duration = _videoController!.value.duration;
    await _videoController!.dispose();

    List<List<Pose>> allPoses = [];
    final frameInterval = 1000 ~/ 30; // 30 fps
    int currentTime = 0;

    while (currentTime <= duration.inMilliseconds) {
      final poses = await processFrame(videoPath, currentTime);
      if (poses.isNotEmpty) {
        allPoses.add(poses);
      }
      currentTime += frameInterval;
    }

    return allPoses;
  }

  Future<String> saveProcessedVideo(String videoPath, List<List<Pose>> poses) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = path.basename(videoPath);
    final outputPath = path.join(directory.path, 'processed_$fileName');
    
    // TODO: Implement video processing with landmarks overlay
    // This would require a more complex implementation using FFmpeg or similar
    // For now, we'll just return the original video path
    return videoPath;
  }

  void dispose() {
    if (_isInitialized) {
      _poseDetector.close();
      _isInitialized = false;
    }
    _videoController?.dispose();
  }
} 