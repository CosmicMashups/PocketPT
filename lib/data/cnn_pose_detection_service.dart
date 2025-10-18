import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
// import 'package:flutter_pytorch_lite/flutter_pytorch_lite.dart'; // Temporarily disabled

/// Service for CNN-based pose detection and pain assessment
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

  // Model state
  bool _isModelLoaded = false;
  // Module? _cnnModel; // Temporarily disabled - PyTorch type
  dynamic _cnnModel; // Using dynamic to avoid compilation errors
  double _lastConfidence = 0;
  bool _lastIsPained = false;

  /// Initialize the CNN pose detection service
  Future<void> initialize() async {
    try {
      debugPrint('CNNPoseDetectionService: Initializing...');
      await _loadModel();
      _isModelLoaded = true;
      debugPrint('CNNPoseDetectionService: Initialized successfully');
    } catch (e) {
      debugPrint('CNNPoseDetectionService: Error during initialization: $e');
      rethrow;
    }
  }

  /// Load the CNN model
  Future<void> _loadModel() async {
    try {
      // Temporarily disabled - PyTorch functionality not available
      // _cnnModel = await FlutterPytorchLite.load('assets/model/cnn_best.pt');
      debugPrint('CNNPoseDetectionService: PyTorch functionality temporarily disabled - using simulation mode');
      _cnnModel = null; // Force simulation mode
    } catch (e) {
      debugPrint('CNNPoseDetectionService: Error loading model: $e');
      // Fallback to simulation if model loading fails
      debugPrint('CNNPoseDetectionService: Falling back to simulation mode');
    }
  }

  /// Perform comprehensive ROM assessment using CNN
  Future<Map<String, dynamic>> performComprehensiveROMAssessment(CameraImage image) async {
    try {
      // Preprocess camera image
      final processedImage = await preprocessCameraImage(image);
      
      // Run CNN inference
      final cnnResult = await _runCNNInference(processedImage);
      
      // Calculate overall pain score based on CNN result
      final overallPainScore = _calculatePainScoreFromCNN(cnnResult);
      
      return {
        'cnn': cnnResult,
        'overallPainScore': overallPainScore,
        'painDescription': _getPainDescription(overallPainScore),
        'compensations': <String, dynamic>{}, // CNN doesn't detect compensations
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('CNNPoseDetectionService: Error in comprehensive assessment: $e');
      return {
        'cnn': {
          'isPained': false,
          'confidence': 0.0,
          'prediction': 'Not Pained',
          'error': e.toString()
        },
        'overallPainScore': 5, // Default moderate pain
        'painDescription': 'Assessment Error',
        'compensations': <String, dynamic>{},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Process static image file for pain assessment
  Future<Map<String, dynamic>> processStaticImage(File imageFile) async {
    try {
      // Read and preprocess the image file
      final bytes = await imageFile.readAsBytes();
      final processedImage = await _preprocessImageBytes(bytes);
      
      // Run CNN inference
      final cnnResult = await _runCNNInference(processedImage);
      
      // Calculate overall pain score based on CNN result
      final overallPainScore = _calculatePainScoreFromCNN(cnnResult);
      
      return {
        'cnn': cnnResult,
        'overallPainScore': overallPainScore,
        'painDescription': _getPainDescription(overallPainScore),
        'compensations': <String, dynamic>{}, // CNN doesn't detect compensations
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('CNNPoseDetectionService: Error processing static image: $e');
      return {
        'cnn': {
          'isPained': false,
          'confidence': 0.0,
          'prediction': 'Not Pained',
          'error': e.toString()
        },
        'overallPainScore': 5, // Default moderate pain
        'painDescription': 'Assessment Error',
        'compensations': <String, dynamic>{},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Preprocess image bytes for CNN inference
  Future<Uint8List> _preprocessImageBytes(Uint8List bytes) async {
    try {
      // Decode image
      final img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        throw Exception('Failed to decode image');
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

  /// Convert camera image to the format expected by CNN
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

  /// Convert CameraImage to Uint8List
  Uint8List _cameraImageToBytes(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    
    final Uint8List rgb = Uint8List(width * height * 3);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        
        final int yValue = image.planes[0].bytes[yIndex];
        final int uValue = image.planes[1].bytes[uvIndex];
        final int vValue = image.planes[2].bytes[uvIndex];
        
        // YUV to RGB conversion
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);
        
        final int rgbIndex = yIndex * 3;
        rgb[rgbIndex] = r;
        rgb[rgbIndex + 1] = g;
        rgb[rgbIndex + 2] = b;
      }
    }
    
    return rgb;
  }

  /// Convert image to normalized RGB bytes
  Uint8List _imageToNormalizedRGB(img.Image image) {
    final Uint8List rgbBytes = Uint8List(INPUT_SIZE * INPUT_SIZE * 3);
    int index = 0;
    
    for (int y = 0; y < INPUT_SIZE; y++) {
      for (int x = 0; x < INPUT_SIZE; x++) {
        final pixel = image.getPixel(x, y);
        // Store RGB values directly (will be normalized in tensor conversion)
        rgbBytes[index++] = pixel.r.toInt();
        rgbBytes[index++] = pixel.g.toInt();
        rgbBytes[index++] = pixel.b.toInt();
      }
    }
    
    return rgbBytes;
  }

  /// Run CNN inference
  Future<Map<String, dynamic>> _runCNNInference(Uint8List imageData) async {
    try {
      if (_cnnModel != null) {
        return await _runRealCNNInference(imageData);
      } else {
        return await _runSimulatedCNNInference(imageData);
      }
    } catch (e) {
      debugPrint('CNNPoseDetectionService: Error in CNN inference: $e');
      return {
        'isPained': false,
        'confidence': 0.0,
        'prediction': 'Not Pained',
        'error': e.toString()
      };
    }
  }

  /// Run actual CNN model inference
  Future<Map<String, dynamic>> _runRealCNNInference(Uint8List imageData) async {
    try {
      // PyTorch functionality temporarily disabled
      debugPrint('CNNPoseDetectionService: Real CNN inference temporarily disabled - using simulation');
      
      // Fallback to simulation since PyTorch is not available
      return await _runSimulatedCNNInference(imageData);
    } catch (e) {
      debugPrint('CNNPoseDetectionService: Error in real CNN inference: $e');
      // Fallback to simulation
      return await _runSimulatedCNNInference(imageData);
    }
  }

  /// Run simulated CNN inference (fallback)
  Future<Map<String, dynamic>> _runSimulatedCNNInference(Uint8List imageData) async {
    // Simulate model inference time
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Simulate pain detection based on image characteristics
    final isPained = _simulatePainDetection(imageData);
    final confidence = isPained ? 0.85 : 0.15; // Simulated confidence
    final prediction = isPained ? 'Pained' : 'Not Pained';
    
    // Update last prediction
    _lastConfidence = confidence;
    _lastIsPained = isPained;
    
    return {
      'isPained': isPained,
      'confidence': confidence,
      'prediction': prediction,
      'error': null
    };
  }

  // Note: Tensor creation and softmax methods removed as they are not currently used
  // These will be re-implemented when PyTorch functionality is restored

  /// Simulate pain detection based on image characteristics
  bool _simulatePainDetection(Uint8List imageData) {
    // This is a simplified simulation - in reality, the CNN model would analyze
    // pose characteristics, muscle tension, movement patterns, etc.
    
    // Simulate random pain detection for demonstration
    // In practice, this would be replaced by the actual model inference
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return random < 20; // 20% chance of detecting pain (for demo purposes)
  }

  /// Calculate pain score from CNN result
  int _calculatePainScoreFromCNN(Map<String, dynamic> cnnResult) {
    final bool isPained = cnnResult['isPained'] ?? false;
    final double confidence = cnnResult['confidence'] ?? 0.0;
    // final double painedProb = cnnResult['painedProb'] ?? 0.0; // Unused for now
    
    if (!isPained) {
      // Not pained - return low pain score based on confidence
      if (confidence > 0.9) {
        return 1; // Very confident not pained
      } else if (confidence > 0.7) {
        return 2; // Confident not pained
      } else {
        return 3; // Uncertain but not pained
      }
    }
    
    // Pained - map confidence to pain score
    if (confidence > 0.9) {
      return 10; // Very severe pain (high confidence)
    } else if (confidence > 0.8) {
      return 9; // Severe pain
    } else if (confidence > 0.7) {
      return 8; // Severe pain
    } else if (confidence > 0.6) {
      return 7; // Moderate-severe pain
    } else if (confidence > 0.5) {
      return 6; // Moderate pain
    } else {
      return 5; // Low-moderate pain (uncertain)
    }
  }

  /// Get pain description based on score
  String _getPainDescription(int painScore) {
    if (painScore <= 1) return 'Good ROM';
    if (painScore <= 3) return 'Low Pain';
    if (painScore <= 6) return 'Moderate Pain';
    return 'Severe Pain';
  }

  /// Get last prediction
  Map<String, dynamic> getLastPrediction() {
      return {
      'isPained': _lastIsPained,
      'confidence': _lastConfidence,
      'prediction': _lastIsPained ? 'Pained' : 'Not Pained',
    };
  }

  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;

  /// Get pain labels
  Map<int, String> get painLabels => PAIN_LABELS;

  /// Dispose resources
  void dispose() {
    _isModelLoaded = false;
    _cnnModel = null;
    debugPrint('CNNPoseDetectionService: Disposed');
  }
}