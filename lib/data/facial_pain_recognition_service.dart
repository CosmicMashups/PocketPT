import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
// import 'package:flutter_pytorch_lite/flutter_pytorch_lite.dart'; // Temporarily disabled

/// Service for facial pain recognition using PyTorch model
/// 
/// This service is aligned with the training code in pain_train.py:
/// - Model Architecture: MobileNetV3-Small with 3-class output
/// - Class Order: 0=Low, 1=Moderate, 2=Severe (matches CLASS_NAMES in training)
/// - Inference Pattern: logits → softmax → argmax → class + confidence
/// - Training used PSPI-based thresholds (t1, t2) for label assignment during training,
///   but inference uses direct class prediction from model output
/// - Model outputs raw logits which must be converted to probabilities via softmax
/// - Confidence is the probability of the predicted class (not a separate metric)
/// 
/// Model Metadata (from pain_train.py saved model):
/// - class_names: ['Low', 'Moderate', 'Severe']
/// - thresholds: (t1, t2) - PSPI thresholds used during training
/// - image_size: 224
/// - normalize_mean: [0.485, 0.456, 0.406]
/// - normalize_std: [0.229, 0.224, 0.225]
class FacialPainRecognitionService {
  static final FacialPainRecognitionService _instance = FacialPainRecognitionService._internal();
  factory FacialPainRecognitionService() => _instance;
  FacialPainRecognitionService._internal();

  // Model parameters (aligned with pain_train.py)
  static const int _inputSize = 224; // Model input size (aligned with training)
  
  // Pain labels - 3-class system (aligned with CLASS_NAMES in pain_train.py)
  // Class indices: 0=Low, 1=Moderate, 2=Severe
  static const List<String> _painLabels = ['Low', 'Moderate', 'Severe'];
  
  // Model state
  bool _isModelLoaded = false;
  double _lastPainConfidence = 0;
  String _lastPainPrediction = 'Low';
  // Module? _painModel; // Temporarily disabled - PyTorch type
  dynamic _painModel; // Using dynamic to avoid compilation errors
  
  // Model metadata (aligned with pain_train.py saved model structure)
  Map<String, dynamic>? _modelMetadata;
  
  // Performance optimization
  static const int MAX_FPS = 5; // Maximum frames per second for pain detection
  DateTime? _lastProcessTime;
  
  // Timeout configuration for pain detection processing
  static const Duration _processingTimeout = Duration(seconds: 5); // Max time for processing a frame
  
  // Default normalization values (aligned with pain_train.py)
  // These match ImageNet normalization used in training
  static const List<double> _defaultNormalizeMean = [0.485, 0.456, 0.406];
  static const List<double> _defaultNormalizeStd = [0.229, 0.224, 0.225];
  
  /// Initialize the facial pain recognition service
  Future<void> initialize() async {
    try {
      debugPrint('FacialPainRecognitionService: Initializing...');
      
      // In a real implementation, you would load the PyTorch model here
      // For now, we'll simulate the model loading
      await _loadModel();
      
      _isModelLoaded = true;
      debugPrint('FacialPainRecognitionService: Initialized successfully');
    } catch (e) {
      debugPrint('FacialPainRecognitionService: Error during initialization: $e');
      rethrow;
    }
  }
  
