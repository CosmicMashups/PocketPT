import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'pose_diagnostics.dart';

/// Manages the pose estimation model loading and inference
/// 
/// This class handles the custom pose estimation model (pose_estimation_model.pt)
/// which is a YOLO11s-pose model trained with Ultralytics.
/// 
/// Uses ONNX Runtime for model inference.
/// 
/// Model specifications:
/// - Input size: 320x320 pixels (RGB format)
/// - Output: 17 COCO format keypoints [x, y, confidence]
/// - Keypoints order: nose, leftEye, rightEye, leftEar, rightEar,
///   leftShoulder, rightShoulder, leftElbow, rightElbow,
///   leftWrist, rightWrist, leftHip, rightHip,
///   leftKnee, rightKnee, leftAnkle, rightAnkle
class PoseModelManager {
  static PoseModelManager? _instance;
  static PoseModelManager get instance => _instance ??= PoseModelManager._internal();
  
  PoseModelManager._internal();
  
  // Model configuration based on pose_train.py
  static const int modelInputSize = 320; // From training config: imgsz=320
  static const int numKeypoints = 17; // COCO format keypoints
  static const int paddingValue = 114;
  static const double minDetectionConfidence = 0.25;
  
  // Method channel for PyTorch Mobile
  static const MethodChannel _pytorchChannel = MethodChannel('com.pocketpt/pytorch');
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _modelPath; // Path to model file after copying from assets
  bool _usePyTorch = false; // Whether PyTorch Mobile is available
  
  /// Check if the model is initialized
  bool get isInitialized => _isInitialized;
  
  /// Check if the model is currently loading
  bool get isLoading => _isLoading;
  
  /// Get any error message from initialization
  String? get errorMessage => _errorMessage;
  
  /// Initialize the pose estimation model
  /// 
  /// This method loads the model using ONNX Runtime.
  /// 
  /// ONNX model: assets/model/pose_estimation_model.onnx (38 MB)
  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;
    
