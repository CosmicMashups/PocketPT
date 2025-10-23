import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pose_model_manager.dart';

/// Custom pose detection service using the trained pose estimation model
/// 
/// This service provides pose detection functionality using the custom
/// trained model instead of Google ML Kit, offering enhanced accuracy
/// and specialized pose detection capabilities.
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
      debugPrint('✓ Custom pose detection service initialized');
    } catch (e) {
      debugPrint('✗ Failed to initialize custom pose detection service: $e');
      rethrow;
    }
  }
  
  /// Detect poses from camera image
  Future<List<Map<String, dynamic>>> detectPosesFromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
  }) async {
    if (!_isInitialized) {
      throw Exception('Service not initialized. Call initialize() first.');
    }
    
    try {
      // Convert camera image to bytes
      final imageBytes = _cameraImageToBytes(image);
      
      // Run pose detection
      final keypoints = await _modelManager.detectPoses(imageBytes);
      
      // Post-process results
      return _postprocessKeypoints(keypoints, image.width, image.height);
    } catch (e) {
      debugPrint('Custom pose detection error: $e');
      return [];
    }
  }
  
  /// Convert camera image to bytes
  Uint8List _cameraImageToBytes(CameraImage cameraImage) {
    final int totalBytes = cameraImage.planes.fold(0, (sum, plane) => sum + plane.bytes.length);
    final Uint8List bytes = Uint8List(totalBytes);
    int offset = 0;
    
    for (final Plane plane in cameraImage.planes) {
      bytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    
    return bytes;
  }
  
  /// Post-process keypoints
  List<Map<String, dynamic>> _postprocessKeypoints(
    List<Map<String, dynamic>> keypoints,
    int imageWidth,
    int imageHeight,
  ) {
    final processedKeypoints = <Map<String, dynamic>>[];
    
    for (final kp in keypoints) {
      final confidence = kp['confidence'] as double;
      
      // Filter out low-confidence keypoints
      if (confidence > 0.5) {
        processedKeypoints.add({
          'x': kp['x'] * imageWidth,  // Convert to pixel coordinates
          'y': kp['y'] * imageHeight,
          'confidence': confidence,
          'name': kp['name'],
          'index': kp['index'],
        });
      }
    }
    
    return processedKeypoints;
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
  void dispose() {
    _modelManager.dispose();
    _isInitialized = false;
  }
}