  /// Load the PyTorch model and metadata
  /// Aligned with pain_train.py model saving structure:
  /// The saved model includes: state_dict, class_names, thresholds, image_size,
  /// normalize_mean, normalize_std, face_crop_enabled, min_face_size, face_margin, etc.
  Future<void> _loadModel() async {
    try {
      // Temporarily disabled - PyTorch functionality not available
      // When enabled, load model and extract metadata:
      // _painModel = await FlutterPytorchLite.load('assets/model/pain_detection_model.pth');
      // _modelMetadata = await _extractModelMetadata(_painModel);
      // 
      // Expected metadata structure (from pain_train.py):
      // {
      //   "class_names": ["Low", "Moderate", "Severe"],
      //   "thresholds": (t1, t2),  // PSPI thresholds used during training
      //   "image_size": 224,
      //   "normalize_mean": [0.485, 0.456, 0.406],
      //   "normalize_std": [0.229, 0.224, 0.225],
      //   "face_crop_enabled": true,
      //   "min_face_size": 96,
      //   "face_margin": 0.15,
      //   ...
      // }
      
      debugPrint('FacialPainRecognitionService: PyTorch functionality temporarily disabled - using simulation mode');
      _painModel = null; // Force simulation mode
      
      // Set default metadata for simulation (aligned with training defaults)
      _modelMetadata = {
        'class_names': _painLabels,
        'thresholds': [1.0, 3.0], // Default PSPI thresholds (Low≤1, Moderate≤3, Severe>3)
        'image_size': _inputSize,
        'normalize_mean': _defaultNormalizeMean,
        'normalize_std': _defaultNormalizeStd,
      };
      debugPrint('FacialPainRecognitionService: Using default metadata - class_names: ${_modelMetadata!['class_names']}, thresholds: ${_modelMetadata!['thresholds']}');
    } catch (e) {
      debugPrint('FacialPainRecognitionService: Error loading model: $e');
      // Fallback to simulation if model loading fails
      debugPrint('FacialPainRecognitionService: Falling back to simulation mode');
      _modelMetadata = {
        'class_names': _painLabels,
        'thresholds': [1.0, 3.0],
        'image_size': _inputSize,
        'normalize_mean': _defaultNormalizeMean,
        'normalize_std': _defaultNormalizeStd,
      };
    }
  }
  
  /// Detect facial pain from camera image with frame rate limiting and timeout handling
  Future<Map<String, dynamic>> detectFacialPain({
    CameraImage? image,
    required CameraDescription camera,
  }) async {
    if (!_isModelLoaded) {
      return {
        'painLevel': 'Low',
        'confidence': 0.0,
        'prediction': 'Low',
        'error': 'Model not loaded'
      };
    }
    
    // Frame rate limiting for performance
    if (!_shouldProcessFrame()) {
      return getLastPrediction();
    }
    
    // For now, use simulation mode since camera image processing needs proper implementation
    if (image == null) {
      return await _runSimulatedPainRecognitionModel(null).timeout(
        _processingTimeout,
        onTimeout: () {
          debugPrint('FacialPainRecognitionService: Pain detection timeout');
          return getLastPrediction();
        },
      );
    }
    
    try {
      // Wrap processing in timeout to prevent hanging
      final result = await Future.any([
        _processPainDetection(image, camera),
        Future.delayed(_processingTimeout, () {
          throw TimeoutException('Pain detection processing timeout', _processingTimeout);
        }),
      ]);
      
      return result;
    } on TimeoutException {
      debugPrint('FacialPainRecognitionService: Pain detection processing timeout after ${_processingTimeout.inSeconds}s');
      return getLastPrediction();
    } catch (e) {
      debugPrint('FacialPainRecognitionService: Error detecting facial pain: $e');
      return {
        'painLevel': 'Low',
        'confidence': 0.0,
        'prediction': 'Low',
        'error': e.toString()
      };
    }
  }

  /// Process pain detection from camera image (extracted for timeout handling)
  Future<Map<String, dynamic>> _processPainDetection(CameraImage image, CameraDescription camera) async {
    // Convert camera image to processable format
    final processedImage = await _processCameraImage(image, camera);
    
    if (processedImage == null) {
      return {
        'painLevel': 'Low',
        'confidence': 0.0,
        'prediction': 'Low',
        'error': 'Failed to process image'
      };
    }
    
    // Extract face region (simplified - in real implementation use face detection)
    final faceRegion = await _extractFaceRegion(processedImage);
    
    if (faceRegion == null) {
      return {
        'painLevel': 'Low',
        'confidence': 0.0,
        'prediction': 'Low',
        'error': 'No face detected'
      };
    }
    
    // Run pain recognition model
    final result = await _runPainRecognitionModel(faceRegion);
    
    return result;
  }
  
