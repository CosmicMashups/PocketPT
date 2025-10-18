import 'dart:io';
import 'package:flutter/material.dart';
import 'pose_detection_service.dart';
import 'cnn_pose_detection_service.dart';
import 'facial_pain_recognition_service.dart';

/// Unified service for processing media files with AI models
class AIMediaProcessingService {
  static final AIMediaProcessingService _instance = AIMediaProcessingService._internal();
  factory AIMediaProcessingService() => _instance;
  AIMediaProcessingService._internal();

  final PoseDetectionService _poseService = PoseDetectionService();
  final CNNPoseDetectionService _cnnService = CNNPoseDetectionService();
  final FacialPainRecognitionService _facialService = FacialPainRecognitionService();

  bool _isInitialized = false;

  /// Initialize all AI services
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('AIMediaProcessingService: Initializing AI services...');
      await _cnnService.initialize();
      await _facialService.initialize();
      _isInitialized = true;
      debugPrint('AIMediaProcessingService: All services initialized successfully');
    } catch (e) {
      debugPrint('AIMediaProcessingService: Error during initialization: $e');
      // Continue with partial initialization
      _isInitialized = true;
    }
  }

  /// Process a static image with all available AI models
  Future<Map<String, dynamic>> processImage(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('AIMediaProcessingService: Processing image: ${imageFile.path}');
      
      // Run pose detection and CNN analysis in parallel
      final results = await Future.wait([
        _poseService.processStaticImage(imageFile),
        _cnnService.processStaticImage(imageFile),
      ]);

      final poseResult = results[0];
      final cnnResult = results[1];

      // Combine results
      final combinedResult = {
        'pose': poseResult,
        'cnn': cnnResult,
        'overallPainScore': _calculateOverallPainScore(poseResult, cnnResult),
        'painDescription': _getCombinedPainDescription(poseResult, cnnResult),
        'keypoints': poseResult['keypoints'] ?? {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'mediaType': 'image',
        'filePath': imageFile.path,
      };

      debugPrint('AIMediaProcessingService: Image processing completed');
      return combinedResult;
    } catch (e) {
      debugPrint('AIMediaProcessingService: Error processing image: $e');
      return {
        'error': e.toString(),
        'overallPainScore': 5,
        'painDescription': 'Processing error',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'mediaType': 'image',
        'filePath': imageFile.path,
      };
    }
  }

  /// Process a video file (placeholder for future implementation)
  Future<Map<String, dynamic>> processVideo(File videoFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('AIMediaProcessingService: Processing video: ${videoFile.path}');
      
      // TODO: Implement video processing
      // For now, return a placeholder result
      return {
        'overallPainScore': 5,
        'painDescription': 'Video processing not yet implemented',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'mediaType': 'video',
        'filePath': videoFile.path,
        'note': 'Video analysis will be implemented in future updates',
      };
    } catch (e) {
      debugPrint('AIMediaProcessingService: Error processing video: $e');
      return {
        'error': e.toString(),
        'overallPainScore': 5,
        'painDescription': 'Video processing error',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'mediaType': 'video',
        'filePath': videoFile.path,
      };
    }
  }

  /// Calculate overall pain score from multiple AI model results
  double _calculateOverallPainScore(Map<String, dynamic> poseResult, Map<String, dynamic> cnnResult) {
    try {
      final poseScore = (poseResult['overallPainScore'] as num?)?.toDouble() ?? 5.0;
      final cnnScore = (cnnResult['overallPainScore'] as num?)?.toDouble() ?? 5.0;
      
      // Weighted average (pose detection gets higher weight as it's more reliable)
      final overallScore = (poseScore * 0.7) + (cnnScore * 0.3);
      
      // Clamp to valid range (0-10)
      return overallScore.clamp(0.0, 10.0);
    } catch (e) {
      debugPrint('Error calculating overall pain score: $e');
      return 5.0; // Default moderate pain
    }
  }

  /// Get combined pain description from multiple AI model results
  String _getCombinedPainDescription(Map<String, dynamic> poseResult, Map<String, dynamic> cnnResult) {
    try {
      final poseDesc = poseResult['painDescription'] as String? ?? 'Unknown';
      final cnnDesc = cnnResult['painDescription'] as String? ?? 'Unknown';
      
      // If both models agree, use that description
      if (poseDesc == cnnDesc) {
        return poseDesc;
      }
      
      // If they disagree, combine them
      return '$poseDesc (AI analysis: $cnnDesc)';
    } catch (e) {
      debugPrint('Error getting combined pain description: $e');
      return 'Assessment completed';
    }
  }

  /// Check if AI services are ready
  bool get isReady => _isInitialized;

  /// Get service status
  Map<String, bool> getServiceStatus() {
    return {
      'poseDetection': true, // Always available
      'cnnAnalysis': _isInitialized,
      'facialRecognition': _isInitialized,
    };
  }
}
