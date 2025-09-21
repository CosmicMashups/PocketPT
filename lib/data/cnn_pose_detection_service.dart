import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class CNNPoseDetectionService {
  static final CNNPoseDetectionService _instance = CNNPoseDetectionService._internal();
  factory CNNPoseDetectionService() => _instance;
  CNNPoseDetectionService._internal();

  // Model configuration
  static const int INPUT_SIZE = 224; // Standard input size for CNN models
  static const int NUM_CLASSES = 2; // Pained (0) and Not Pained (1)
  
  // Pain level mapping based on CNN output
  static const Map<int, String> PAIN_LABELS = {
    0: 'Pained',
    1: 'Not Pained'
  };

  // Convert camera image to the format expected by CNN
  Future<Uint8List> preprocessCameraImage(CameraImage image) async {
    try {
      // Convert camera image to bytes
      final bytes = _cameraImageToBytes(image);
      
      // Decode image
      final img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        throw Exception('Failed to decode camera image');
      }

      // Resize to model input size
      final resizedImage = img.copyResize(
        decodedImage,
        width: INPUT_SIZE,
        height: INPUT_SIZE,
        interpolation: img.Interpolation.linear,
      );

      // Convert to RGB format and normalize
      final rgbBytes = _imageToNormalizedRGB(resizedImage);
      
      return rgbBytes;
    } catch (e) {
      debugPrint('Image preprocessing error: $e');
      rethrow;
    }
  }

  // Convert CameraImage to Uint8List
  Uint8List _cameraImageToBytes(CameraImage image) {
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
    
    return bytes;
  }

  // Convert image to normalized RGB format
  Uint8List _imageToNormalizedRGB(img.Image image) {
    final rgbBytes = Uint8List(INPUT_SIZE * INPUT_SIZE * 3);
    int index = 0;
    
    for (int y = 0; y < INPUT_SIZE; y++) {
      for (int x = 0; x < INPUT_SIZE; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        
        // Normalize to 0-1 range
        rgbBytes[index++] = (r / 255.0 * 255).round().clamp(0, 255);
        rgbBytes[index++] = (g / 255.0 * 255).round().clamp(0, 255);
        rgbBytes[index++] = (b / 255.0 * 255).round().clamp(0, 255);
      }
    }
    
    return rgbBytes;
  }

  // Simulate CNN inference (replace with actual model inference)
  Future<Map<String, dynamic>> performCNNAssessment(CameraImage image) async {
    try {
      // Preprocess image
      final preprocessedImage = await preprocessCameraImage(image);
      
      // Simulate CNN inference - in real implementation, this would call the actual model
      // For now, we'll simulate based on image characteristics
      final painScore = _simulatePainDetection(preprocessedImage);
      
      // Convert to standardized format
      return _convertToStandardizedAssessment(painScore);
    } catch (e) {
      debugPrint('CNN assessment error: $e');
      return _getDefaultAssessment();
    }
  }

  // Simulate pain detection based on image characteristics
  int _simulatePainDetection(Uint8List imageData) {
    // Simple heuristic: analyze image brightness and contrast
    // In real implementation, this would be replaced with actual CNN inference
    
    double totalBrightness = 0;
    double totalContrast = 0;
    
    for (int i = 0; i < imageData.length; i += 3) {
      final r = imageData[i];
      final g = imageData[i + 1];
      final b = imageData[i + 2];
      
      final brightness = (r + g + b) / 3.0;
      totalBrightness += brightness;
      
      // Simple contrast calculation
      if (i > 0) {
        final prevBrightness = (imageData[i - 3] + imageData[i - 2] + imageData[i - 1]) / 3.0;
        totalContrast += (brightness - prevBrightness).abs();
      }
    }
    
    final avgBrightness = totalBrightness / (imageData.length / 3);
    final avgContrast = totalContrast / (imageData.length / 3);
    
    // Heuristic: lower brightness and higher contrast might indicate pain/compensation
    // This is a placeholder - real CNN would be much more sophisticated
    if (avgBrightness < 100 && avgContrast > 20) {
      return 0; // Pained
    } else {
      return 1; // Not Pained
    }
  }

  // Convert CNN output to standardized assessment format
  Map<String, dynamic> _convertToStandardizedAssessment(int painClass) {
    final isPained = painClass == 0;
    final painScore = isPained ? 8 : 2; // High pain for "Pained", low for "Not Pained"
    
    return {
      'cnnPrediction': painClass,
      'painLabel': PAIN_LABELS[painClass] ?? 'Unknown',
      'isPained': isPained,
      'painScore': painScore,
      'confidence': 0.85, // Simulated confidence
      'assessmentMethod': 'CNN',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Get default assessment when CNN fails
  Map<String, dynamic> _getDefaultAssessment() {
    return {
      'cnnPrediction': 1,
      'painLabel': 'Not Pained',
      'isPained': false,
      'painScore': 5,
      'confidence': 0.0,
      'assessmentMethod': 'CNN (Error)',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Calculate angle between three points (reused from original service)
  double calculateAngle(Offset point1, Offset point2, Offset point3) {
    final vector1 = point1 - point2;
    final vector2 = point3 - point2;
    
    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    final magnitude1 = math.sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy);
    final magnitude2 = math.sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy);
    
    if (magnitude1 == 0 || magnitude2 == 0) return 0.0;
    
    final cosine = dotProduct / (magnitude1 * magnitude2);
    final clampedCosine = cosine.clamp(-1.0, 1.0);
    final angleRadians = math.acos(clampedCosine);
    final angleDegrees = (angleRadians * 180) / math.pi;
    
    return angleDegrees;
  }

  // Get pain description based on score
  String getPainDescription(int painScore) {
    if (painScore <= 3) return 'Minimal pain';
    if (painScore <= 6) return 'Moderate pain';
    return 'Severe pain';
  }

  // Get ROM color based on pain score
  Color getROMColor(int painScore) {
    if (painScore <= 3) return Colors.green;
    if (painScore <= 6) return Colors.orange;
    return Colors.red;
  }

  // Comprehensive ROM Assessment using CNN
  Future<Map<String, dynamic>> performComprehensiveROMAssessment(CameraImage image) async {
    try {
      // Perform CNN assessment
      final cnnResult = await performCNNAssessment(image);
      
      // Create comprehensive assessment
      final assessment = <String, dynamic>{
        'cnn': cnnResult,
        'overallPainScore': cnnResult['painScore'],
        'painDescription': getPainDescription(cnnResult['painScore']),
        'overallROMStatus': cnnResult['isPained'] ? 'severe' : 'good',
        'assessmentMethod': 'CNN',
        'confidence': cnnResult['confidence'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      return assessment;
    } catch (e) {
      debugPrint('Comprehensive CNN assessment error: $e');
      return {
        'cnn': _getDefaultAssessment(),
        'overallPainScore': 5,
        'painDescription': 'Assessment error',
        'overallROMStatus': 'unknown',
        'assessmentMethod': 'CNN (Error)',
        'confidence': 0.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  // Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}