  /// Process camera image for model input
  Future<img.Image?> _processCameraImage(CameraImage image, CameraDescription camera) async {
    try {
      // Convert YUV420 to RGB
      final yuvBytes = _convertYUV420ToRGB(image);
      
      // Create image from bytes
      final processedImage = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: yuvBytes.buffer,
        format: img.Format.uint8,
        numChannels: 3,
      );
      
      return processedImage;
    } catch (e) {
      debugPrint('FacialPainRecognitionService: Error processing camera image: $e');
      return null;
    }
  }
  
  /// Convert YUV420 camera image to RGB
  Uint8List _convertYUV420ToRGB(CameraImage image) {
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
  
  /// Extract face region from image (simplified implementation)
  Future<img.Image?> _extractFaceRegion(img.Image image) async {
    try {
      // In a real implementation, you would use face detection (e.g., MediaPipe, OpenCV)
      // For now, we'll assume the face is in the center region
      final int faceSize = (image.width * 0.6).round();
      final int startX = (image.width - faceSize) ~/ 2;
      final int startY = (image.height - faceSize) ~/ 2;
      
      // Crop face region
      final faceRegion = img.copyCrop(
        image,
        x: startX,
        y: startY,
        width: faceSize,
        height: faceSize,
      );
      
      // Resize to model input size
      final resizedFace = img.copyResize(
        faceRegion,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.cubic,
      );
      
      return resizedFace;
    } catch (e) {
      debugPrint('FacialPainRecognitionService: Error extracting face region: $e');
      return null;
    }
  }
  
  /// Run pain recognition model
  Future<Map<String, dynamic>> _runPainRecognitionModel(img.Image faceImage) async {
    try {
      if (_painModel != null) {
        // Use actual PyTorch model
        return await _runRealPainRecognitionModel(faceImage);
      } else {
        // Fallback to simulation
        return await _runSimulatedPainRecognitionModel(faceImage);
      }
    } catch (e) {
      debugPrint('FacialPainRecognitionService: Error running pain recognition model: $e');
      return {
        'painLevel': 'Low',
        'confidence': 0.0,
        'prediction': 'Low',
        'error': e.toString()
      };
    }
  }

  /// Run actual PyTorch model inference
  /// Aligned with pain_train.py inference pattern:
  /// 1. Model outputs logits (raw scores for 3 classes)
  /// 2. Apply softmax to get probabilities
  /// 3. Use argmax to get predicted class index
  /// 4. Confidence is the probability of the predicted class
  /// 5. Map class index to label using CLASS_NAMES: ['Low', 'Moderate', 'Severe']
  Future<Map<String, dynamic>> _runRealPainRecognitionModel(img.Image faceImage) async {
    try {
      // PyTorch functionality temporarily disabled
      debugPrint('FacialPainRecognitionService: Real model inference temporarily disabled - using simulation');
      
      // TODO: When PyTorch is enabled, implement proper inference:
      // 1. Preprocess image (resize to 224x224, normalize with model metadata)
      // 2. Run model inference to get logits (List<double> of length 3)
      // 3. Apply softmax: final probabilities = _softmax(logits);
      // 4. Get predicted class: final classIndex = probabilities.indexOf(probabilities.reduce(max));
      // 5. Get confidence: final confidence = probabilities[classIndex];
      // 6. Map to label: final painLevel = _painLabels[classIndex];
      // 7. Return result with painLevel, confidence, and probabilities
      
      // Fallback to simulation since PyTorch is not available
      return await _runSimulatedPainRecognitionModel(faceImage);
    } catch (e) {
      debugPrint('FacialPainRecognitionService: Error in real model inference: $e');
      // Fallback to simulation
      return await _runSimulatedPainRecognitionModel(faceImage);
    }
  }

  /// Apply softmax to logits to get probability distribution
  /// This aligns with how the model was trained in pain_train.py
  /// Model outputs raw logits, which need softmax to convert to probabilities
  /// Implements: softmax(x_i) = exp(x_i - max(x)) / sum(exp(x_j - max(x)))
  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) {
      return [];
    }
    
    // Find max for numerical stability (prevents overflow)
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    
    // Compute exp(x_i - max) for each logit
    final expValues = logits.map((logit) {
      final shifted = logit - maxLogit;
      // Clamp to prevent overflow/underflow (exp of values > 20 or < -20 are extreme)
      final clamped = shifted.clamp(-20.0, 20.0);
      return math.exp(clamped);
    }).toList();
    
    // Compute sum of exponentials
    final sumExp = expValues.fold(0.0, (sum, exp) => sum + exp);
    
    // Normalize to get probabilities (must sum to 1.0)
    if (sumExp == 0.0 || sumExp.isInfinite || sumExp.isNaN) {
      // Fallback: uniform distribution if computation fails
      return List.filled(logits.length, 1.0 / logits.length);
    }
    
    return expValues.map((exp) => exp / sumExp).toList();
  }

  /// Run simulated pain recognition (fallback)
  /// This simulates the actual model inference pattern: logits → softmax → argmax → class + confidence
  /// Aligned with pain_train.py inference logic
  Future<Map<String, dynamic>> _runSimulatedPainRecognitionModel(img.Image? faceImage) async {
    // Simulate model inference time
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Simulate model output: generate logits for 3 classes (as the real model would)
    // Class indices: 0=Low, 1=Moderate, 2=Severe (aligned with CLASS_NAMES in training)
    final logits = _simulateModelLogits(faceImage);
    
    // Apply softmax to convert logits to probabilities (aligned with training code)
    final probabilities = _softmax(logits);
    
    // Get predicted class using argmax (aligned with pain_train.py: torch.argmax(logits, dim=1))
    int predictedClassIndex = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        predictedClassIndex = i;
      }
    }
    
    // Map class index to label (aligned with CLASS_NAMES: ['Low', 'Moderate', 'Severe'])
    final painLevel = _painLabels[predictedClassIndex];
    
    // Confidence is the probability of the predicted class (aligned with training logic)
    final confidence = probabilities[predictedClassIndex];
    
    // Update last prediction
    _lastPainConfidence = confidence;
    _lastPainPrediction = painLevel;
    
    return {
      'painLevel': painLevel,
      'confidence': confidence,
      'prediction': painLevel,
      'probabilities': probabilities, // Include full probability distribution for debugging
      'error': null
    };
  }

  /// Simulate model logits output (3 classes: Low, Moderate, Severe)
  /// In real inference, these would come from the PyTorch model
  /// This simulates the distribution patterns seen in training
  List<double> _simulateModelLogits(img.Image? faceImage) {
    // Simulate random logits based on realistic pain distribution
    // Most cases are Low pain (class 0), fewer Moderate (class 1), rare Severe (class 2)
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    
    // Simulate logits that would produce the expected class distribution
    // Higher logit value = higher probability after softmax
    double logitLow, logitModerate, logitSevere;
    
    if (random < 5) {
      // 5% chance: Severe pain (class 2 has highest logit)
      logitSevere = 2.5 + (random % 10) * 0.1;
      logitModerate = 1.0 + (random % 10) * 0.05;
      logitLow = 0.5 + (random % 10) * 0.05;
    } else if (random < 20) {
      // 15% chance: Moderate pain (class 1 has highest logit)
      logitModerate = 2.0 + (random % 10) * 0.1;
      logitLow = 1.0 + (random % 10) * 0.05;
      logitSevere = 0.5 + (random % 10) * 0.05;
    } else {
      // 80% chance: Low pain (class 0 has highest logit)
      logitLow = 2.5 + (random % 10) * 0.1;
      logitModerate = 1.0 + (random % 10) * 0.05;
      logitSevere = 0.3 + (random % 10) * 0.05;
    }
    
    // Return logits in class order: [Low, Moderate, Severe] (aligned with CLASS_NAMES)
    return [logitLow, logitModerate, logitSevere];
  }
  
  /// Check if frame should be processed based on frame rate limiting
  bool _shouldProcessFrame() {
    final now = DateTime.now();
    if (_lastProcessTime == null) {
      _lastProcessTime = now;
      return true;
    }
    
    final elapsed = now.difference(_lastProcessTime!).inMilliseconds;
    if (elapsed >= (1000 / MAX_FPS)) {
      _lastProcessTime = now;
      return true;
    }
    return false;
  }
  
  /// Get last pain prediction
  Map<String, dynamic> getLastPrediction() {
    return {
      'painLevel': _lastPainPrediction,
      'confidence': _lastPainConfidence,
      'prediction': _lastPainPrediction,
    };
  }
  
  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;
  
  /// Get pain labels
  List<String> get painLabels => _painLabels;
  
  /// Get model metadata (aligned with pain_train.py saved model structure)
  Map<String, dynamic>? get modelMetadata => _modelMetadata;
  
  /// Get normalization mean values (for image preprocessing when PyTorch is enabled)
  List<double> get normalizeMean => 
      _modelMetadata?['normalize_mean'] as List<double>? ?? _defaultNormalizeMean;
  
  /// Get normalization std values (for image preprocessing when PyTorch is enabled)
  List<double> get normalizeStd => 
      _modelMetadata?['normalize_std'] as List<double>? ?? _defaultNormalizeStd;
  
  /// Dispose resources
  void dispose() {
    _isModelLoaded = false;
    _painModel = null;
    _modelMetadata = null;
    debugPrint('FacialPainRecognitionService: Disposed');
  }
}
