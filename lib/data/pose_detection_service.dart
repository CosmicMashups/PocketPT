import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:camera/camera.dart';

class PoseDetectionService {
  static final PoseDetectionService _instance = PoseDetectionService._internal();
  factory PoseDetectionService() => _instance;
  PoseDetectionService._internal();

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    ),
  );

  // State from last processed frame to support coordinate normalization
  // These are used to ensure landmarks are properly normalized and mirrored
  Size? _lastImageSize;
  bool _isFrontCamera = false;

  // Detect poses from a camera image
  Future<List<Pose>> detectFromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
  }) async {
    try {
      int totalBytes = 0;
      for (final Plane plane in image.planes) {
        totalBytes += plane.bytes.length;
      }
      final bytes = Uint8List(totalBytes);
      int offset = 0;
      for (final Plane plane in image.planes) {
        final data = plane.bytes;
        bytes.setRange(offset, offset + data.length, data);
        offset += data.length;
      }

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation rotation = _rotationFromCamera(camera.sensorOrientation);
      final InputImageFormat format = _imageFormatFromRaw(image.format.raw);

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      // Persist context for downstream landmark normalization
      _lastImageSize = imageSize;
      _isFrontCamera = camera.lensDirection == CameraLensDirection.front;

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
      final poses = await _poseDetector.processImage(inputImage);
      return poses;
    } catch (e) {
      debugPrint('Pose detection error: $e');
      return <Pose>[];
    }
  }

  // Detect poses from a static image file
  Future<List<Pose>> detectFromImageFile(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(0, 0), // Will be determined from image
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 0,
        ),
      );
      final poses = await _poseDetector.processImage(inputImage);
      return poses;
    } catch (e) {
      debugPrint('Pose detection from file error: $e');
      return <Pose>[];
    }
  }

  // Process static image and return comprehensive assessment
  Future<Map<String, dynamic>> processStaticImage(File imageFile) async {
    try {
      final poses = await detectFromImageFile(imageFile);
      if (poses.isEmpty) {
        return {
          'error': 'No poses detected in image',
          'overallPainScore': 5,
          'painDescription': 'No pose detected',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      }

      final landmarks = getPoseLandmarks(poses.first);
      final assessment = performComprehensiveROMAssessment(landmarks);
      
      return assessment;
    } catch (e) {
      debugPrint('Error processing static image: $e');
      return {
        'error': e.toString(),
        'overallPainScore': 5,
        'painDescription': 'Processing error',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  InputImageRotation _rotationFromCamera(int sensorOrientation) {
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    return rotation ?? InputImageRotation.rotation0deg;
  }

  InputImageFormat _imageFormatFromRaw(int raw) {
    final format = InputImageFormatValue.fromRawValue(raw);
    return format ?? InputImageFormat.nv21;
  }

  // Get pose landmarks as a map with improved coordinate normalization
  Map<String, Offset> getPoseLandmarks(Pose pose) {
    final landmarks = <String, Offset>{};
    final Size? imgSize = _lastImageSize;
    
    // Helper to normalize and mirror if needed with improved error handling
    Offset _toNormalized(Offset p) {
      if (imgSize == null || imgSize.width <= 0 || imgSize.height <= 0) {
        debugPrint('Warning: Invalid image size for coordinate normalization: $imgSize');
        return Offset(0.5, 0.5); // Return center point as fallback
      }
      
      // Ensure coordinates are within valid range
      double x = p.dx.clamp(0.0, imgSize.width);
      double y = p.dy.clamp(0.0, imgSize.height);
      
      // Normalize to 0.0-1.0 range
      double nx = x / imgSize.width;
      double ny = y / imgSize.height;
      
      // Mirror horizontally for front camera preview to match camera display
      if (_isFrontCamera) {
        nx = 1.0 - nx;
      }
      
      return Offset(nx, ny);
    }
    for (final entry in pose.landmarks.entries) {
      final type = entry.key;
      final lm = entry.value;
      final point = _toNormalized(Offset(lm.x, lm.y));
      switch (type) {
        case PoseLandmarkType.nose:
          landmarks['nose'] = point; break;
        case PoseLandmarkType.leftEye:
          landmarks['leftEye'] = point; break;
        case PoseLandmarkType.rightEye:
          landmarks['rightEye'] = point; break;
        case PoseLandmarkType.leftShoulder:
          landmarks['leftShoulder'] = point; break;
        case PoseLandmarkType.rightShoulder:
          landmarks['rightShoulder'] = point; break;
        case PoseLandmarkType.leftElbow:
          landmarks['leftElbow'] = point; break;
        case PoseLandmarkType.rightElbow:
          landmarks['rightElbow'] = point; break;
        case PoseLandmarkType.leftWrist:
          landmarks['leftWrist'] = point; break;
        case PoseLandmarkType.rightWrist:
          landmarks['rightWrist'] = point; break;
        case PoseLandmarkType.leftHip:
          landmarks['leftHip'] = point; break;
        case PoseLandmarkType.rightHip:
          landmarks['rightHip'] = point; break;
        case PoseLandmarkType.leftKnee:
          landmarks['leftKnee'] = point; break;
        case PoseLandmarkType.rightKnee:
          landmarks['rightKnee'] = point; break;
        case PoseLandmarkType.leftAnkle:
          landmarks['leftAnkle'] = point; break;
        case PoseLandmarkType.rightAnkle:
          landmarks['rightAnkle'] = point; break;
        case PoseLandmarkType.leftHeel:
          landmarks['leftHeel'] = point; break;
        case PoseLandmarkType.rightHeel:
          landmarks['rightHeel'] = point; break;
        case PoseLandmarkType.leftFootIndex:
          landmarks['leftFootIndex'] = point; break;
        case PoseLandmarkType.rightFootIndex:
          landmarks['rightFootIndex'] = point; break;
        case PoseLandmarkType.leftEar:
          landmarks['leftEar'] = point; break;
        case PoseLandmarkType.rightEar:
          landmarks['rightEar'] = point; break;
        case PoseLandmarkType.leftPinky:
          landmarks['leftPinky'] = point; break;
        case PoseLandmarkType.rightPinky:
          landmarks['rightPinky'] = point; break;
        case PoseLandmarkType.leftIndex:
          landmarks['leftIndex'] = point; break;
        case PoseLandmarkType.rightIndex:
          landmarks['rightIndex'] = point; break;
        case PoseLandmarkType.leftThumb:
          landmarks['leftThumb'] = point; break;
        case PoseLandmarkType.rightThumb:
          landmarks['rightThumb'] = point; break;
        default:
          break;
      }
    }
    return landmarks;
  }

  // Calculate angle between three points (for joint angles)
  double calculateAngle(Offset pointA, Offset vertex, Offset pointB) {
    final v1 = pointA - vertex;
    final v2 = pointB - vertex;
    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final mag1 = v1.distance;
    final mag2 = v2.distance;
    if (mag1 == 0 || mag2 == 0) return 0.0;
    double cosTheta = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final radians = math.acos(cosTheta);
    return radians * 180.0 / 3.1415926535;
  }

  // Analyze exercise form based on pose landmarks
  Map<String, dynamic> analyzeExerciseForm(Map<String, Offset> landmarks) {
    final analysis = <String, dynamic>{};
    
    if (landmarks.containsKey('leftShoulder') && 
        landmarks.containsKey('leftElbow') && 
        landmarks.containsKey('leftWrist')) {
      
      final shoulderAngle = calculateAngle(
        landmarks['leftShoulder']!,
        landmarks['leftElbow']!,
        landmarks['leftWrist']!
      );
      
      analysis['leftArmAngle'] = shoulderAngle;
      analysis['leftArmForm'] = _evaluateArmForm(shoulderAngle);
    }
    
    if (landmarks.containsKey('rightShoulder') && 
        landmarks.containsKey('rightElbow') && 
        landmarks.containsKey('rightWrist')) {
      
      final shoulderAngle = calculateAngle(
        landmarks['rightShoulder']!,
        landmarks['rightElbow']!,
        landmarks['rightWrist']!
      );
      
      analysis['rightArmAngle'] = shoulderAngle;
      analysis['rightArmForm'] = _evaluateArmForm(shoulderAngle);
    }
    
    return analysis;
  }

  String _evaluateArmForm(double angle) {
    if (angle < 45) return 'Too bent';
    if (angle > 135) return 'Too straight';
    return 'Good form';
  }

  // ROM Assessment Methods (matching Jupyter logic exactly)
  Map<String, dynamic> assessTricepsROM(Map<String, Offset> landmarks) {
    final assessment = <String, dynamic>{};
    
    try {
      // Left triceps assessment (Shoulder-Elbow-Wrist angle)
      if (landmarks.containsKey('leftShoulder') && 
          landmarks.containsKey('leftElbow') && 
          landmarks.containsKey('leftWrist')) {
        final angle = calculateAngle(
          landmarks['leftShoulder']!,
          landmarks['leftElbow']!,
          landmarks['leftWrist']!
        );
        if (angle.isFinite && angle >= 0) {
          assessment['leftTricepsAngle'] = angle;
          assessment['leftTricepsROM'] = _evaluateTricepsROM(angle);
          assessment['leftTricepsLabel'] = _getTricepsROMLabel(angle);
        }
      }
      
      // Right triceps assessment (Shoulder-Elbow-Wrist angle)
      if (landmarks.containsKey('rightShoulder') && 
          landmarks.containsKey('rightElbow') && 
          landmarks.containsKey('rightWrist')) {
        final angle = calculateAngle(
          landmarks['rightShoulder']!,
          landmarks['rightElbow']!,
          landmarks['rightWrist']!
        );
        if (angle.isFinite && angle >= 0) {
          assessment['rightTricepsAngle'] = angle;
          assessment['rightTricepsROM'] = _evaluateTricepsROM(angle);
          assessment['rightTricepsLabel'] = _getTricepsROMLabel(angle);
        }
      }
    } catch (e) {
      print('Triceps assessment error: $e');
    }
    
    return assessment;
  }

  Map<String, dynamic> assessShouldersROM(Map<String, Offset> landmarks) {
    final assessment = <String, dynamic>{};
    
    try {
      // Left shoulder assessment (Hip-Shoulder-Elbow angle)
      if (landmarks.containsKey('leftHip') && 
          landmarks.containsKey('leftShoulder') && 
          landmarks.containsKey('leftElbow')) {
        final angle = calculateAngle(
          landmarks['leftHip']!,
          landmarks['leftShoulder']!,
          landmarks['leftElbow']!
        );
        if (angle.isFinite && angle >= 0) {
          assessment['leftShoulderAngle'] = angle;
          assessment['leftShoulderROM'] = _evaluateShouldersROM(angle);
          assessment['leftShoulderLabel'] = _getShouldersROMLabel(angle);
        }
      }
      
      // Right shoulder assessment (Hip-Shoulder-Elbow angle)
      if (landmarks.containsKey('rightHip') && 
          landmarks.containsKey('rightShoulder') && 
          landmarks.containsKey('rightElbow')) {
        final angle = calculateAngle(
          landmarks['rightHip']!,
          landmarks['rightShoulder']!,
          landmarks['rightElbow']!
        );
        if (angle.isFinite && angle >= 0) {
          assessment['rightShoulderAngle'] = angle;
          assessment['rightShoulderROM'] = _evaluateShouldersROM(angle);
          assessment['rightShoulderLabel'] = _getShouldersROMLabel(angle);
        }
      }
    } catch (e) {
      print('Shoulder assessment error: $e');
    }
    
    return assessment;
  }

  // Compensation Detection (matching Jupyter logic exactly)
  Map<String, dynamic> detectCompensations(Map<String, Offset> landmarks) {
    final compensations = <String, dynamic>{};
    
    if (landmarks.containsKey('leftShoulder') && 
        landmarks.containsKey('rightShoulder') &&
        landmarks.containsKey('leftHip') && 
        landmarks.containsKey('rightHip')) {
      
      // Shoulder Elevation Compensation (Normalized vertical difference between shoulders)
      final leftShoulderY = landmarks['leftShoulder']!.dy;
      final rightShoulderY = landmarks['rightShoulder']!.dy;
      final shoulderDifference = (leftShoulderY - rightShoulderY).abs();
      
      // Normalized by the vertical distance between hips (a proxy for torso height)
      final hipDistance = (landmarks['leftHip']! - landmarks['rightHip']!).distance;
      final shoulderElevationRatio = shoulderDifference / hipDistance;
      
      if (shoulderElevationRatio > 0.05) { // 5% threshold
        compensations['shoulderElevation'] = true;
        compensations['shoulderElevationMessage'] = 'Warning: Shoulder Elevation Compensation';
      }
      
      // Torso Lean Compensation (Lateral deviation of torso relative to vertical axis)
      // Using horizontal difference between hips, normalized by hip distance
      final leftHipX = landmarks['leftHip']!.dx;
      final rightHipX = landmarks['rightHip']!.dx;
      final hipCenterX = (leftHipX + rightHipX) / 2;
      
      final leftShoulderX = landmarks['leftShoulder']!.dx;
      final rightShoulderX = landmarks['rightShoulder']!.dx;
      final shoulderCenterX = (leftShoulderX + rightShoulderX) / 2;
      
      final torsoLean = (hipCenterX - shoulderCenterX).abs();
      final torsoLeanRatio = torsoLean / hipDistance;
      
      if (torsoLeanRatio > 0.05) { // 5% threshold
        compensations['torsoLean'] = true;
        compensations['torsoLeanMessage'] = 'Warning: Torso Lean Compensation';
      }
    }
    
    return compensations;
  }

  // ROM Evaluation Methods (matching Jupyter logic exactly)
  String _evaluateTricepsROM(double angle) {
    // Triceps Extension (Shoulder-Elbow-Wrist angle)
    // Angle: ~180 is straight (full extension), ~0 is fully flexed
    if (angle < 90) return 'severe';      // Angle < 90° -> Severe (Limited Extension)
    if (angle < 135) return 'moderate';  // 90° <= Angle < 135° -> Moderate (Partial Extension)
    return 'good';                      // Angle >= 135° -> Good (Good Extension)
  }

  String _evaluateShouldersROM(double angle) {
    // Shoulder Assessment (Hip-Shoulder-Elbow angle)
    // Angle: ~180 arm down, ~90 T-pose, ~<90 arm raised above T-pose
    if (angle < 90) return 'severe';   // Angle < 90° -> Severe Pain (Arm raised high)
    if (angle <= 110) return 'moderate'; // 90° <= Angle <= 110° -> Moderate Pain (Closer to T-pose)
    if (angle <= 150) return 'low';     // 111° <= Angle <= 150° -> Low Pain (Arm down/partial)
    return 'good';                      // Angle > 150° -> Good Mobility/Low Pain (Arm closer to body)
  }

  // ROM Label Methods (matching Jupyter format exactly)
  String _getTricepsROMLabel(double angle) {
    final rom = _evaluateTricepsROM(angle);
    switch (rom) {
      case 'severe':
        return 'Triceps ROM: Severe (<90°)';
      case 'moderate':
        return 'Triceps ROM: Moderate (90-134°)';
      case 'good':
        return 'Triceps ROM: Good (>=135°)';
      default:
        return 'Triceps ROM: Unknown';
    }
  }

  String _getShouldersROMLabel(double angle) {
    final rom = _evaluateShouldersROM(angle);
    switch (rom) {
      case 'severe':
        return 'Shoulder Pain: Severe (<90°)';
      case 'moderate':
        return 'Shoulder Pain: Moderate (90-110°)';
      case 'low':
        return 'Shoulder Pain: Low (111-150°)';
      case 'good':
        return 'Shoulder Mobility: Good (>=151°)';
      default:
        return 'Shoulder ROM: Unknown';
    }
  }

  // Standardized ROM to Pain Scale Conversion (Clinical Standards)
  // Based on clinical pain assessment practices and ROM limitations
  int romToPainScale(String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 9; // 8-10: Severe limitation/pain (significant functional impact)
      case 'moderate':
        return 6; // 5-7: Moderate limitation/pain (noticeable functional impact)
      case 'low':
        return 3; // 2-4: Low limitation/pain (minimal functional impact)
      case 'good':
        return 1; // 0-1: Good ROM/no pain (normal function)
      default:
        return 5; // Default moderate pain when ROM level is unknown
    }
  }

  // Clinical Pain Scale Descriptions for User Understanding
  String getPainDescription(int painScale) {
    if (painScale >= 8) {
      return "Severe Pain - Significant functional limitation";
    } else if (painScale >= 5) {
      return "Moderate Pain - Noticeable functional impact";
    } else if (painScale >= 2) {
      return "Low Pain - Minimal functional impact";
    } else {
      return "No/Minimal Pain - Normal function";
    }
  }

  // ROM Level Assessment with Clinical Context
  String getROMClinicalContext(String romLevel, String assessmentType) {
    switch (romLevel) {
      case 'severe':
        return "Severe ROM limitation - Requires immediate attention";
      case 'moderate':
        return "Moderate ROM limitation - Monitor and consider intervention";
      case 'low':
        return "Mild ROM limitation - Continue monitoring";
      case 'good':
        return "Normal ROM - Maintain current activities";
      default:
        return "ROM assessment incomplete - Retry assessment";
    }
  }

  // Comprehensive ROM Assessment with Standardized Clinical Pain Scale
  Map<String, dynamic> performComprehensiveROMAssessment(Map<String, Offset> landmarks) {
    final assessment = <String, dynamic>{};
    
    try {
      // Perform ROM assessments (matching Jupyter focus)
      assessment['triceps'] = assessTricepsROM(landmarks);
      assessment['shoulders'] = assessShouldersROM(landmarks);
      assessment['compensations'] = detectCompensations(landmarks);
      
      // Calculate overall pain score using standardized method
      final painScores = <int>[];
      final romLevels = <String>[];
      
      // Add triceps scores and ROM levels
      if (assessment['triceps']['leftTricepsROM'] != null) {
        final romLevel = assessment['triceps']['leftTricepsROM'];
        painScores.add(romToPainScale(romLevel));
        romLevels.add(romLevel);
      }
      if (assessment['triceps']['rightTricepsROM'] != null) {
        final romLevel = assessment['triceps']['rightTricepsROM'];
        painScores.add(romToPainScale(romLevel));
        romLevels.add(romLevel);
      }
      
      // Add shoulder scores and ROM levels
      if (assessment['shoulders']['leftShoulderROM'] != null) {
        final romLevel = assessment['shoulders']['leftShoulderROM'];
        painScores.add(romToPainScale(romLevel));
        romLevels.add(romLevel);
      }
      if (assessment['shoulders']['rightShoulderROM'] != null) {
        final romLevel = assessment['shoulders']['rightShoulderROM'];
        painScores.add(romToPainScale(romLevel));
        romLevels.add(romLevel);
      }
      
      // Calculate overall pain score and clinical context
      if (painScores.isNotEmpty) {
        final averagePain = painScores.reduce((a, b) => a + b) / painScores.length;
        assessment['overallPainScore'] = averagePain.round();
        assessment['painDescription'] = getPainDescription(averagePain.round());
        
        // Determine overall ROM status
        final severeCount = romLevels.where((level) => level == 'severe').length;
        final moderateCount = romLevels.where((level) => level == 'moderate').length;
        
        if (severeCount > 0) {
          assessment['overallROMStatus'] = 'severe';
        } else if (moderateCount > 0) {
          assessment['overallROMStatus'] = 'moderate';
        } else if (romLevels.any((level) => level == 'low')) {
          assessment['overallROMStatus'] = 'low';
        } else {
          assessment['overallROMStatus'] = 'good';
        }
        
        assessment['clinicalContext'] = getROMClinicalContext(
          assessment['overallROMStatus'], 
          'comprehensive'
        );
      } else {
        assessment['overallPainScore'] = 5; // Default moderate pain if no valid scores
        assessment['painDescription'] = getPainDescription(5);
        assessment['overallROMStatus'] = 'unknown';
        assessment['clinicalContext'] = 'ROM assessment incomplete - Retry assessment';
      }
      
      return assessment;
    } catch (e) {
      print('Comprehensive ROM assessment error: $e');
      // Return minimal assessment on error
      return {
        'triceps': {},
        'shoulders': {},
        'compensations': {},
        'overallPainScore': 5,
        'painDescription': getPainDescription(5),
        'overallROMStatus': 'unknown',
        'clinicalContext': 'Assessment error - Retry assessment',
      };
    }
  }

  // Dispose resources
  void dispose() {
    _poseDetector.close();
  }
}
