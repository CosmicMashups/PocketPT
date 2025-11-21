import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'pose_model_manager.dart';
import 'pose_diagnostics.dart';

/// Custom pose detection service using the trained YOLO11s-pose model
/// 
/// This service provides pose detection functionality using the custom
/// trained YOLO11s-pose model (pose_estimation_model.pt) instead of Google ML Kit.
/// 
/// Based on pose_test2.py implementation:
/// - Model input: 320x320 RGB images
/// - Model output: 17 COCO format keypoints [x, y, confidence]
/// - Keypoints are returned in pixel coordinates (scaled to original image size)
class CustomPoseDetectionService {
  static final CustomPoseDetectionService _instance = CustomPoseDetectionService._internal();
  factory CustomPoseDetectionService() => _instance;
  CustomPoseDetectionService._internal();
  
  final PoseModelManager _modelManager = PoseModelManager.instance;
  bool _isInitialized = false;
  
  /// Initialize the custom pose detection service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _modelManager.initialize();
      _isInitialized = true;
      debugPrint('✓ Custom YOLO11s-pose detection service initialized');
      PoseDiagnostics.instance.logModelInit(success: true);
    } catch (e) {
      debugPrint('✗ Failed to initialize custom pose detection service: $e');
      PoseDiagnostics.instance.logModelInit(
        success: false,
        message: e.toString(),
      );
      rethrow;
    }
  }
  
  /// Detect poses from camera image
  /// 
  /// Processes camera image and returns detected poses in YOLO format.
  /// Keypoints are returned in pixel coordinates matching the original camera image size.
  /// 
  /// Based on pose_test2.py: results = model(frame, verbose=False)
  Future<List<Map<String, dynamic>>> detectPosesFromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
  }) async {
    if (!_isInitialized) {
      throw Exception('Service not initialized. Call initialize() first.');
    }
    
    try {
      // Convert YUV420 camera image to img.Image and handle rotation/mirroring
      final convertedImage = _cameraImageToImage(image, camera);
      
      // Run pose detection using YOLO model
      // Model handles preprocessing (resize to 320x320) and returns keypoints in pixel coordinates
      final keypoints = await _modelManager.detectPoses(convertedImage);
      
      // Keypoints are already in pixel coordinates from model manager
      // Filter low-confidence keypoints (matching pose_test2.py: v > 0.5)
      final filtered =
          _filterKeypointsByConfidence(keypoints, minConfidence: 0.5);
      return filtered;
    } catch (e) {
      debugPrint('Custom pose detection error: $e');
      PoseDiagnostics.instance.markFrameFailure('Detection error: $e');
      return [];
    }
  }
  
  /// Convert camera image (YUV420) to img.Image with rotation and mirroring
  /// 
  /// Converts CameraImage from YUV420 format to RGB format required by YOLO model.
  /// Rotates the image based on sensor orientation to ensure upright person.
  /// Mirrors the image if using front camera.
  img.Image _cameraImageToImage(CameraImage cameraImage, CameraDescription camera) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;
    
    // Create img.Image buffer
    var image = img.Image(width: width, height: height, numChannels: 3);
    
    // Convert YUV420 to RGB
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        
        final int yValue = cameraImage.planes[0].bytes[yIndex];
        final int uValue = cameraImage.planes[1].bytes[math.min(
          uvIndex,
          cameraImage.planes[1].bytes.length - 1,
        )];
        final int vValue = cameraImage.planes[2].bytes[math.min(
          uvIndex,
          cameraImage.planes[2].bytes.length - 1,
        )];
        
        // YUV to RGB conversion (ITU-R BT.601)
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);
        
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    
    // Rotate image based on sensor orientation
    // Android sensor is typically landscape (90 or 270 degrees)
    if (camera.sensorOrientation != 0) {
      image = img.copyRotate(image, angle: camera.sensorOrientation);
    }
    
    // Mirror if front camera (after rotation)
    if (camera.lensDirection == CameraLensDirection.front) {
      image = img.copyFlip(image, direction: img.FlipDirection.horizontal);
    }
    
    return image;
  }
  
  /// Filter keypoints by confidence threshold
  /// 
  /// Matches pose_test2.py behavior: only keep keypoints with confidence > 0.5
  List<Map<String, dynamic>> _filterKeypointsByConfidence(
    List<Map<String, dynamic>> keypoints,
    {double minConfidence = 0.5}
  ) {
    return keypoints.where((kp) {
      final confidence = kp['confidence'] as double? ?? 0.0;
      return confidence > minConfidence;
    }).toList();
  }
  
  /// Calculate angle between three points
  double calculateAngle(
    Map<String, dynamic> pointA,
    Map<String, dynamic> vertex,
    Map<String, dynamic> pointB,
  ) {
    final v1 = Offset(
      pointA['x'] - vertex['x'],
      pointA['y'] - vertex['y'],
    );
    final v2 = Offset(
      pointB['x'] - vertex['x'],
      pointB['y'] - vertex['y'],
    );
    
    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final mag1 = v1.distance;
    final mag2 = v2.distance;
    
    if (mag1 == 0 || mag2 == 0) return 0.0;
    
    final cosTheta = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final radians = math.acos(cosTheta);
    return radians * 180.0 / math.pi;
  }
  
  /// Analyze exercise form
  Map<String, dynamic> analyzeExerciseForm(List<Map<String, dynamic>> keypoints) {
    final analysis = <String, dynamic>{};
    
    // Find relevant keypoints
    final leftShoulder = keypoints.firstWhere(
      (kp) => kp['name'] == 'leftShoulder',
      orElse: () => <String, dynamic>{},
    );
    final leftElbow = keypoints.firstWhere(
      (kp) => kp['name'] == 'leftElbow',
      orElse: () => <String, dynamic>{},
    );
    final leftWrist = keypoints.firstWhere(
      (kp) => kp['name'] == 'leftWrist',
      orElse: () => <String, dynamic>{},
    );
    
    if (leftShoulder.isNotEmpty && leftElbow.isNotEmpty && leftWrist.isNotEmpty) {
      final angle = calculateAngle(leftShoulder, leftElbow, leftWrist);
      analysis['leftArmAngle'] = angle;
      analysis['leftArmForm'] = _evaluateArmForm(angle);
    }
    
    // Similar analysis for right arm
    final rightShoulder = keypoints.firstWhere(
      (kp) => kp['name'] == 'rightShoulder',
      orElse: () => <String, dynamic>{},
    );
    final rightElbow = keypoints.firstWhere(
      (kp) => kp['name'] == 'rightElbow',
      orElse: () => <String, dynamic>{},
    );
    final rightWrist = keypoints.firstWhere(
      (kp) => kp['name'] == 'rightWrist',
      orElse: () => <String, dynamic>{},
    );
    
    if (rightShoulder.isNotEmpty && rightElbow.isNotEmpty && rightWrist.isNotEmpty) {
      final angle = calculateAngle(rightShoulder, rightElbow, rightWrist);
      analysis['rightArmAngle'] = angle;
      analysis['rightArmForm'] = _evaluateArmForm(angle);
    }
    
    return analysis;
  }
  
  /// Evaluate arm form based on angle
  String _evaluateArmForm(double angle) {
    if (angle < 45) return 'Too bent';
    if (angle > 135) return 'Too straight';
    return 'Good form';
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _modelManager.dispose();
    _isInitialized = false;
  }
}
