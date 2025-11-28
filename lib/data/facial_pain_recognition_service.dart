import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service for facial pain recognition using PyTorch Mobile model
/// 
/// This service is aligned with the training code in pain_train.py:
/// - Model Architecture: ResNet18 (default) with 3-class output
/// - Class Order: 0=Low, 1=Moderate, 2=Severe (matches CLASS_NAMES in training)
/// - Inference Pattern: logits → softmax → argmax → class + confidence
/// - Training used PSPI-based thresholds (t1, t2) for label assignment during training,
///   but inference uses direct class prediction from model output
/// - Model outputs raw logits which must be converted to probabilities via softmax
/// - Confidence is the probability of the predicted class (not a separate metric)
/// 
/// Model Format: PyTorch Lite (.ptl) for mobile deployment via PyTorch Mobile
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
  static const String _modelAssetName = 'pain_recognition_model.ptl';
  
  // Pain labels - 3-class system (aligned with CLASS_NAMES in pain_train.py)
  // Class indices: 0=Low, 1=Moderate, 2=Severe
  static const List<String> _painLabels = ['Low', 'Moderate', 'Severe'];
  
  // Method channel for PyTorch Mobile (pain detection)
  static const MethodChannel _pytorchChannel = MethodChannel('com.pocketpt/pytorch');
  
  // Model state
  bool _isModelLoaded = false;
  double _lastPainConfidence = 0; // Always updated from real-time model output, never hardcoded
  String? _lastPainPrediction; // null indicates no valid prediction yet
  
  // Track confidence history to detect if it's stuck
  final List<double> _recentConfidences = [];
  static const int _maxConfidenceHistory = 5;
  
  String? _modelPath; // Path to PyTorch Lite model file after copying from assets
  String? _activeModelFileName;
  bool _usePyTorchMobile = false; // Whether PyTorch Mobile is available
  int _inferenceCount = 0; // Track number of successful inferences for debugging
  int _errorCount = 0; // Track number of errors for debugging
  
  // Model metadata (aligned with pain_train.py saved model structure)
  Map<String, dynamic>? _modelMetadata;
  
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
  
  /// Load the PyTorch Lite model from assets
  /// Model must be converted to .ptl format first using export_pain_to_ptl.py
  Future<void> _loadModel() async {
    try {
      const modelAssetPath = 'assets/model/${_modelAssetName}';
      
      debugPrint('FacialPainRecognitionService: Loading PyTorch Lite model from assets...');
      
      // Load model from assets and copy to temporary directory
      final byteData = await rootBundle.load(modelAssetPath);
      
      // Try to get temporary directory with multiple fallbacks
      Directory tempDir;
      try {
        tempDir = await getTemporaryDirectory();
      } catch (e1) {
        debugPrint('FacialPainRecognitionService: ⚠️ getTemporaryDirectory failed: $e1');
        try {
          // Try application documents directory as fallback
          tempDir = await getApplicationDocumentsDirectory();
          debugPrint('FacialPainRecognitionService: Using application documents directory as fallback');
        } catch (e2) {
          debugPrint('FacialPainRecognitionService: ⚠️ getApplicationDocumentsDirectory failed: $e2');
          try {
            // Try application support directory as fallback
            tempDir = await getApplicationSupportDirectory();
            debugPrint('FacialPainRecognitionService: Using application support directory as fallback');
          } catch (e3) {
            debugPrint('FacialPainRecognitionService: ⚠️ getApplicationSupportDirectory failed: $e3');
            // Last resort: try system temp (may fail on some platforms)
            try {
              tempDir = Directory.systemTemp;
              debugPrint('FacialPainRecognitionService: Using system temp directory as last resort');
            } catch (e4) {
              debugPrint('FacialPainRecognitionService: ❌ All directory options failed');
              throw Exception('Cannot get temporary directory: $e1, $e2, $e3, $e4');
            }
          }
        }
      }
      
      // Ensure directory exists
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      
      final modelFile = File('${tempDir.path}/pain_recognition_model.ptl');
      
      // Write model file with error handling
      try {
        await modelFile.writeAsBytes(byteData.buffer.asUint8List());
        debugPrint('FacialPainRecognitionService: PyTorch Lite model written to: ${modelFile.path}');
      } catch (e) {
        debugPrint('FacialPainRecognitionService: ❌ Error writing model file: $e');
        throw Exception('Cannot write model file to ${modelFile.path}: $e');
      }
      
      // Verify file was written
      if (!await modelFile.exists()) {
        throw Exception('Model file was not created at ${modelFile.path}');
      }
      
      _modelPath = modelFile.path;
      _activeModelFileName = path.basename(modelFile.path);
      debugPrint('FacialPainRecognitionService: ✅ PyTorch Lite model copied to: $_modelPath (${(await modelFile.length())} bytes)');
      
      // Initialize PyTorch Mobile module via method channel
      try {
        final result = await _pytorchChannel.invokeMethod('initialize', {
          'modelPath': _modelPath,
        });
        
        if (result != true) {
          throw Exception('PyTorch Mobile initialization returned false');
        }
        
        _usePyTorchMobile = true;
        debugPrint('FacialPainRecognitionService: ✅ PyTorch Mobile session initialized successfully - REAL model will be used');
        
        // Verify PyTorch Mobile is actually working by running a test inference
        await _verifyPyTorchMobile();
      } catch (e) {
        debugPrint('FacialPainRecognitionService: ❌ PyTorch Mobile initialization failed: $e');
        throw Exception('PyTorch Mobile method channel not available: $e');
      }
      
      // Set metadata (aligned with training defaults from pain_train.py)
      _modelMetadata = {
        'class_names': _painLabels,
        'thresholds': [1.0, 3.0], // Default PSPI thresholds (Low≤1, Moderate≤3, Severe>3)
        'image_size': _inputSize,
        'normalize_mean': _defaultNormalizeMean,
        'normalize_std': _defaultNormalizeStd,
      };
      debugPrint('FacialPainRecognitionService: Using metadata - class_names: ${_modelMetadata!['class_names']}, thresholds: ${_modelMetadata!['thresholds']}');
      
    } catch (e) {
      debugPrint('FacialPainRecognitionService: ❌ Error loading PyTorch Lite model: $e');
      // Do NOT silently fall back to simulation - throw error instead
      debugPrint('FacialPainRecognitionService: ⚠️ PyTorch Mobile not available - pain detection will fail');
      _usePyTorchMobile = false;
      _activeModelFileName = _modelAssetName;
      _modelMetadata = {
        'class_names': _painLabels,
        'thresholds': [1.0, 3.0],
        'image_size': _inputSize,
        'normalize_mean': _defaultNormalizeMean,
        'normalize_std': _defaultNormalizeStd,
      };
      // Re-throw to let caller know initialization failed
      rethrow;
    }
  }
  
  /// Verify PyTorch Mobile is actually working by running a test inference
  Future<void> _verifyPyTorchMobile() async {
    try {
      debugPrint('FacialPainRecognitionService: Verifying PyTorch Mobile with test inference...');
      
      // Create a dummy test image (224x224 RGB)
      final testImage = img.Image(width: _inputSize, height: _inputSize, numChannels: 3);
      final testPreprocessed = _preprocessImageForPyTorch(testImage);
      
      debugPrint('FacialPainRecognitionService: Test input size: ${testPreprocessed.length}, expected: ${_inputSize * _inputSize * 3}');
      
      // Run a test inference
      final testResult = await _pytorchChannel.invokeMethod('run', {
        'modelPath': _modelPath, // Pass model path to identify which model to use
        'input': testPreprocessed,
        'inputShape': [1, 3, _inputSize, _inputSize],
      });
      
      if (testResult != null && testResult is List && testResult.isNotEmpty) {
        debugPrint('FacialPainRecognitionService: ✅ PyTorch Mobile verification successful - test inference returned ${testResult.length} values');
        debugPrint('FacialPainRecognitionService: Test output values: ${testResult.take(3).toList()}');
        
        // Verify output has at least 3 values (for 3 classes)
        if (testResult.length >= 3) {
          debugPrint('FacialPainRecognitionService: ✅ Output shape verified: ${testResult.length} values (expected at least 3)');
        } else {
          debugPrint('FacialPainRecognitionService: ⚠️ Output has insufficient values: ${testResult.length}, expected at least 3');
        }
      } else {
        debugPrint('FacialPainRecognitionService: ⚠️ PyTorch Mobile verification failed - test inference returned null or empty');
        throw Exception('PyTorch Mobile test inference returned null or empty');
      }
    } catch (e) {
      debugPrint('FacialPainRecognitionService: ⚠️ PyTorch Mobile verification failed: $e');
      // Re-throw to prevent initialization if verification fails
      rethrow;
    }
  }
  
  /// Detect facial pain from camera image with real-time inference
  /// Note: Frame rate limiting is handled by the caller (camera view), so this always processes the frame
  Future<Map<String, dynamic>> detectFacialPain({
    CameraImage? image,
    required CameraDescription camera,
  }) async {
    if (!_isModelLoaded) {
      debugPrint('FacialPainRecognitionService: ❌ Model not loaded - returning error (no hardcoded value)');
      return {
        'painLevel': _lastPainPrediction, // Use last known value if available, null otherwise
        'confidence': _lastPainConfidence,
        'prediction': _lastPainPrediction,
        'error': 'Model not loaded'
      };
    }
    
    // REMOVED: Frame rate limiting removed - caller (camera view) already handles frame rate limiting
    // This ensures real-time detection on every frame that passes through the camera view's frame rate limiter
    
    // If image is null, we can't process - return error
    if (image == null) {
      debugPrint('FacialPainRecognitionService: Image is null, cannot process');
      return {
        'painLevel': _lastPainPrediction,
        'confidence': _lastPainConfidence,
        'prediction': _lastPainPrediction,
        'error': 'Image is null'
      };
    }
    
    try {
      debugPrint('FacialPainRecognitionService: 🔄 Processing new frame for pain detection');
      debugPrint('FacialPainRecognitionService: PyTorch Mobile status: $_usePyTorchMobile, Model path: $_modelPath');
      debugPrint('FacialPainRecognitionService: Model labels (aligned with pain_train.py): $_painLabels');
      debugPrint('FacialPainRecognitionService: Expected output classes: 0=Low, 1=Moderate, 2=Severe');
      
      // Wrap processing in timeout to prevent hanging
      final result = await Future.any([
        _processPainDetection(image, camera),
        Future.delayed(_processingTimeout, () {
          throw TimeoutException('Pain detection processing timeout', _processingTimeout);
        }),
      ]);
      
      // Log result for debugging
      if (result['error'] != null) {
        debugPrint('FacialPainRecognitionService: ⚠️ Pain detection returned error: ${result['error']}');
        debugPrint('FacialPainRecognitionService: Returning last known values - Level: ${result['painLevel']}, Confidence: ${result['confidence']}');
      } else {
        debugPrint('FacialPainRecognitionService: ✅ Pain detection successful - Level: ${result['painLevel']}, Confidence: ${result['confidence']}');
        // Update last prediction when successful
        _lastPainPrediction = result['painLevel'] as String? ?? _lastPainPrediction;
        _lastPainConfidence = (result['confidence'] as num?)?.toDouble() ?? _lastPainConfidence;
      }
      
      return result;
    } on TimeoutException {
      debugPrint('FacialPainRecognitionService: Pain detection processing timeout after ${_processingTimeout.inSeconds}s');
      return getLastPrediction();
    } catch (e, stackTrace) {
      debugPrint('FacialPainRecognitionService: Error detecting facial pain: $e');
      debugPrint('FacialPainRecognitionService: Stack trace: $stackTrace');
      return {
        'painLevel': _lastPainPrediction,
        'confidence': _lastPainConfidence,
        'prediction': _lastPainPrediction,
        'error': e.toString()
      };
    }
  }

  /// Process pain detection from camera image (extracted for timeout handling)
  Future<Map<String, dynamic>> _processPainDetection(CameraImage image, CameraDescription camera) async {
    // Convert camera image to processable format
    final processedImage = await _processCameraImage(image, camera);
    
    if (processedImage == null) {
      debugPrint('FacialPainRecognitionService: ❌ Failed to process image - returning error (no hardcoded value)');
      return {
        'painLevel': _lastPainPrediction, // Use last known value if available, null otherwise
        'confidence': _lastPainConfidence,
        'prediction': _lastPainPrediction,
        'error': 'Failed to process image'
      };
    }
    
    // Extract face region - uses center crop with automatic fallback
    final faceRegion = await _extractFaceRegion(processedImage);
    
    // Final fallback: if face extraction completely failed, use full image
    if (faceRegion == null) {
      debugPrint('FacialPainRecognitionService: ⚠️ Face extraction returned null, using full image as final fallback');
      final fullImageResized = img.copyResize(
        processedImage,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.cubic,
      );
      
      // Ensure RGB format
      if (fullImageResized.numChannels != 3) {
        final converted = img.Image(width: _inputSize, height: _inputSize, numChannels: 3);
        for (int y = 0; y < _inputSize; y++) {
          for (int x = 0; x < _inputSize; x++) {
            final srcPixel = fullImageResized.getPixel(x, y);
            converted.setPixelRgba(x, y, srcPixel.r, srcPixel.g, srcPixel.b, 255);
          }
        }
        debugPrint('FacialPainRecognitionService: Using full image converted to RGB as final fallback');
        // Continue with converted image below
        final result = await _runPainRecognitionModel(converted);
        return result;
      }
      
      debugPrint('FacialPainRecognitionService: Using full image (${processedImage.width}x${processedImage.height}) resized to $_inputSize x $_inputSize as final fallback');
      final result = await _runPainRecognitionModel(fullImageResized);
      return result;
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
  /// Fixed to properly handle row strides for all planes
  Uint8List _convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    
    // Get plane information
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    
    final int yRowStride = yPlane.bytesPerRow;
    final int yPixelStride = yPlane.bytesPerPixel ?? 1;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;
    
    final Uint8List rgb = Uint8List(width * height * 3);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Calculate Y plane index (accounting for row stride)
        final int yIndex = (y * yRowStride) + (x * yPixelStride);
        
        // Calculate UV plane indices (UV is subsampled by 2x2)
        final int uvY = y ~/ 2;
        final int uvX = x ~/ 2;
        final int uvIndex = (uvY * uvRowStride) + (uvX * uvPixelStride);
        
        // Ensure indices are within bounds
        if (yIndex >= yPlane.bytes.length) continue;
        if (uvIndex >= uPlane.bytes.length || uvIndex >= vPlane.bytes.length) continue;
        
        final int yValue = yPlane.bytes[yIndex];
        final int uValue = uPlane.bytes[uvIndex];
        final int vValue = vPlane.bytes[uvIndex];
        
        // YUV to RGB conversion (ITU-R BT.601)
        // Convert YUV values from 0-255 range to normalized values
        final double yNorm = (yValue - 16) / 219.0;
        final double uNorm = (uValue - 128) / 224.0;
        final double vNorm = (vValue - 128) / 224.0;
        
        // Convert to RGB
        int r = ((yNorm + 1.402 * vNorm) * 255).round().clamp(0, 255);
        int g = ((yNorm - 0.344136 * uNorm - 0.714136 * vNorm) * 255).round().clamp(0, 255);
        int b = ((yNorm + 1.772 * uNorm) * 255).round().clamp(0, 255);
        
        // Store RGB values
        final int rgbIndex = (y * width + x) * 3;
        if (rgbIndex + 2 < rgb.length) {
          rgb[rgbIndex] = r;
          rgb[rgbIndex + 1] = g;
          rgb[rgbIndex + 2] = b;
        }
      }
    }
    
    return rgb;
  }
  
  /// Extract face region from image (improved implementation)
  /// Uses center crop with multiple fallback strategies to ensure model always gets valid input
  Future<img.Image?> _extractFaceRegion(img.Image image) async {
    try {
      final int imageWidth = image.width;
      final int imageHeight = image.height;
      
      debugPrint('FacialPainRecognitionService: Extracting face region from ${imageWidth}x${imageHeight} image');
      
      // Strategy: Use center region that's 50-70% of the smaller dimension
      // This works well for selfie/front-facing camera where face is typically centered
      final int smallerDim = math.min(imageWidth, imageHeight);
      final double faceRatio = 0.6; // Use 60% of smaller dimension
      int cropSize = (smallerDim * faceRatio).round();
      
      // Ensure crop size is at least model input size but not larger than image
      cropSize = cropSize.clamp(_inputSize, smallerDim);
      
      // Calculate center crop region
      int startX = (imageWidth - cropSize) ~/ 2;
      int startY = (imageHeight - cropSize) ~/ 2;
      
      // Clamp to image bounds
      startX = startX.clamp(0, imageWidth - 1);
      startY = startY.clamp(0, imageHeight - 1);
      
      // Adjust crop size if it would exceed image bounds
      final int maxCropWidth = imageWidth - startX;
      final int maxCropHeight = imageHeight - startY;
      final int actualCropWidth = math.min(cropSize, maxCropWidth);
      final int actualCropHeight = math.min(cropSize, maxCropHeight);
      
      img.Image? faceRegion;
      
      // Try to crop center region
      if (actualCropWidth >= _inputSize && actualCropHeight >= _inputSize) {
        faceRegion = img.copyCrop(
          image,
          x: startX,
          y: startY,
          width: actualCropWidth,
          height: actualCropHeight,
        );
        debugPrint('FacialPainRecognitionService: Cropped center region ${actualCropWidth}x${actualCropHeight} from position ($startX, $startY)');
      } else {
        // Fallback: use full image if crop is too small
        debugPrint('FacialPainRecognitionService: Crop too small, using full image as fallback');
        faceRegion = image;
      }
      
      // Always resize to model input size
      // At this point, faceRegion cannot be null due to earlier checks
      final resizedFace = img.copyResize(
        faceRegion,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.cubic,
      );
      
      debugPrint('FacialPainRecognitionService: Resized face region to $_inputSize x $_inputSize');
      
      // Ensure image has 3 channels (RGB)
      if (resizedFace.numChannels != 3) {
        debugPrint('FacialPainRecognitionService: Converting from ${resizedFace.numChannels} channels to 3 channels (RGB)');
        final converted = img.Image(width: resizedFace.width, height: resizedFace.height, numChannels: 3);
        for (int y = 0; y < resizedFace.height; y++) {
          for (int x = 0; x < resizedFace.width; x++) {
            final srcPixel = resizedFace.getPixel(x, y);
            converted.setPixelRgba(x, y, srcPixel.r, srcPixel.g, srcPixel.b, 255);
          }
        }
        return converted;
      }
      
      return resizedFace;
    } catch (e, stackTrace) {
      debugPrint('FacialPainRecognitionService: ❌ Error extracting face region: $e');
      debugPrint('FacialPainRecognitionService: Stack trace: $stackTrace');
      // Return null and let caller handle fallback
      return null;
    }
  }
  
  /// Run pain recognition model
  Future<Map<String, dynamic>> _runPainRecognitionModel(img.Image faceImage) async {
    try {
      if (_usePyTorchMobile) {
        // Use actual PyTorch Mobile model
        debugPrint('FacialPainRecognitionService: Using REAL PyTorch Mobile model for inference');
        return await _runPyTorchInference(faceImage);
      } else {
        // PyTorch Mobile not available - return error
        debugPrint('FacialPainRecognitionService: ❌ PyTorch Mobile not available - cannot perform inference');
        return {
          'painLevel': _lastPainPrediction,
          'confidence': _lastPainConfidence,
          'prediction': _lastPainPrediction,
          'error': 'PyTorch Mobile not available'
        };
      }
    } catch (e) {
      debugPrint('FacialPainRecognitionService: Error running pain recognition model: $e');
      return {
        'painLevel': _lastPainPrediction,
        'confidence': _lastPainConfidence,
        'prediction': _lastPainPrediction,
        'error': e.toString()
      };
    }
  }

  /// Run PyTorch Mobile model inference
  /// Aligned with pain_train.py inference pattern:
  /// 1. Preprocess image (resize to 224x224, normalize with model metadata)
  /// 2. Model outputs logits (raw scores for 3 classes)
  /// 3. Apply softmax to get probabilities
  /// 4. Use argmax to get predicted class index
  /// 5. Confidence is the probability of the predicted class
  /// 6. Map class index to label using CLASS_NAMES: ['Low', 'Moderate', 'Severe']
  Future<Map<String, dynamic>> _runPyTorchInference(img.Image faceImage) async {
    try {
      if (!_usePyTorchMobile) {
        debugPrint('FacialPainRecognitionService: ❌ PyTorch Mobile not initialized');
        return {
          'painLevel': _lastPainPrediction,
          'confidence': _lastPainConfidence,
          'prediction': _lastPainPrediction,
          'error': 'PyTorch Mobile not initialized',
        };
      }
      
      // Validate input image
      if (faceImage.width != _inputSize || faceImage.height != _inputSize) {
        debugPrint('FacialPainRecognitionService: ⚠️ Input image size mismatch: ${faceImage.width}x${faceImage.height}, expected ${_inputSize}x${_inputSize}');
        // Resize to correct size
        faceImage = img.copyResize(faceImage, width: _inputSize, height: _inputSize);
      }
      
      // 1. Preprocess image: resize to 224x224 and normalize
      final preprocessedImage = _preprocessImageForPyTorch(faceImage);
      
      if (preprocessedImage.length != _inputSize * _inputSize * 3) {
        debugPrint('FacialPainRecognitionService: ❌ Preprocessed image size mismatch: ${preprocessedImage.length}, expected ${_inputSize * _inputSize * 3}');
        throw Exception('Preprocessing failed: incorrect output size');
      }
      
      // Log sample of preprocessed input to verify it's varying
      // preprocessedImage is Float32List, access directly
      final sampleStart = preprocessedImage.sublist(0, math.min(10, preprocessedImage.length));
      final sampleMid = preprocessedImage.sublist(
        math.min(preprocessedImage.length ~/ 2, preprocessedImage.length - 10),
        math.min(preprocessedImage.length ~/ 2 + 10, preprocessedImage.length)
      );
      final sampleEnd = preprocessedImage.sublist(
        math.max(0, preprocessedImage.length - 10),
        preprocessedImage.length
      );
      debugPrint('FacialPainRecognitionService: Preprocessed input sample (start): ${sampleStart.map((v) => v.toStringAsFixed(3)).join(", ")}');
      debugPrint('FacialPainRecognitionService: Preprocessed input sample (mid): ${sampleMid.map((v) => v.toStringAsFixed(3)).join(", ")}');
      debugPrint('FacialPainRecognitionService: Preprocessed input sample (end): ${sampleEnd.map((v) => v.toStringAsFixed(3)).join(", ")}');
      
      // DIAGNOSTIC: Check if preprocessed input is all zeros or constant
      final inputAllZeros = preprocessedImage.every((v) => v.abs() < 0.001);
      final inputAllSame = preprocessedImage.every((v) => (v - preprocessedImage[0]).abs() < 0.001);
      if (inputAllZeros) {
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - Preprocessed input is all zeros! This will cause model to fail.');
      } else if (inputAllSame) {
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - Preprocessed input is constant (all values ≈ ${preprocessedImage[0].toStringAsFixed(3)})! This will cause model to always predict the same class.');
      } else {
        final minVal = preprocessedImage.reduce((a, b) => a < b ? a : b);
        final maxVal = preprocessedImage.reduce((a, b) => a > b ? a : b);
        debugPrint('FacialPainRecognitionService: ✅ Preprocessed input varies: min=${minVal.toStringAsFixed(3)}, max=${maxVal.toStringAsFixed(3)}');
      }
      
      debugPrint('FacialPainRecognitionService: 🔄 Running REAL-TIME PyTorch Mobile inference (aligned with pain_train.py)');
      debugPrint('FacialPainRecognitionService: Input shape: [1, 3, $_inputSize, $_inputSize] (matches training: 224x224 RGB)');
      debugPrint('FacialPainRecognitionService: Normalization: mean=[${normalizeMean.join(", ")}], std=[${normalizeStd.join(", ")}] (matches pain_train.py)');
      debugPrint('FacialPainRecognitionService: Preprocessed input length: ${preprocessedImage.length}, expected: ${_inputSize * _inputSize * 3}');
      
      // 2. Run inference via method channel - THIS IS THE ACTUAL MODEL CALL
      final inferenceStartTime = DateTime.now();
      final result = await _pytorchChannel.invokeMethod('run', {
        'modelPath': _modelPath, // Pass model path to identify which model to use
        'input': preprocessedImage,
        'inputShape': [1, 3, _inputSize, _inputSize],
      });
      final inferenceDuration = DateTime.now().difference(inferenceStartTime);
      debugPrint('FacialPainRecognitionService: ✅ REAL-TIME inference completed in ${inferenceDuration.inMilliseconds}ms');
      
      if (result == null) {
        debugPrint('FacialPainRecognitionService: ❌ PyTorch Mobile returned null output');
        // Don't fall back to simulation - return error instead
        return {
          'painLevel': _lastPainPrediction,
          'confidence': _lastPainConfidence,
          'prediction': _lastPainPrediction,
          'error': 'PyTorch Mobile returned null output',
        };
      }
      
      debugPrint('FacialPainRecognitionService: ✅ PyTorch Mobile inference successful - processing real model output');
      debugPrint('FacialPainRecognitionService: Output type: ${result.runtimeType}, length: ${result is List ? result.length : 'N/A'}');
      
      // 3. Extract logits from output (List<double>)
      // PyTorch model output shape is [1, 3] which is flattened to 3 values by native code
      List outputData;
      if (result is List) {
        outputData = result;
        debugPrint('FacialPainRecognitionService: ✅ Received List output with ${outputData.length} values');
        // Log all raw values for debugging
        if (outputData.isNotEmpty) {
          final rawValues = outputData.take(10).map((v) => v.toStringAsFixed(6)).join(', ');
          debugPrint('FacialPainRecognitionService: Raw output values (first 10): [$rawValues]');
        }
      } else if (result is Map && result.containsKey('output')) {
        // Handle case where native code returns wrapped output
        outputData = result['output'] as List;
        debugPrint('FacialPainRecognitionService: ✅ Received Map output with wrapped list of ${outputData.length} values');
      } else {
        debugPrint('FacialPainRecognitionService: ❌ Unexpected output format: ${result.runtimeType}');
        debugPrint('FacialPainRecognitionService: ❌ Output value: $result');
        throw Exception('Unexpected output format from PyTorch Mobile: ${result.runtimeType}');
      }
      
      debugPrint('FacialPainRecognitionService: Raw output data length: ${outputData.length}');
      debugPrint('FacialPainRecognitionService: Expected: 3 values (logits for Low, Moderate, Severe)');
      
      // Extract logits - handle both [1, 3] and [3] output shapes
      // PyTorch model output shape is [1, 3] which is flattened to 3 values by native code
      final logits = <double>[];
      
      // If output is [1, 3] shape (flattened to 3 values), extract all 3
      // If output has more values, take first 3 (shouldn't happen but handle gracefully)
      if (outputData.length >= 3) {
        // Extract first 3 values as logits
        for (int i = 0; i < 3; i++) {
          final value = outputData[i];
          if (value is num) {
            logits.add(value.toDouble());
          } else {
            debugPrint('FacialPainRecognitionService: ⚠️ Unexpected value type at index $i: ${value.runtimeType}, value: $value');
            logits.add(0.0);
          }
        }
        
        // Log if output has more than 3 values (unexpected but not fatal)
        if (outputData.length > 3) {
          debugPrint('FacialPainRecognitionService: ⚠️ Output has ${outputData.length} values, expected 3. Using first 3 values.');
        }
      } else {
        // Output has fewer than 3 values - this is an error
        debugPrint('FacialPainRecognitionService: ❌ Output has insufficient values: ${outputData.length}, expected at least 3');
        // Extract what we have and pad with zeros
        for (int i = 0; i < outputData.length; i++) {
          final value = outputData[i];
          if (value is num) {
            logits.add(value.toDouble());
          } else {
            logits.add(0.0);
          }
        }
        // Pad to 3 values
        while (logits.length < 3) {
          logits.add(0.0);
        }
      }
      
      debugPrint('FacialPainRecognitionService: ✅ Extracted logits: [${logits[0].toStringAsFixed(6)}, ${logits[1].toStringAsFixed(6)}, ${logits[2].toStringAsFixed(6)}]');
      debugPrint('FacialPainRecognitionService: Logits interpretation: Low=${logits[0].toStringAsFixed(3)}, Moderate=${logits[1].toStringAsFixed(3)}, Severe=${logits[2].toStringAsFixed(3)}');
      
      // Check if logits are all the same (indicates model might be stuck)
      final allSame = logits.every((logit) => (logit - logits[0]).abs() < 0.001);
      if (allSame) {
        debugPrint('FacialPainRecognitionService: ⚠️ WARNING - All logits are nearly identical (${logits[0].toStringAsFixed(6)})! This suggests model output is not varying.');
        debugPrint('FacialPainRecognitionService: ⚠️ This could indicate:');
        debugPrint('    1. Model always receives same/similar input');
        debugPrint('    2. Model weights not loaded correctly');
        debugPrint('    3. Preprocessing issue (all zeros/constant values)');
      }
      
      // Check if logits have reasonable range (not all zeros or extreme values)
      final maxLogit = logits.reduce((a, b) => a > b ? a : b);
      final minLogit = logits.reduce((a, b) => a < b ? a : b);
      final logitRange = maxLogit - minLogit;
      debugPrint('FacialPainRecognitionService: Logit range: min=${minLogit.toStringAsFixed(3)}, max=${maxLogit.toStringAsFixed(3)}, range=${logitRange.toStringAsFixed(3)}');
      
      if (logitRange < 0.1) {
        debugPrint('FacialPainRecognitionService: ⚠️ WARNING - Logits have very small range (<0.1), model predictions will be uncertain');
      }
      
      if (maxLogit.abs() > 100 || minLogit.abs() > 100) {
        debugPrint('FacialPainRecognitionService: ⚠️ WARNING - Logits have extreme values (>100), this might cause numerical instability');
      }
      
      // 4. Apply softmax to convert logits to probabilities
      final probabilities = _softmax(logits);
      
      debugPrint('FacialPainRecognitionService: Probabilities: [${probabilities[0].toStringAsFixed(3)}, ${probabilities[1].toStringAsFixed(3)}, ${probabilities[2].toStringAsFixed(3)}]');
      
      // Check if probabilities are all the same (indicates softmax issue or stuck model)
      final probsAllSame = probabilities.every((prob) => (prob - probabilities[0]).abs() < 0.001);
      if (probsAllSame) {
        debugPrint('FacialPainRecognitionService: ⚠️ WARNING - All probabilities are nearly identical! This suggests model is stuck or softmax issue.');
        debugPrint('FacialPainRecognitionService: ⚠️ All probabilities ≈ ${probabilities[0].toStringAsFixed(3)}');
      }
      
      // 5. Get predicted class using argmax
      int predictedClassIndex = 0;
      double maxProb = probabilities[0];
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          predictedClassIndex = i;
        }
      }
      
      // 6. Map class index to label
      if (predictedClassIndex >= _painLabels.length) {
        debugPrint('FacialPainRecognitionService: ⚠️ Predicted class index $predictedClassIndex out of bounds, using 0');
        predictedClassIndex = 0;
      }
      
      final painLevel = _painLabels[predictedClassIndex];
      final confidence = probabilities[predictedClassIndex];
      
      // CRITICAL: Ensure confidence comes from REAL-TIME model output, not cached
      // Confidence is the probability of the predicted class from the current frame's inference
      // This should vary between frames as facial expressions change
      
      // Update last prediction ONLY when we have a valid model output from REAL-TIME inference
      // This ensures each processed frame updates the pain level and confidence (not cached)
      final painLevelChanged = _lastPainPrediction != painLevel;
      final confidenceChanged = _lastPainConfidence == 0 || (_lastPainConfidence - confidence).abs() > 0.001; // Changed if difference > 0.1%
      
      // Track confidence history to detect stuck values
      _recentConfidences.add(confidence);
      if (_recentConfidences.length > _maxConfidenceHistory) {
        _recentConfidences.removeAt(0);
      }
      
      // Check if confidence is stuck (all recent values are nearly identical)
      bool confidenceIsStuck = false;
      if (_recentConfidences.length >= 3) {
        final avgConfidence = _recentConfidences.reduce((a, b) => a + b) / _recentConfidences.length;
        confidenceIsStuck = _recentConfidences.every((c) => (c - avgConfidence).abs() < 0.001);
      }
      
      _lastPainConfidence = confidence;
      _lastPainPrediction = painLevel;
      
      _inferenceCount++;
      debugPrint('FacialPainRecognitionService: ✅ REAL-TIME model prediction #$_inferenceCount - Pain: $painLevel (${painLevelChanged ? "CHANGED" : "same"}), Confidence: ${(confidence * 100).toStringAsFixed(1)}% (${confidenceChanged ? "CHANGED" : "same"})');
      debugPrint('FacialPainRecognitionService: ✅ Probabilities: Low=${(probabilities[0] * 100).toStringAsFixed(1)}%, Moderate=${(probabilities[1] * 100).toStringAsFixed(1)}%, Severe=${(probabilities[2] * 100).toStringAsFixed(1)}%');
      debugPrint('FacialPainRecognitionService: ✅ Class mapping: Index $predictedClassIndex -> "${_painLabels[predictedClassIndex]}" (matches pain_train.py: 0=Low, 1=Moderate, 2=Severe)');
      debugPrint('FacialPainRecognitionService: ✅ Confidence source: REAL-TIME model output (probability of predicted class), value: ${confidence.toStringAsFixed(6)}');
      
      // Log summary statistics periodically
      if (_inferenceCount % 10 == 0) {
        debugPrint('FacialPainRecognitionService: 📊 Statistics - Successful inferences: $_inferenceCount, Errors: $_errorCount');
        debugPrint('FacialPainRecognitionService: 📊 Last prediction: $_lastPainPrediction (confidence: ${(_lastPainConfidence * 100).toStringAsFixed(1)}%)');
        debugPrint('FacialPainRecognitionService: 📊 Confidence variation check - Current: ${(confidence * 100).toStringAsFixed(2)}%, Previous: ${(_lastPainConfidence * 100).toStringAsFixed(2)}%');
      }
      
      // DIAGNOSTIC: Check if confidence is stuck at the same value
      if (confidenceIsStuck && _inferenceCount > 3) {
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - Confidence stuck at ${(confidence * 100).toStringAsFixed(1)}% for multiple frames');
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - Recent confidence values: ${_recentConfidences.map((c) => (c * 100).toStringAsFixed(1)).join(", ")}%');
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - This indicates model is receiving similar inputs or outputting similar predictions');
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - Check: 1) Face extraction varies, 2) Model logits vary, 3) Preprocessing produces different inputs');
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - Model logits: [${logits[0].toStringAsFixed(3)}, ${logits[1].toStringAsFixed(3)}, ${logits[2].toStringAsFixed(3)}]');
      }
      
      // DIAGNOSTIC: Check if model predictions are varying
      if (!painLevelChanged && _inferenceCount > 5) {
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - Model predicting same level "$painLevel" for ${_inferenceCount} consecutive frames');
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - Current probabilities: Low=${(probabilities[0] * 100).toStringAsFixed(1)}%, Moderate=${(probabilities[1] * 100).toStringAsFixed(1)}%, Severe=${(probabilities[2] * 100).toStringAsFixed(1)}%');
      }
      
      // DIAGNOSTIC: Check if model is stuck at a specific class
      if (predictedClassIndex == 0 && probabilities[0] > 0.8) {
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - Model consistently predicting Low with high confidence (${(probabilities[0] * 100).toStringAsFixed(1)}%)');
        debugPrint('FacialPainRecognitionService: ⚠️ DIAGNOSTIC - This may indicate:');
        debugPrint('   1. Model always receiving similar input (face extraction issue?)');
        debugPrint('   2. Preprocessing issue (normalization, resize, channel order)');
        debugPrint('   3. Model not properly loaded or using wrong weights');
        debugPrint('   4. Input image quality/lighting issues');
      }
      
      // Validate that pain level is one of the expected values
      if (!_painLabels.contains(painLevel)) {
        debugPrint('FacialPainRecognitionService: ❌ ERROR - Invalid pain level "$painLevel" not in expected labels: $_painLabels');
      }
      
      return {
        'painLevel': painLevel,
        'confidence': confidence,
        'prediction': painLevel,
        'probabilities': probabilities,
        'error': null,
        'isRealTime': true, // Flag to indicate this is real model output, not cached
      };
      
    } catch (e, stackTrace) {
      _errorCount++;
      debugPrint('FacialPainRecognitionService: ❌ Error in PyTorch Mobile inference #$_errorCount: $e');
      debugPrint('FacialPainRecognitionService: Stack trace: $stackTrace');
      
      // Log error summary periodically
      if (_errorCount % 5 == 0) {
        debugPrint('FacialPainRecognitionService: ⚠️ Error summary - Successful inferences: $_inferenceCount, Errors: $_errorCount');
        debugPrint('FacialPainRecognitionService: ⚠️ Last successful prediction: $_lastPainPrediction (confidence: ${(_lastPainConfidence * 100).toStringAsFixed(1)}%)');
      }
      
      // Don't fall back to simulation - return error with last known values
      return {
        'painLevel': _lastPainPrediction,
        'confidence': _lastPainConfidence,
        'prediction': _lastPainPrediction,
        'error': e.toString(),
      };
    }
  }
  
  /// Preprocess image for PyTorch model input
  /// Converts img.Image to Float32List in NCHW format (batch=1, channels=3, height=224, width=224)
  /// Fixed to ensure proper channel ordering and normalization
  /// Returns Float32List to match pose model pattern and ensure correct type for method channel
  Float32List _preprocessImageForPyTorch(img.Image image) {
    // Ensure image is RGB with 3 channels
    img.Image resizedImage;
    if (image.numChannels != 3) {
      debugPrint('FacialPainRecognitionService: Converting image from ${image.numChannels} channels to 3 channels');
      // Create new RGB image and copy pixels
      final converted = img.Image(width: image.width, height: image.height, numChannels: 3);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final srcPixel = image.getPixel(x, y);
          converted.setPixelRgba(x, y, srcPixel.r, srcPixel.g, srcPixel.b, 255);
        }
      }
      resizedImage = converted;
    } else {
      resizedImage = image;
    }
    
    // Resize to model input size if needed
    if (resizedImage.width != _inputSize || resizedImage.height != _inputSize) {
      resizedImage = img.copyResize(
        resizedImage,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.cubic,
      );
    }
    
    // Normalize and convert to float32 tensor format [N, C, H, W] = [1, 3, 224, 224]
    // ImageNet normalization: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
    final mean = normalizeMean;
    final std = normalizeStd;
    
    final float32Data = Float32List(_inputSize * _inputSize * 3);
    int index = 0;
    
    // Convert to NCHW format (channel first)
    // Order: [R channel all pixels, G channel all pixels, B channel all pixels]
    for (int c = 0; c < 3; c++) { // Channels: R, G, B
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          
          // Get channel value (0=R, 1=G, 2=B)
          int channelValue;
          if (c == 0) {
            channelValue = pixel.r.toInt();
          } else if (c == 1) {
            channelValue = pixel.g.toInt();
          } else {
            channelValue = pixel.b.toInt();
          }
          
          // Normalize: (pixel / 255.0 - mean) / std
          // This matches PyTorch's transforms.Normalize(mean, std)
          // Formula: normalized = (pixel / 255.0 - mean) / std
          final normalized = (channelValue / 255.0 - mean[c]) / std[c];
          
          // Clamp to reasonable range to prevent extreme values
          final clamped = normalized.clamp(-10.0, 10.0);
          float32Data[index++] = clamped;
        }
      }
    }
    
    // Return Float32List directly (same as pose model pattern)
    // Flutter method channel will automatically convert Float32List to FloatArray in Kotlin
    return float32Data;
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

  /// Check if frame should be processed based on frame rate limiting
  /// Get last pain prediction (may be null if no valid prediction yet)
  /// Note: This is only used for error fallback cases, not for frame skipping
  Map<String, dynamic> getLastPrediction() {
    return {
      'painLevel': _lastPainPrediction, // May be null if no valid prediction
      'confidence': _lastPainConfidence,
      'prediction': _lastPainPrediction,
      'isRealTime': false, // Flag to indicate this is cached, not real-time
    };
  }
  
  /// Whether PyTorch Mobile completed initialization and model file is available
  bool get isPyTorchReady => _usePyTorchMobile && _modelPath != null;

  /// Whether the service is relying on the simulated fallback instead of PyTorch Mobile
  bool get usesFallbackMode => !_usePyTorchMobile;

  /// Name of the current PyTorch Lite model derived from asset or temp path
  String get activeModelDisplayName => _activeModelFileName ?? _modelAssetName;

  /// Expose whether the native PyTorch Mobile is enabled
  bool get isPyTorchEnabled => _usePyTorchMobile;
  
  // Legacy getters for backward compatibility (deprecated - use PyTorch getters instead)
  @Deprecated('Use isPyTorchReady instead')
  bool get isOnnxReady => isPyTorchReady;
  
  @Deprecated('Use isPyTorchEnabled instead')
  bool get isOnnxEnabled => isPyTorchEnabled;

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
  Future<void> dispose() async {
    // Dispose PyTorch Mobile session before clearing state
    if (_usePyTorchMobile && _modelPath != null) {
      try {
        await _pytorchChannel.invokeMethod('dispose', {
          'modelPath': _modelPath, // Pass model path to dispose specific model
        });
        debugPrint('FacialPainRecognitionService: PyTorch Mobile session disposed');
      } catch (e) {
        debugPrint('FacialPainRecognitionService: Error disposing PyTorch Mobile session: $e');
      }
    }
    
    _isModelLoaded = false;
    _usePyTorchMobile = false;
    _modelMetadata = null;
    _activeModelFileName = null;
    
    // Clean up temporary model file
    if (_modelPath != null) {
      try {
        final file = File(_modelPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('FacialPainRecognitionService: Error deleting model file: $e');
      }
      _modelPath = null;
    }
    
    debugPrint('FacialPainRecognitionService: Disposed');
  }
}