    try {
      _isLoading = true;
      _errorMessage = null;
      
      // Try PyTorch Mobile
      try {
        debugPrint('PoseModelManager: Attempting to initialize PyTorch Mobile...');
        await _initializePyTorchMobile();
        _usePyTorch = true;
        debugPrint('PoseModelManager: ✅ YOLO11s-pose model manager initialized with PyTorch Mobile');
        _isInitialized = true;
        PoseDiagnostics.instance.logModelInit(success: true);
        return;
      } catch (e) {
        _errorMessage = 'Failed to initialize pose estimation model: $e';
        debugPrint('PoseModelManager: ❌ PyTorch Mobile initialization failed: $e');
        _usePyTorch = false;
        _isInitialized = false;
        PoseDiagnostics.instance.logModelInit(
          success: false,
          message: e.toString(),
        );
        rethrow;
      }
    } finally {
      _isLoading = false;
    }
  }
  
  /// Initialize PyTorch Mobile model
  Future<void> _initializePyTorchMobile() async {
    const modelAssetPath = 'assets/model/pose_model.ptl';
    
    // Load model from assets and copy to temporary directory
    final byteData = await rootBundle.load(modelAssetPath);
    final tempDir = await getTemporaryDirectory();
    final modelFile = File('${tempDir.path}/pose_model.ptl');
    await modelFile.writeAsBytes(byteData.buffer.asUint8List());
    
    _modelPath = modelFile.path;
    debugPrint('PoseModelManager: PyTorch model copied to: $_modelPath');
    
    // Initialize PyTorch Module via method channel
    try {
      final result = await _pytorchChannel.invokeMethod('initialize', {
        'modelPath': _modelPath,
      });
      
      if (result != true) {
        throw Exception('PyTorch initialization returned false');
      }
      
      debugPrint('PoseModelManager: ✅ PyTorch Mobile session initialized');
      
      // Verify PyTorch Mobile is actually working by running a test inference
      await _verifyPyTorchMobile();
    } catch (e) {
      debugPrint('PoseModelManager: ❌ PyTorch Mobile initialization failed: $e');
      throw Exception('PyTorch Mobile method channel not available: $e');
    }
  }
  
  /// Verify PyTorch Mobile is actually working by running a test inference
  Future<void> _verifyPyTorchMobile() async {
    try {
      debugPrint('PoseModelManager: Verifying PyTorch Mobile with test inference...');
      
      // Create a dummy test image (320x320 RGB)
      final testImage = img.Image(width: modelInputSize, height: modelInputSize, numChannels: 3);
      final testPreprocessed = _preprocessImage(testImage);
      
      // Run a test inference
      final testResult = await _pytorchChannel.invokeMethod('run', {
        'input': testPreprocessed.data,
        'inputShape': [1, 3, modelInputSize, modelInputSize],
      });
      
      if (testResult != null && testResult is List && testResult.isNotEmpty) {
        debugPrint('PoseModelManager: ✅ PyTorch Mobile verification successful - test inference returned ${testResult.length} values');
      } else {
        debugPrint('PoseModelManager: ⚠️ PyTorch Mobile verification failed - test inference returned null or empty');
      }
    } catch (e) {
      debugPrint('PoseModelManager: ⚠️ PyTorch Mobile verification failed: $e');
      // Don't throw - just log warning, model might still work
    }
  }
  
  /// Detect poses from image
  /// 
  /// This method processes an image and returns detected poses in YOLO format.
  /// 
  /// Expected input: img.Image (any size)
  /// Expected output: List of keypoints matching YOLO output format:
  ///   Each keypoint: {x: pixel_x, y: pixel_y, confidence: 0.0-1.0, name: string, index: int}
  Future<List<Map<String, dynamic>>> detectPoses(img.Image image) async {
    if (!_isInitialized) {
      throw Exception('Model not initialized. Call initialize() first.');
    }
    
    try {
      final originalWidth = image.width;
      final originalHeight = image.height;
      
      // Use PyTorch Mobile if available, otherwise fail
      if (_usePyTorch) {
        return await _runPyTorchInference(image, originalWidth, originalHeight);
      } else {
        throw Exception('PyTorch Mobile not available');
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
      return [];
    }
  }
  
  /// Run PyTorch Mobile inference for pose detection
  Future<List<Map<String, dynamic>>> _runPyTorchInference(
    img.Image image,
    int originalWidth,
    int originalHeight,
  ) async {
    try {
      // Preprocess image: letterbox to 320x320 and normalize
      final preprocessed = _preprocessImage(image);
      PoseDiagnostics.instance.logInputTensor(
        preprocessed.data,
        [1, 3, modelInputSize, modelInputSize],
      );
      
      // Run inference via method channel
      final inferenceStart = DateTime.now();
      final result = await _pytorchChannel.invokeMethod('run', {
        'input': preprocessed.data,
        'inputShape': [1, 3, modelInputSize, modelInputSize],
      });
      
      if (result == null) {
        debugPrint('PoseModelManager: ❌ PyTorch Mobile returned null output');
        return [];
      }
      
      // Parse output - result should be a List<double> representing the output tensor
      final outputData = result as List;
      debugPrint('PoseModelManager: Received output size: ${outputData.length}');
      
      // Parse YOLO output to extract keypoints
      final keypoints = _parseYOLOOutput(
        outputData.cast<double>(), 
        originalWidth, 
        originalHeight,
        preprocessed.scale,
        preprocessed.padX,
        preprocessed.padY,
      );

      PoseDiagnostics.instance.logOutputKeypoints(
        keypoints,
        duration: DateTime.now().difference(inferenceStart),
      );
      
      debugPrint('PoseModelManager: Parsed ${keypoints.length} keypoints');
      if (keypoints.isNotEmpty) {
         debugPrint('PoseModelManager: First keypoint: ${keypoints[0]}');
      }
      
      return keypoints;
      
    } catch (e) {
      debugPrint('PoseModelManager: ❌ PyTorch Mobile inference error: $e');
      PoseDiagnostics.instance.markFrameFailure('Inference error: $e');
      return [];
    }
  }
  
  /// Data class to hold preprocessed image data and scaling info
  /// Used to map coordinates back to original image
  
  /// Preprocess image for PyTorch model input with Letterboxing
  /// 
  /// Resizes to 320x320 preserving aspect ratio (letterboxing) and normalizes pixel values to [0, 1].
  /// Returns Float32List in NCHW format (batch, channels, height, width).
  _PreprocessedData _preprocessImage(img.Image image) {
    // Calculate scaling for letterboxing
    final double scale = math.min(
      modelInputSize / image.width,
      modelInputSize / image.height,
    );
    
    final int newWidth = (image.width * scale).round();
    final int newHeight = (image.height * scale).round();
    
    // Resize image
    final resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
    
    // Create 320x320 canvas (filled with gray/114 or black/0)
    // YOLO typically uses 114 for padding, but 0 is also common. Using 0 for simplicity.
    final canvas = img.Image(width: modelInputSize, height: modelInputSize, numChannels: 3);
    img.fill(
      canvas,
      color: img.ColorRgb8(paddingValue, paddingValue, paddingValue),
    );
    
    // Calculate padding to center the image
    final int padX = (modelInputSize - newWidth) ~/ 2;
    final int padY = (modelInputSize - newHeight) ~/ 2;
    
    // Paste resized image onto canvas
    img.compositeImage(canvas, resized, dstX: padX, dstY: padY);
    
    // Normalize to [0, 1] range and convert to float32
    // ONNX expects NCHW format: [batch, channels, height, width]
    final float32Data = Float32List(1 * 3 * modelInputSize * modelInputSize);
    
    // Fill in NCHW format
    for (int c = 0; c < 3; c++) { // Channel (R, G, B)
      for (int h = 0; h < modelInputSize; h++) { // Height
        for (int w = 0; w < modelInputSize; w++) { // Width
          final pixel = canvas.getPixel(w, h);
          final value = c == 0 ? pixel.r / 255.0 : (c == 1 ? pixel.g / 255.0 : pixel.b / 255.0);
          final index = c * (modelInputSize * modelInputSize) + h * modelInputSize + w;
          float32Data[index] = value;
        }
      }
    }
    
    return _PreprocessedData(
      data: float32Data,
      scale: scale,
      padX: padX.toDouble(),
      padY: padY.toDouble(),
    );
  }
  
  /// Parse YOLO output to extract keypoints
  /// 
  /// Output shape: [1, 56, 2100] flattened to [117600]
  /// Format per detection (56 values):
  ///   - [0:4]: bbox (x, y, w, h)
  ///   - [4]: confidence
  ///   - [5:56]: keypoints (17 * 3 = 51 values: x, y, conf for each keypoint)
  /// 
  /// IMPORTANT: YOLO export shape is [Batch, Channels, Anchors] -> [1, 56, 2100]
  /// But the data might be flattened in a way that requires careful indexing.
  /// 
  /// If the output is [1, 56, 2100], then for a given anchor 'a' (0..2099) and channel 'c' (0..55):
  /// Index = c * 2100 + a
  List<Map<String, dynamic>> _parseYOLOOutput(
    List<double> outputData,
    int originalWidth,
    int originalHeight,
    double scale,
    double padX,
    double padY,
  ) {
    final keypoints = <Map<String, dynamic>>[];
    
    // COCO keypoint names (17 keypoints)
    const keypointNames = [
      'nose', 'leftEye', 'rightEye', 'leftEar', 'rightEar',
      'leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow',
      'leftWrist', 'rightWrist', 'leftHip', 'rightHip',
      'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle'
    ];
    
    const numAnchors = 2100;
    
    // Find the best detection (highest confidence)
    int bestAnchorIndex = -1;
    double maxConfidence = 0.0;
    
    // The confidence score is at channel index 4
    // Index in flattened array = 4 * numAnchors + anchorIndex
    final confOffset = 4 * numAnchors;
    
    for (int i = 0; i < numAnchors; i++) {
      final confidence = outputData[confOffset + i];
      if (confidence > maxConfidence) {
        maxConfidence = confidence;
        bestAnchorIndex = i;
      }
    }
    
    // If no good detection found
    if (bestAnchorIndex == -1 || maxConfidence < minDetectionConfidence) {
      return [];
    }
    
    // Extract keypoints for the best anchor
    // Keypoints start at channel 5
    for (int kp = 0; kp < numKeypoints; kp++) {
      final channelBase = 5 + (kp * 3);
      
      // Calculate indices for x, y, conf
      // Index = channel * numAnchors + anchorIndex
      final xIdx = channelBase * numAnchors + bestAnchorIndex;
      final yIdx = (channelBase + 1) * numAnchors + bestAnchorIndex;
      final cIdx = (channelBase + 2) * numAnchors + bestAnchorIndex;
      
      if (cIdx >= outputData.length) break;
      
      // Get raw coordinates (in 320x320 model space)
      final rawX = outputData[xIdx];
      final rawY = outputData[yIdx];
      final kpConf = outputData[cIdx];
      
      // Map back to original image coordinates
      // 1. Remove padding
      // 2. Scale back up
      final x = (rawX - padX) / scale;
      final y = (rawY - padY) / scale;
      
      // Only include keypoints with reasonable confidence
      if (kpConf > minDetectionConfidence) {
        final clampedX = _clampCoordinate(x, originalWidth.toDouble());
        final clampedY = _clampCoordinate(y, originalHeight.toDouble());

        keypoints.add({
          'x': clampedX,
          'y': clampedY,
          'confidence': kpConf,
          'name': keypointNames[kp],
          'index': kp,
        });
      }
    }
    
    return keypoints;
  }
  
  /// Dispose of model resources
  Future<void> dispose() async {
    _isInitialized = false;
    _isLoading = false;
    _errorMessage = null;
    
    // Dispose PyTorch Mobile session if active
    if (_usePyTorch) {
      try {
        await _pytorchChannel.invokeMethod('dispose');
        debugPrint('PoseModelManager: PyTorch Mobile session disposed');
      } catch (e) {
        debugPrint('PoseModelManager: Error disposing PyTorch Mobile: $e');
      }
      _usePyTorch = false;
    }
    
    // Clean up temporary model file
    if (_modelPath != null) {
      try {
        final file = File(_modelPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('PoseModelManager: Error deleting model file: $e');
      }
      _modelPath = null;
    }
  }
}

double _clampCoordinate(double value, double max) {
  if (value.isNaN || value.isInfinite) {
    return 0;
  }
  if (value < 0) return 0;
  if (value > max) return max;
  return value;
}

class _PreprocessedData {
  final Float32List data;
  final double scale;
  final double padX;
  final double padY;
  
  _PreprocessedData({
    required this.data,
    required this.scale,
    required this.padX,
    required this.padY,
  });
}
