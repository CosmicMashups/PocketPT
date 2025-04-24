import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

class VideoProcessor {
  late PoseDetector _poseDetector;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      final options = PoseDetectorOptions();
      _poseDetector = PoseDetector(options: options);
      _isInitialized = true;
    }
  }

  Future<List<Map<String, dynamic>>> processVideo(String videoPath) async {
    try {
      final detector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.single,
          model: PoseDetectionModel.accurate,
        ),
      );

      final List<Map<String, dynamic>> poseData = [];
      final frameInterval = 1000 ~/ 30; // 30 fps
      int currentTime = 0;

      while (true) {
        final frameData = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 1280,
          maxHeight: 720,
          timeMs: currentTime,
        );

        if (frameData == null) break;

        final inputImage = InputImage.fromBytes(
          bytes: frameData,
          metadata: InputImageMetadata(
            size: const ui.Size(1280, 720),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: 1280 * 4,
          ),
        );

        final poses = await detector.processImage(inputImage);
        if (poses.isNotEmpty) {
          final pose = poses.first;
          final landmarks = pose.landmarks;
          final Map<String, dynamic> frameData = {
            'timestamp': currentTime,
            'landmarks': landmarks.entries.map((entry) {
              final landmark = entry.value;
              return {
                'type': entry.key.toString(),
                'x': landmark.x,
                'y': landmark.y,
                'z': landmark.z,
                'likelihood': landmark.likelihood,
              };
            }).toList(),
          };
          poseData.add(frameData);
        }

        currentTime += frameInterval;
      }

      await detector.close();
      return poseData;
    } catch (e) {
      debugPrint('Error processing video: $e');
      rethrow;
    }
  }

  void dispose() {
    if (_isInitialized) {
      _poseDetector.close();
      _isInitialized = false;
    }
  }
} 