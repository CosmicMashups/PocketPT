import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'design_system.dart';

/// Centralized camera service for managing camera lifecycle across all record pages
/// Implements singleton pattern to prevent multiple camera controllers and resource conflicts
class CameraService {
  CameraService._privateConstructor();
  static final CameraService _instance = CameraService._privateConstructor();
  static CameraService get instance => _instance;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = false;
  bool _isDisposed = false;
  
  // Stream controllers for camera state management
  final StreamController<bool> _initializationController = StreamController<bool>.broadcast();
  final StreamController<String?> _errorController = StreamController<String?>.broadcast();
  
  // Public streams
  Stream<bool> get initializationStream => _initializationController.stream;
  Stream<String?> get errorStream => _errorController.stream;
  
  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isInitializing => _isInitializing;
  bool get isDisposed => _isDisposed;
  List<CameraDescription>? get cameras => _cameras;

  /// Initialize camera with proper error handling and lifecycle management
  Future<bool> initialize() async {
    if (_isInitializing) {
      debugPrint('CameraService: Already initializing, waiting for completion...');
      // Wait for current initialization to complete
      await _initializationController.stream.first;
      return isInitialized;
    }

    if (isInitialized) {
      debugPrint('CameraService: Camera already initialized');
      return true;
    }

    if (_isDisposed) {
      debugPrint('CameraService: Cannot initialize disposed camera service');
      return false;
    }

    _isInitializing = true;
    _initializationController.add(false);

    try {
      debugPrint('CameraService: Starting camera initialization...');
      
      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      // Create camera controller with medium resolution for optimal performance
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false, // Disable audio to reduce resource usage
      );

      // Initialize the controller
      await _controller!.initialize();
      
      if (_isDisposed) {
        // Camera was disposed during initialization
        await _disposeController();
        return false;
      }

      debugPrint('CameraService: Camera initialized successfully');
      _initializationController.add(true);
      return true;

    } catch (e) {
      debugPrint('CameraService: Camera initialization failed: $e');
      _errorController.add(e.toString());
      _initializationController.add(false);
      
      // Clean up failed initialization
      await _disposeController();
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Dispose camera resources properly
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    debugPrint('CameraService: Disposing camera service...');
    _isDisposed = true;
    
    await _disposeController();
    
    // Close streams
    await _initializationController.close();
    await _errorController.close();
    
    debugPrint('CameraService: Camera service disposed');
  }

  /// Internal method to dispose controller
  Future<void> _disposeController() async {
    if (_controller != null) {
      try {
        await _controller!.dispose();
      } catch (e) {
        debugPrint('CameraService: Error disposing controller: $e');
      }
      _controller = null;
    }
  }

  /// Reset camera service for new session
  Future<void> reset() async {
    debugPrint('CameraService: Resetting camera service...');
    await _disposeController();
    _isDisposed = false;
    _cameras = null;
  }

  /// Check if camera is ready for use
  bool get isReady => isInitialized && !_isDisposed && _controller != null;

  /// Get camera preview widget with proper error handling
  Widget? getCameraPreview() {
    if (!isReady) return null;
    return CameraPreview(_controller!);
  }

  /// Get enhanced camera preview widget with modern medical styling
  Widget? getEnhancedCameraPreview(BuildContext context) {
    if (!isReady) return null;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusXL),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        boxShadow: RecordingDesignSystem.medicalShadow,
        border: Border.all(
          color: RecordingDesignSystem.primaryMedical.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusXL),
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  /// Get professional loading indicator for camera initialization
  Widget getLoadingIndicator(BuildContext context) {
    
    return Container(
      padding: const EdgeInsets.all(RecordingDesignSystem.spacingXXL),
      decoration: BoxDecoration(
        color: RecordingDesignSystem.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusXL),
        boxShadow: RecordingDesignSystem.medicalShadow,
        border: Border.all(
          color: RecordingDesignSystem.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                RecordingDesignSystem.primaryMedical,
              ),
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingM),
          Text(
            'Initializing camera...',
            style: RecordingDesignSystem.bodyLarge.copyWith(
              color: RecordingDesignSystem.getTextSecondaryColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get professional error state widget
  Widget getErrorState(BuildContext context, String errorMessage, VoidCallback? onRetry) {
    return Container(
      padding: const EdgeInsets.all(RecordingDesignSystem.spacingL),
      decoration: BoxDecoration(
        color: RecordingDesignSystem.getErrorColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
        border: Border.all(
          color: RecordingDesignSystem.getErrorColor(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: RecordingDesignSystem.getErrorColor(context),
            size: 32,
          ),
          const SizedBox(height: RecordingDesignSystem.spacingM),
          Text(
            'Camera Error',
            style: RecordingDesignSystem.titleLarge.copyWith(
              color: RecordingDesignSystem.getErrorColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingS),
          Text(
            errorMessage,
            style: RecordingDesignSystem.bodyMedium.copyWith(
              color: RecordingDesignSystem.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: RecordingDesignSystem.spacingM),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: RecordingDesignSystem.getErrorColor(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: RecordingDesignSystem.spacingL,
                  vertical: RecordingDesignSystem.spacingM,
                ),
              ),
              child: Text(
                'Retry',
                style: RecordingDesignSystem.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Switch to different camera if available
  Future<bool> switchCamera(int cameraIndex) async {
    if (_cameras == null || cameraIndex >= _cameras!.length) {
      debugPrint('CameraService: Invalid camera index: $cameraIndex');
      return false;
    }

    try {
      // Dispose current controller
      await _disposeController();
      
      // Create new controller with selected camera
      _controller = CameraController(
        _cameras![cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      
      if (_isDisposed) {
        await _disposeController();
        return false;
      }
      
      debugPrint('CameraService: Switched to camera $cameraIndex');
      _initializationController.add(true);
      return true;
      
    } catch (e) {
      debugPrint('CameraService: Failed to switch camera: $e');
      _errorController.add(e.toString());
      return false;
    }
  }
}
