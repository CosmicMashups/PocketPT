// Import necessary packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import '../data/globals.dart';
import '../main.dart';
import '../data/custom_pose_detection_service.dart';
import '../data/facial_pain_recognition_service.dart';
import '../widgets/custom_pose_skeleton_painter.dart';
import '../widgets/enhanced_pose_skeleton_painter.dart';
import '../widgets/assessment_help_dialog.dart';
import 'assessment_data.dart';
import 'arom/assessment_service.dart';
import 'arom/assessment_result.dart';
import 'c_video.dart';
import 'c_painlevel.dart';
import '../core/animations.dart';
class AssessPainCamera extends StatefulWidget {
  const AssessPainCamera({super.key});

  @override
  State<AssessPainCamera> createState() => _AssessPainCameraState();
}

class _AssessPainCameraState extends State<AssessPainCamera> with TickerProviderStateMixin {
  // Assessment logic moved to modular services

  int painScale = 0;
  late CameraController _controller;
  late List<CameraDescription> cameras;
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = false; // Track if camera initialization is in progress
  bool _isRecording = false;

  // New: pose estimation and camera switching state
  int _selectedCameraIndex = 0;
  String _selectedSide = 'Right'; // 'Left' or 'Right' side to assess
  
  /// Muscle-to-algorithm mapping for automatic detection
  /// Maps muscle groups selected in previous screens to appropriate AROM assessment algorithms
  /// Used to eliminate manual muscle selection redundancy in camera assessment
  static const Map<String, String> _muscleToAlgorithm = {
    // Upper Body
    'Deltoids': 'shoulders',
    'Biceps': 'biceps',
    'Triceps': 'triceps',
    'Cervical Muscle': 'shoulders',
    
    // Lower Body
    'Quadriceps': 'quadriceps',
    'Hamstrings': 'hamstrings',
    'Calf': 'calves',
    'Ankle': 'calves',
    'Gluteals': 'gluteals',
    
    // Core
    'Abdominals': 'abdominals',
    'Obliques': 'obliques',
    'Lower Back': 'lower back',
    'Multifidus': 'multifidus'
  };
  final CustomPoseDetectionService _poseService = CustomPoseDetectionService();
  final FacialPainRecognitionService _painService = FacialPainRecognitionService();
  bool _isStreaming = false;
  bool _processingFrame = false;
  Timer? _throttleTimer;
  int? _lastProcessedTime; // ms timestamp for throttling
  
  // Pain detection state variables
  bool _isPainDetectionEnabled = false;
  String? _currentPainLevel;
  double _painConfidence = 0.0;
  bool _showPainBanner = false;
  DateTime? _lastPainProcessTime;
  
  // Track if page is active - prevents pain detection after navigation
  bool _isPageActive = true;
  
  // Track if pain values are locked (after navigation)
  bool _painValuesLocked = false;
  
  // Severe pain dialog cooldown
  DateTime? _lastSeverePainDialogTime;
  static const Duration _severePainDialogCooldown = Duration(seconds: 15);
  
  // Checkbox states for pain dialogs
  bool _moderatePainBannerDontShowAgain = false;
  bool _severePainDialogDontShowAgain = false;
  
  // Animation controllers for pain feedback
  late AnimationController _painOverlayController;
  late AnimationController _painBannerController;
  late AnimationController _painColorController;
  late Animation<double> _painOverlayFadeAnimation;
  late Animation<double> _painBannerSlideAnimation;
  late Animation<double> _painBannerFadeAnimation;
  late Animation<Color?> _painColorAnimation;
  late Animation<double> _painScaleAnimation;
  
  // Video recording settings
  bool _enableVideoRecording = false; // Default to real-time only
  bool _isRealTimeAssessment = false;
  
  // Performance monitoring
  int _frameCount = 0;
  int _lastFpsTime = 0;
  double _currentFps = 0.0;
  
  // Current assessment result from modular services
  AssessmentResult? _currentAssessmentResult;

  // Skeleton visualization state - improved for better synchronization
  bool _showSkeleton = true; // Enabled by default
  List<Map<String, dynamic>> _currentKeypoints = []; // Raw keypoints from custom model
  Size? _cameraImageSize; // Store camera image dimensions for coordinate scaling
  SkeletonOverlayConfig _skeletonConfig = const SkeletonOverlayConfig();

  /// Convert custom model keypoints to landmarks format expected by assessment services
  /// 
  /// The custom model returns keypoints as a list of maps with 'x', 'y', 'confidence', 'name', and 'index' fields.
  /// This method converts them to normalized landmarks (0.0-1.0) matching ML Kit format.
  Map<String, Offset> _keypointsToLandmarks(
    List<Map<String, dynamic>> keypoints,
    Size imageSize,
    bool isFrontCamera,
  ) {
    final landmarks = <String, Offset>{};
    
    if (keypoints.isEmpty || imageSize.width <= 0 || imageSize.height <= 0) {
      return landmarks;
    }
    
    // Convert each keypoint to normalized landmark
    for (final kp in keypoints) {
      final x = (kp['x'] as num?)?.toDouble();
      final y = (kp['y'] as num?)?.toDouble();
      final confidence = (kp['confidence'] as num?)?.toDouble() ?? 0.0;
      final name = kp['name'] as String?;
      
      // Filter low confidence keypoints
      if (x == null || y == null || name == null || confidence < 0.5) {
        continue;
      }
      
      // Clamp coordinates to image bounds
      final clampedX = x.clamp(0.0, imageSize.width);
      final clampedY = y.clamp(0.0, imageSize.height);
      
      // Normalize to 0.0-1.0 range
      double nx = clampedX / imageSize.width;
      double ny = clampedY / imageSize.height;
      
      // Mirror horizontally for front camera preview
      if (isFrontCamera) {
        nx = 1.0 - nx;
      }
      
      landmarks[name] = Offset(nx, ny);
    }
    
    return landmarks;
  }

  /// Determine assessment algorithm based on UserAssess.specificMuscle
  /// 
  /// This method automatically selects the appropriate AROM assessment algorithm
  /// based on the muscle group selected by the user in previous assessment screens.
  /// 
  /// Returns:
  /// - The appropriate algorithm name for the selected muscle
  /// - 'triceps' as fallback for unknown or empty muscle selections
  /// 
  /// Example:
  /// ```dart
  /// final mode = _getAssessmentMode(); // Returns 'hamstrings' if UserAssess.specificMuscle = 'Hamstrings'
  /// ```
  String _getAssessmentMode() {
    final muscle = UserAssess.specificMuscle;
    if (muscle.isEmpty) {
      debugPrint('Warning: No muscle selected, using default (triceps)');
      return 'triceps';
    }
    
    final mode = _muscleToAlgorithm[muscle];
    if (mode == null) {
      debugPrint('Warning: Unknown muscle group: $muscle, using default (triceps)');
      return 'triceps';
    }
    
    debugPrint('Selected muscle: $muscle -> Assessment mode: $mode');
    return mode;
  }
  
  double? _getCurrentAngle() {
    final result = _currentAssessmentResult;
    if (result == null) return null;
    final angle = result.additionalData['angle'];
    if (angle is num) {
      return angle.toDouble();
    }
    return null;
  }

  // Start assessment (with or without video recording)
  Future<XFile?> _startAssessment() async {
    if (!_controller.value.isInitialized) {
      return null;
    }

    try {
      // Ensure image stream is active for pose detection
      if (!_isStreaming) {
        debugPrint('Starting image stream for pose detection during assessment');
        await _startImageStream();
      }
      
      if (_enableVideoRecording) {
        // Video recording mode
        if (_controller.value.isRecordingVideo) {
          return null; // Already recording
        }
        
        await _controller.startVideoRecording();
        debugPrint('Video recording started, pose detection continues via image stream');
        
        // Verify pose detection is working during recording
        _verifyPoseDetectionDuringRecording();
        
        // Wait for 10 seconds while pose detection continues via image stream
        await Future.delayed(const Duration(seconds: 10));
        
        // Stop video recording but keep image stream for pose detection
        XFile videoFile = await _controller.stopVideoRecording();
        debugPrint('Video recording stopped, pose detection continues via image stream');
        return videoFile;
      } else {
        // Real-time assessment mode (no video recording)
        setState(() {
          _isRealTimeAssessment = true;
        });
        debugPrint('Real-time assessment started (no video recording)');
        
        // Verify pose detection is working during real-time assessment
        _verifyPoseDetectionDuringRecording();
        
        // Wait for 10 seconds while pose detection continues via image stream
        await Future.delayed(const Duration(seconds: 10));
        
        setState(() {
          _isRealTimeAssessment = false;
        });
        debugPrint('Real-time assessment completed');
        return null; // No video file in real-time mode
      }
    } catch (e) {
      debugPrint('Error during assessment: $e');
      return null;
    }
  }

  // Initialize the camera
  @override
  void initState() {
    super.initState();
    print('AssessPainCamera: initState() called');
    print('AssessPainCamera: Current AssessmentData.painScale = "${AssessmentData.painScale}"');
    print('AssessPainCamera: Current UserAssess.painScale = "${UserAssess.painScale}"');
    
    // Initialize pain scale from local data
    painScale = UserAssess.painScale;
    print('AssessPainCamera: painScale initialized to: $painScale');
    
    // Initialize pain feedback animations
    _painOverlayController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.fast,
    );
    _painBannerController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.medium,
    );
    _painColorController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.medium,
    );
    
    // Set up animations
    _painOverlayFadeAnimation = PocketPTAnimations.createOpacityTween(
      begin: 0.0,
      end: 1.0,
    ).animate(PocketPTAnimations.createCurvedAnimation(_painOverlayController));
    
    _painBannerSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(PocketPTAnimations.createCurvedAnimation(_painBannerController));
    
    _painBannerFadeAnimation = PocketPTAnimations.createOpacityTween().animate(
      PocketPTAnimations.createCurvedAnimation(_painBannerController),
    );
    
    _painColorAnimation = ColorTween(
      begin: Colors.grey,
      end: Colors.green,
    ).animate(PocketPTAnimations.createCurvedAnimation(_painColorController));
    
    _painScaleAnimation = PocketPTAnimations.createScaleTween(
      begin: 0.95,
      end: 1.0,
    ).animate(PocketPTAnimations.createCurvedAnimation(_painOverlayController));
    
    // Start overlay fade in
    _painOverlayController.forward();
    
    _initializePoseDetection();
    _initializeCamera();
    _initializePainDetection();
    print('AssessPainCamera: initState() completed');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If returning to this page and controller was disposed, re-initialize
    if (!_isCameraInitialized) {
      debugPrint('Camera not initialized, attempting to initialize...');
      _initializeCamera();
    }
  }

  // Initialize the camera and set the controller
  Future<void> _initializeCamera() async {
    // Prevent multiple simultaneous initialization attempts
    if (_isCameraInitializing) {
      debugPrint('Camera initialization already in progress, skipping...');
      return;
    }
    
    try {
      _isCameraInitializing = true;
      cameras = await availableCameras();  // Get available cameras
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        _isCameraInitializing = false;
        return;
      }
      
      // Try to initialize camera with auto-switching on failure
      bool initialized = false;
      int attempts = 0;
      int maxAttempts = cameras.length;
      
      while (!initialized && attempts < maxAttempts && mounted) {
        try {
          _controller = CameraController(
            cameras[_selectedCameraIndex],  // Use the selected camera
            ResolutionPreset.high,  // Set the camera resolution
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.yuv420,
          );

          await _controller.initialize();  // Initialize the camera
          initialized = true;
          
          if (!mounted) {
            _isCameraInitializing = false;
            return;
          }
          setState(() {
            _isCameraInitialized = true;  // Camera is initialized
            _isCameraInitializing = false;  // Initialization complete
          });
          
          // Start image stream after a short delay to ensure camera is ready
          await Future.delayed(const Duration(milliseconds: 500));
          await _startImageStream();
          debugPrint('Camera initialized successfully with camera index: $_selectedCameraIndex');
        } catch (e) {
          debugPrint('Camera initialization error with camera $_selectedCameraIndex: $e');
          // Try next camera
          attempts++;
          if (attempts < maxAttempts) {
            _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
            debugPrint('Trying next camera: $_selectedCameraIndex');
            // Dispose failed controller before retrying
            try {
              await _controller.dispose();
            } catch (_) {}
          }
        }
      }
      
      _isCameraInitializing = false; // Reset initialization flag
      
      if (!initialized && mounted && !_isCameraInitialized) {
        debugPrint('Failed to initialize any camera after trying all available cameras');
        setState(() {
          _isCameraInitialized = false;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Camera Unavailable'),
            content: const Text('We could not access any camera. Please ensure camera permission is granted in system settings and that no other app is using the camera.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _isCameraInitializing = false; // Reset initialization flag
      if (mounted && !_isCameraInitialized) {
        setState(() {
          _isCameraInitialized = false;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Camera Unavailable'),
            content: const Text('We could not access the camera. Please ensure camera permission is granted in system settings and that no other app is using the camera.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  Future<void> _startImageStream() async {
    if (_isStreaming || !_controller.value.isInitialized) {
      debugPrint('Cannot start image stream: isStreaming=$_isStreaming, isInitialized=${_controller.value.isInitialized}');
      return;
    }
    
    // Check if camera supports image streaming
    try {
      if (!_controller.value.isInitialized) {
        debugPrint('⚠️ Camera not initialized, cannot start image stream');
        return;
      }
      // Note: Some cameras may not support streaming - we'll catch the error if it fails
    } catch (e) {
      debugPrint('⚠️ Error checking camera streaming support: $e');
      return;
    }
    
    try {
      _isStreaming = true;
      await _controller.startImageStream((CameraImage image) async {
      if (_processingFrame) return;
      if (_throttleTimer != null && _throttleTimer!.isActive) return;
      _throttleTimer = Timer(const Duration(milliseconds: 150), () {});
      // Additional hard cap to reduce CPU usage on low-end devices
      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      _lastProcessedTime ??= nowMs;
      if (nowMs - _lastProcessedTime! < 120) {
        return;
      }
      _lastProcessedTime = nowMs;
      
      // Performance monitoring: calculate FPS
      _frameCount++;
      if (_lastFpsTime == 0) {
        _lastFpsTime = nowMs;
      } else if (nowMs - _lastFpsTime >= 1000) {
        _currentFps = _frameCount * 1000.0 / (nowMs - _lastFpsTime);
        _frameCount = 0;
        _lastFpsTime = nowMs;
        
        // Log performance metrics
        if (_currentFps < 8.0) {
          debugPrint('Warning: Low FPS detected: ${_currentFps.toStringAsFixed(1)}');
        }
      }

      _processingFrame = true;
      try {
        // Store camera image size for coordinate scaling
        final camera = cameras[_selectedCameraIndex];
        final sensorOrientation = camera.sensorOrientation;
        final isPortrait = sensorOrientation == 90 || sensorOrientation == 270;
        
        _cameraImageSize = Size(
          isPortrait ? image.height.toDouble() : image.width.toDouble(),
          isPortrait ? image.width.toDouble() : image.height.toDouble(),
        );
        
        // Process pose detection using custom model
        final keypoints = await _poseService.detectPosesFromCameraImage(
          image: image,
          camera: camera,
        );
        
        if (keypoints.isNotEmpty) {
          try {
            // Convert keypoints to landmarks format
            final isFrontCamera = camera.lensDirection == CameraLensDirection.front;
            final landmarks = _keypointsToLandmarks(
              keypoints,
              _cameraImageSize!,
              isFrontCamera,
            );
            
            // Validate landmarks before processing
            if (landmarks.isEmpty) {
              debugPrint('Warning: Empty landmarks detected, skipping frame');
              return;
            }
            
            // Additional validation: check for reasonable landmark count
            if (landmarks.length < 5) {
              debugPrint('Warning: Insufficient landmarks detected (${landmarks.length}), skipping frame');
              return;
            }
          
            // Store keypoints for skeleton visualization
            _currentKeypoints = keypoints;
            debugPrint('Pose detected: ${landmarks.length} landmarks, ${keypoints.length} keypoints');
          
            // Only trigger UI update if skeleton is visible to avoid unnecessary repaints
            if (_showSkeleton && mounted) {
              setState(() {});
            }
          
            // Perform ROM assessment using modular services
            try {
              final assessmentResult = AssessmentService.assess(_getAssessmentMode(), landmarks, _selectedSide);
              
              if (mounted && _isPageActive && !_painValuesLocked) {
                setState(() {
                  _currentAssessmentResult = assessmentResult;
                  
                  // Update both UserAssess and AssessmentData for integration (persists during recording)
                  // Only update if page is active and values are not locked
                  UserAssess.painScale = assessmentResult.painScore;
                  UserAssess.painLevel = assessmentResult.categoricalPainLevel;
                  
                  // Also update AssessmentData to ensure it's available in the pain level page
                  AssessmentData.painScale = assessmentResult.painScore;
                  AssessmentData.painLevel = assessmentResult.categoricalPainLevel;
                  
                  debugPrint('AROM Assessment updated - painScore: ${assessmentResult.painScore}, categoricalPainLevel: ${assessmentResult.categoricalPainLevel}');
                  
                  PainHistory.recordTodayAndSave(
                    painScale: UserAssess.painScale,
                    painLevel: UserAssess.painLevel,
                  );
                });
              }
            } catch (e) {
              debugPrint('Assessment failed: $e');
            }
          } catch (e) {
            debugPrint('Landmark processing error: $e');
            // Continue processing even if landmark extraction fails
          }
        }
        
        // Process pain detection with frame rate limiting (only if page is active)
        if (_isPageActive && _isPainDetectionEnabled && _shouldProcessPainFrame()) {
          try {
            final painResult = await _painService.detectFacialPain(
              image: image,
              camera: cameras[_selectedCameraIndex],
            );
            if (_isPageActive && mounted) {
              // Always handle result, even if there's an error (to show error state)
              if (painResult['error'] == null) {
                // Successful detection - update UI
                debugPrint('✅ Pain detection successful: ${painResult['painLevel']}, confidence: ${painResult['confidence']}');
                _handlePainDetectionResult(painResult);
              } else {
                // Error occurred - log it but still update UI with last known values if available
                debugPrint('⚠️ Pain detection returned error: ${painResult['error']}');
                if (painResult['painLevel'] != null && painResult['confidence'] != null) {
                  // Update with last known values to keep UI responsive
                  debugPrint('Using last known pain level: ${painResult['painLevel']}');
                  _handlePainDetectionResult(painResult);
                } else {
                  // No valid values available - log warning
                  debugPrint('❌ Pain detection error with no fallback values available');
                }
              }
            }
          } catch (e, stackTrace) {
            debugPrint('Pain detection error: $e');
            debugPrint('Pain detection stack trace: $stackTrace');
          }
        }
      } catch (e) {
        debugPrint('Pose detection error: $e');
      } finally {
        _processingFrame = false;
      }
    });
    } catch (e) {
      debugPrint('Error starting image stream: $e');
      _isStreaming = false;
      
      // Check if error is due to streaming not being supported
      if (e.toString().contains('supportsImageStreaming') || e.toString().contains('is not true')) {
        debugPrint('⚠️ Camera does not support image streaming on this device');
        debugPrint('⚠️ Pose detection and pain recognition will not work without image streaming');
        return;
      }
      
      // Retry once after a short delay to handle devices that fail on first attempt
      if (mounted && _controller.value.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!_isStreaming) {
          try {
            await _controller.startImageStream((CameraImage image) async {
              if (_processingFrame) return;
              if (_throttleTimer != null && _throttleTimer!.isActive) return;
              _throttleTimer = Timer(const Duration(milliseconds: 150), () {});
              final int nowMs = DateTime.now().millisecondsSinceEpoch;
              _lastProcessedTime ??= nowMs;
              if (nowMs - _lastProcessedTime! < 120) {
                return;
              }
              _lastProcessedTime = nowMs;

              _processingFrame = true;
              try {
                // Store camera image size for coordinate scaling
                final camera = cameras[_selectedCameraIndex];
                final sensorOrientation = camera.sensorOrientation;
                final isPortrait = sensorOrientation == 90 || sensorOrientation == 270;
                
                _cameraImageSize = Size(
                  isPortrait ? image.height.toDouble() : image.width.toDouble(),
                  isPortrait ? image.width.toDouble() : image.height.toDouble(),
                );
                
                // Process pose detection using custom model
                final keypoints = await _poseService.detectPosesFromCameraImage(
                  image: image,
                  camera: camera,
                );
                
                if (keypoints.isNotEmpty) {
                  try {
                    // Convert keypoints to landmarks format
                    final isFrontCamera = camera.lensDirection == CameraLensDirection.front;
                    final landmarks = _keypointsToLandmarks(
                      keypoints,
                      _cameraImageSize!,
                      isFrontCamera,
                    );
                    
                    // Validate landmarks before processing
                    if (landmarks.isEmpty) {
                      debugPrint('Warning: Empty landmarks detected in retry, skipping frame');
                      return;
                    }
                    
                    // Additional validation: check for reasonable landmark count
                    if (landmarks.length < 5) {
                      debugPrint('Warning: Insufficient landmarks detected in retry (${landmarks.length}), skipping frame');
                      return;
                    }
                  
                    // Store keypoints for skeleton visualization
                    _currentKeypoints = keypoints;
                  
                    // Only trigger UI update if skeleton is visible to avoid unnecessary repaints
                    if (_showSkeleton && mounted) {
                      setState(() {});
                    }
                    
                    // Perform ROM assessment using modular services
                    try {
                      final assessmentResult = AssessmentService.assess(_getAssessmentMode(), landmarks, _selectedSide);
                      
                      if (mounted && _isPageActive && !_painValuesLocked) {
                        setState(() {
                          _currentAssessmentResult = assessmentResult;
                          
                          // Update both UserAssess and AssessmentData for integration (persists during recording)
                          // Only update if page is active and values are not locked
                          UserAssess.painScale = assessmentResult.painScore;
                          UserAssess.painLevel = assessmentResult.categoricalPainLevel;
                          
                          // Also update AssessmentData to ensure it's available in the pain level page
                          AssessmentData.painScale = assessmentResult.painScore;
                          AssessmentData.painLevel = assessmentResult.categoricalPainLevel;
                          
                          debugPrint('AROM Assessment updated (retry) - painScore: ${assessmentResult.painScore}, categoricalPainLevel: ${assessmentResult.categoricalPainLevel}');
                          
                          PainHistory.recordTodayAndSave(
                            painScale: UserAssess.painScale,
                            painLevel: UserAssess.painLevel,
                          );
                        });
                      }
                    } catch (e) {
                      debugPrint('Assessment failed in retry: $e');
                    }
                  } catch (e) {
                    debugPrint('Landmark processing error in retry: $e');
                    // Continue processing even if landmark extraction fails
                  }
                }
              } finally {
                _processingFrame = false;
              }
            });
            _isStreaming = true;
          } catch (e2) {
            debugPrint('Retry startImageStream failed: $e2');
          }
        }
      }
    }
  }

  

  // Assessment logic moved to modular services

  // Assessment logic moved to modular services


  Future<void> _switchCamera() async {
    if (cameras.isEmpty) return;
    final next = (_selectedCameraIndex + 1) % cameras.length;
    try { await _controller.stopImageStream(); } catch (_) {}
    await _controller.dispose();
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = next;
      _isStreaming = false;
      // Clear keypoints when switching cameras to prevent stale data
      _currentKeypoints = [];
      _cameraImageSize = null;
    });
    await _initializeCamera();
  }

  // Initialize custom pose detection service
  Future<void> _initializePoseDetection() async {
    try {
      await _poseService.initialize();
      debugPrint('Custom pose detection service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing custom pose detection service: $e');
      // Graceful degradation: Continue without pose detection
    }
  }

  // Initialize pain detection service
  Future<void> _initializePainDetection() async {
    try {
      await _painService.initialize();
      if (mounted) {
        setState(() {
          _isPainDetectionEnabled = true;
        });
        // Pain detection is handled in the image stream callback, no need for separate timer
        debugPrint('Pain detection initialized successfully for AROM assessment');
      }
    } catch (e) {
      debugPrint('Error initializing pain detection: $e');
      if (mounted) {
        setState(() {
          _isPainDetectionEnabled = false;
        });
      }
      // Graceful degradation: Continue assessment without pain detection
      // Assessment can proceed with manual pain level input
      debugPrint('AROM assessment will continue without automatic pain detection');
    }
  }

  // Stop pain detection (cleanup method - pain detection is handled in image stream)
  void _stopPainDetection() {
    _isPageActive = false;
    _painValuesLocked = true; // Lock pain values to prevent further updates
  }

  // Handle pain detection results
  void _handlePainDetectionResult(Map<String, dynamic> result) {
    // Only update UI if we have real model output (not cached/error values)
    final isRealTime = result['isRealTime'] == true;
    final hasError = result['error'] != null;
    
    if (isRealTime) {
      debugPrint('✅ Updating UI with REAL-TIME model output: ${result['painLevel']}, confidence: ${result['confidence']}');
    } else if (hasError) {
      debugPrint('⚠️ Pain detection has error, using last known value if available: ${result['error']}');
    } else {
      debugPrint('ℹ️ Using cached/last known pain level: ${result['painLevel']}');
    }
    // Don't process if page is no longer active or values are locked
    if (!_isPageActive || _painValuesLocked) return;
    
    final painLevel = result['painLevel'] as String?;
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
    
    // Always update state if we have valid values (even with low confidence)
    // This ensures the UI reflects the current model output
    if (painLevel != null && painLevel.isNotEmpty) {
      // Check if pain level changed for smooth animation
      final painLevelChanged = _currentPainLevel != painLevel;
      
      setState(() {
        _currentPainLevel = painLevel;
        _painConfidence = confidence;
      });
      
      debugPrint('Pain detection result updated: Level=$painLevel, Confidence=${(confidence * 100).toStringAsFixed(1)}%');
      
      // Animate color change and scale when pain level changes
      if (painLevelChanged && _currentPainLevel != null) {
        _animatePainLevelChange(_currentPainLevel!);
      }
      
      // Only trigger interventions for higher confidence detections
      if (confidence > 0.7) {
        _triggerPainIntervention(painLevel);
      }
    } else {
      debugPrint('Pain detection result invalid: painLevel=$painLevel, confidence=$confidence');
    }
  }

  // Animate pain level change with color transition and scale
  void _animatePainLevelChange(String newPainLevel) {
    // Update color animation
    final newColor = _getPainColor(newPainLevel);
    _painColorAnimation = ColorTween(
      begin: _painColorAnimation.value ?? Colors.grey,
      end: newColor,
    ).animate(PocketPTAnimations.createCurvedAnimation(_painColorController));
    
    // Reset and play animations
    _painColorController.reset();
    _painOverlayController.reset();
    _painColorController.forward();
    _painOverlayController.forward();
  }

  // Trigger pain intervention based on level
  void _triggerPainIntervention(String painLevel) {
    switch (painLevel) {
      case 'Low':
        // Ignore low pain
        break;
      case 'Moderate':
        _showModeratePainBanner();
        break;
      case 'Severe':
        _showSeverePainDialog();
        break;
    }
  }

  // Check if moderate pain banner should be shown
  bool _shouldShowModeratePainBanner() {
    return UserSettings.showModeratePainBanner;
  }

  // Save preference to hide/show moderate pain banner
  Future<void> _setHideModeratePainBanner(bool hide) async {
    UserSettings.showModeratePainBanner = !hide;
    await UserSettings.saveToHive();
    await UserSettings.saveToFirebase();
  }

  // Show moderate pain banner
  void _showModeratePainBanner() {
    // Check if user has disabled this banner
    if (!_shouldShowModeratePainBanner()) {
      debugPrint('Moderate pain banner disabled by user preference');
      return;
    }
    
    if (_showPainBanner) return; // Prevent multiple banners
    
    setState(() {
      _showPainBanner = true;
    });
    
    // Animate banner slide-in
    _painBannerController.forward();
    
    // Auto-dismiss after 10 seconds with smooth animation
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _dismissPainBanner();
      }
    });
  }

  // Check if severe pain dialog should be shown
  bool _shouldShowSeverePainDialog() {
    return UserSettings.showSeverePainDialog;
  }

  // Save preference to hide/show severe pain dialog
  Future<void> _setHideSeverePainDialog(bool hide) async {
    UserSettings.showSeverePainDialog = !hide;
    await UserSettings.saveToHive();
    await UserSettings.saveToFirebase();
  }

  // Show severe pain dialog with cooldown protection
  void _showSeverePainDialog() {
    // Check if user has disabled this dialog
    if (!_shouldShowSeverePainDialog()) {
      debugPrint('Severe pain dialog disabled by user preference');
      return;
    }
    
    final now = DateTime.now();
    
    // Check if enough time has passed since last dialog
    if (_lastSeverePainDialogTime != null) {
      final timeSinceLastDialog = now.difference(_lastSeverePainDialogTime!);
      if (timeSinceLastDialog < _severePainDialogCooldown) {
        debugPrint('Severe pain dialog blocked due to cooldown. Time remaining: ${(_severePainDialogCooldown - timeSinceLastDialog).inSeconds} seconds');
        return;
      }
    }
    
    _lastSeverePainDialogTime = now;
    
    // Reset checkbox state for this dialog
    _severePainDialogDontShowAgain = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Text('Pain Detected'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The application has detected severe pain from your facial expressions. '
                    'Please confirm if this pain level is accurate before proceeding.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _severePainDialogDontShowAgain,
                        onChanged: (value) {
                          setDialogState(() {
                            _severePainDialogDontShowAgain = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Don\'t show this again',
                          style: GoogleFonts.ptSans(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_severePainDialogDontShowAgain) {
                      await _setHideSeverePainDialog(true);
                    }
                    Navigator.of(context).pop();
                    _pauseExerciseForRest();
                  },
                  child: Text('Take a Rest'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_severePainDialogDontShowAgain) {
                      await _setHideSeverePainDialog(true);
                    }
                    Navigator.of(context).pop();
                    _continueExercise();
                  },
                  child: Text('Continue Assessment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Pause exercise for rest
  void _pauseExerciseForRest() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assessment paused. Please rest and resume when ready.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Continue exercise with warning
  void _continueExercise() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Continuing assessment. Please stop if pain increases.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Dismiss pain banner
  void _dismissPainBanner() {
    // Animate banner slide-out before hiding
    _painBannerController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showPainBanner = false;
        });
      }
    });
  }

  // Check if pain detection frame should be processed (5 FPS limiting)
  bool _shouldProcessPainFrame() {
    final now = DateTime.now();
    if (_lastPainProcessTime == null) {
      _lastPainProcessTime = now;
      return true;
    }
    final elapsed = now.difference(_lastPainProcessTime!).inMilliseconds;
    if (elapsed >= (1000 / 5)) { // 5 FPS
      _lastPainProcessTime = now;
      return true;
    }
    return false;
  }

  // Verify pose detection is working during recording
  void _verifyPoseDetectionDuringRecording() {
    if (_isRecording && _isStreaming) {
      debugPrint('✅ Pose detection is active during recording');
    } else if (_isRecording && !_isStreaming) {
      debugPrint('⚠️ WARNING: Pose detection is NOT active during recording');
    }
  }

  // Build pain detection status overlay - moved to top left
  Widget _buildPainDetectionOverlay() {
    final iconColor = _getPainColor(_currentPainLevel);
    final modelName = _painService.activeModelDisplayName;
    final isOnnxReady = _painService.isOnnxReady;

    Widget buildContent(Color currentIconColor) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPainIcon(_currentPainLevel),
                color: currentIconColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _currentPainLevel ?? (_isPainDetectionEnabled ? 'Analyzing...' : 'N/A'),
                style: GoogleFonts.ptSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (_painConfidence > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${(_painConfidence * 100).toInt()}%',
                  style: GoogleFonts.ptSans(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Model: $modelName',
                style: GoogleFonts.ptSans(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
              if (!isOnnxReady) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, size: 10, color: Colors.orangeAccent),
                      const SizedBox(width: 4),
                      Text(
                        'ONNX unavailable',
                        style: GoogleFonts.ptSans(
                          fontSize: 10,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    Widget buildOverlay(Color currentColor) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: buildContent(currentColor),
      );
    }

    if (!PocketPTAnimations.shouldAnimate(context)) {
      return Positioned(top: 8, left: 8, child: buildOverlay(iconColor));
    }

    return Positioned(
      top: 8,
      left: 8,
      child: FadeTransition(
        opacity: _painOverlayFadeAnimation,
        child: ScaleTransition(
          scale: _painScaleAnimation,
          child: AnimatedBuilder(
            animation: _painColorController,
            builder: (context, child) {
              final animatedColor = _painColorAnimation.value ?? iconColor;
              return buildOverlay(animatedColor);
            },
          ),
        ),
      ),
    );
  }

  // Build moderate pain banner
  Widget _buildModeratePainBanner() {
    Widget bannerContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade700, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Moderate Pain Detected',
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please take a break if needed. You can continue when ready.',
                      style: GoogleFonts.ptSans(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  if (_moderatePainBannerDontShowAgain) {
                    await _setHideModeratePainBanner(true);
                  }
                  _dismissPainBanner();
                },
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _moderatePainBannerDontShowAgain,
                onChanged: (value) {
                  setState(() {
                    _moderatePainBannerDontShowAgain = value ?? false;
                  });
                },
                checkColor: Colors.orange.shade700,
                fillColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return Colors.transparent;
                  },
                ),
              ),
              Expanded(
                child: Text(
                  'Don\'t show this again',
                  style: GoogleFonts.ptSans(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!PocketPTAnimations.shouldAnimate(context)) {
      // Fallback to non-animated version if animations are disabled
      return Positioned(
        bottom: 20,
        left: 20,
        right: 20,
        child: bannerContent,
      );
    }

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0), // Start from below
          end: Offset.zero,
        ).animate(_painBannerSlideAnimation),
        child: FadeTransition(
          opacity: _painBannerFadeAnimation,
          child: bannerContent,
        ),
      ),
    );
  }

  // Get pain color based on level
  Color _getPainColor(String? painLevel) {
    switch (painLevel) {
      case 'Low':
        return Colors.green;
      case 'Moderate':
        return Colors.orange;
      case 'Severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _mapFacialPainScore(String? painLevel) {
    switch (painLevel) {
      case 'Low':
        return 2;
      case 'Moderate':
        return 5;
      case 'Severe':
        return 8;
      default:
        // Return null/0 to indicate no valid pain level instead of hardcoded 2
        return 0; // Will be handled by UI to show "N/A" or last known value
    }
  }

  // Get pain icon based on level
  IconData _getPainIcon(String? painLevel) {
    switch (painLevel) {
      case 'Low':
        return Icons.sentiment_very_satisfied;
      case 'Moderate':
        return Icons.sentiment_dissatisfied;
      case 'Severe':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  // Get background color based on detected pain level
  Color _getPainBasedBackgroundColor() {
    switch (_currentPainLevel) {
      case 'Low':
        return Colors.green.shade50;
      case 'Moderate':
        return Colors.orange.shade50;
      case 'Severe':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  // Get border color based on detected pain level
  Color _getPainBasedBorderColor() {
    switch (_currentPainLevel) {
      case 'Low':
        return Colors.green.shade400;
      case 'Moderate':
        return Colors.orange.shade400;
      case 'Severe':
        return Colors.red.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  // Get accent color based on detected pain level
  Color _getPainBasedAccentColor() {
    switch (_currentPainLevel) {
      case 'Low':
        return Colors.green.shade600;
      case 'Moderate':
        return Colors.orange.shade600;
      case 'Severe':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Get text color based on detected pain level
  Color _getPainBasedTextColor() {
    switch (_currentPainLevel) {
      case 'Low':
        return Colors.green.shade800;
      case 'Moderate':
        return Colors.orange.shade800;
      case 'Severe':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  // Show pain level confirmation dialog
  void _showPainLevelConfirmationDialog() {
    // This dialog should ONLY display AROM assessment values from @arom/
    // If AROM assessment result is not available, show an error or use last known AROM values
    if (_currentAssessmentResult == null) {
      debugPrint('⚠️ Pain Level Dialog: AROM assessment result is null - using AssessmentData as fallback');
      // Use AssessmentData which should contain AROM values from previous assessment
      if (AssessmentData.painScale <= 0 || AssessmentData.painLevel.isEmpty) {
        debugPrint('❌ Pain Level Dialog: No AROM assessment data available');
        // Show error dialog instead
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Assessment Required'),
              content: const Text('Please complete the ROM assessment first before viewing pain level.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
    }
    
    // Use AROM assessment result values (from @arom/)
    final romPainLevel = _currentAssessmentResult?.categoricalPainLevel ?? AssessmentData.painLevel;
    final romPainScale = _currentAssessmentResult?.painScore ?? AssessmentData.painScale;
    final poseAngle = _currentAssessmentResult?.additionalData['angle'] as double?;
    
    debugPrint('✅ Pain Level Confirmation Dialog - AROM Assessment Result:');
    debugPrint('   painScore: $romPainScale, categoricalPainLevel: $romPainLevel');
    if (_currentAssessmentResult != null) {
      debugPrint('   displayLabel: ${_currentAssessmentResult!.displayLabel}');
      debugPrint('   romLevel: ${_currentAssessmentResult!.romLevel}');
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.health_and_safety, color: _getPainColor(romPainLevel), size: 24),
              const SizedBox(width: 8),
              Text('Pain Level'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Active Range of Motion (AROM) assessment recorded the following values:',
                style: GoogleFonts.ptSans(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPainColor(romPainLevel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getPainColor(romPainLevel)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getPainIcon(romPainLevel), color: _getPainColor(romPainLevel)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$romPainLevel Pain',
                                style: GoogleFonts.ptSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _getPainColor(romPainLevel),
                                ),
                              ),
                              if (_currentAssessmentResult != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _currentAssessmentResult!.displayLabel,
                                  style: GoogleFonts.ptSans(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Pain Scale: ',
                          style: GoogleFonts.ptSans(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '$romPainScale / 10',
                          style: GoogleFonts.ptSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getPainColor(romPainLevel),
                          ),
                        ),
                      ],
                    ),
                    if (poseAngle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pose angle: ${poseAngle.toStringAsFixed(1)}°',
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Is this AROM-based pain level accurate for your assessment?',
                style: GoogleFonts.ptSans(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // ALWAYS use AROM assessment result if available (romPainLevel is already from AROM)
                // The _proceedToPainLevelInput will use _currentAssessmentResult if available
                _proceedToPainLevelInput(romPainLevel);
              },
              child: Text('Yes, Continue'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedToPainLevelInput('Manual'); // Let user input manually
              },
              child: Text('No, Input Manually'),
            ),
          ],
        );
      },
    );
  }

  // Proceed to pain level input with detected or manual option
  void _proceedToPainLevelInput(String painLevel) {
    // ALWAYS use AROM assessment result if available, regardless of painLevel parameter
    if (!_painValuesLocked) {
      // ALWAYS prefer AROM assessment result over facial pain detection
      if (_currentAssessmentResult != null) {
        // Use the AROM assessment result values - this is the authoritative source
        UserAssess.painScale = _currentAssessmentResult!.painScore;
        UserAssess.painLevel = _currentAssessmentResult!.categoricalPainLevel;
        AssessmentData.painScale = _currentAssessmentResult!.painScore;
        AssessmentData.painLevel = _currentAssessmentResult!.categoricalPainLevel;
        
        debugPrint('✅ Proceeding to pain level input with AROM result - painScore: ${_currentAssessmentResult!.painScore}, categoricalPainLevel: ${_currentAssessmentResult!.categoricalPainLevel}');
        debugPrint('✅ AROM values set: UserAssess.painScale=${UserAssess.painScale}, UserAssess.painLevel=${UserAssess.painLevel}');
        debugPrint('✅ AROM values set: AssessmentData.painScale=${AssessmentData.painScale}, AssessmentData.painLevel=${AssessmentData.painLevel}');
      } else if (painLevel != 'Manual') {
        // Only use facial pain detection if AROM is not available AND not manual input
        // Fallback to facial pain detection if AROM result not available
        debugPrint('⚠️ AROM assessment not available, using facial pain detection fallback: $painLevel');
        switch (painLevel) {
          case 'Low':
            UserAssess.painScale = 2;
            UserAssess.painLevel = 'Low';
            AssessmentData.painScale = 2;
            AssessmentData.painLevel = 'Low';
            break;
          case 'Moderate':
            UserAssess.painScale = 5;
            UserAssess.painLevel = 'Moderate';
            AssessmentData.painScale = 5;
            AssessmentData.painLevel = 'Moderate';
            break;
          case 'Severe':
            UserAssess.painScale = 8;
            UserAssess.painLevel = 'Severe';
            AssessmentData.painScale = 8;
            AssessmentData.painLevel = 'Severe';
            break;
        }
        debugPrint('Proceeding to pain level input with facial pain detection - painLevel: $painLevel');
      }
    } else if (painLevel == 'Manual' && _currentAssessmentResult != null) {
      // Even for manual input, preserve AROM assessment values as starting point
      UserAssess.painScale = _currentAssessmentResult!.painScore;
      UserAssess.painLevel = _currentAssessmentResult!.categoricalPainLevel;
      AssessmentData.painScale = _currentAssessmentResult!.painScore;
      AssessmentData.painLevel = _currentAssessmentResult!.categoricalPainLevel;
      
      debugPrint('Proceeding to manual pain level input with AROM result as starting point - painScore: ${_currentAssessmentResult!.painScore}');
    }
    
    // Stop pain detection and lock values before navigation (prevents further updates)
    _stopPainDetection();
    
    debugPrint('Final values before navigation - UserAssess.painScale: ${UserAssess.painScale}, UserAssess.painLevel: ${UserAssess.painLevel}');
    debugPrint('Final values before navigation - AssessmentData.painScale: ${AssessmentData.painScale}, AssessmentData.painLevel: ${AssessmentData.painLevel}');
    
    // Navigate directly to pain level input
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AssessPainLevel(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  // Dispose of the camera controller when not needed
  @override
  void dispose() {
    // Stop pain detection and lock values
    _stopPainDetection();
    try { _controller.stopImageStream(); } catch (_) {}
    _painService.dispose(); // Dispose pain detection service
    _painOverlayController.dispose();
    _painBannerController.dispose();
    _painColorController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('AssessPainCamera: build() called');
    print('AssessPainCamera: Current AssessmentData.painScale in build = "${AssessmentData.painScale}"');
    print('AssessPainCamera: Current UserAssess.painScale in build = "${UserAssess.painScale}"');
    print('AssessPainCamera: Current painScale = $painScale');
    
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final currentAngle = _getCurrentAngle();
      return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
            ),
          ],
        ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8B2E2E)),
          onPressed: () async {
            // Stop pain detection and lock values before navigation
            _stopPainDetection();
            try { await _controller.stopImageStream(); } catch (_) {}
            await _controller.dispose();
            setState(() {
              _isCameraInitialized = false;
              _isStreaming = false;
            });
            if (context.mounted) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => AssessPainVideo(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                ),
              );
            }
          },
        ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "ROM Assessment",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            Text(
              "${UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle : 'Muscle Assessment'} (${_selectedSide} Side)",
              style: GoogleFonts.ptSans(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Unified settings button with dropdown menu
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.settings, color: Color(0xFF8B2E2E), size: 20),
              tooltip: 'Settings',
              onSelected: (value) {
                // Don't close menu for skeleton toggle - handled by switch directly
                if (value == 'skeleton') {
                  return;
                }
                switch (value) {
                  case 'help':
                    _showHelpDialog();
                    break;
                  case 'video':
                    setState(() {
                      _enableVideoRecording = !_enableVideoRecording;
                    });
                    break;
                  case 'skeleton_config':
                    _showSkeletonConfigDialog(context);
                    break;
                  case 'switch_camera':
                    _switchCamera();
                    break;
                  case 'left_side':
                    setState(() => _selectedSide = 'Left');
                    break;
                  case 'right_side':
                    setState(() => _selectedSide = 'Right');
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'help',
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline, color: Color(0xFF8B2E2E), size: 18),
                      const SizedBox(width: 12),
                      Text('Assessment Help', style: GoogleFonts.ptSans(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'video',
                  child: Row(
                    children: [
                      Icon(
                        _enableVideoRecording ? Icons.videocam : Icons.videocam_off,
                        color: _enableVideoRecording ? const Color(0xFF8B2E2E) : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text('Video Recording', style: GoogleFonts.ptSans(fontSize: 14)),
                      const Spacer(),
                      Switch(
                        value: _enableVideoRecording,
                        activeColor: const Color(0xFF8B2E2E),
                        onChanged: (value) {
                          setState(() {
                            _enableVideoRecording = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'skeleton',
                  child: Row(
                    children: [
                      const Icon(Icons.scatter_plot, color: Color(0xFF8B2E2E), size: 18),
                      const SizedBox(width: 12),
                      Text('Skeleton Overlay', style: GoogleFonts.ptSans(fontSize: 14)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          // Prevent menu item tap from interfering with switch
                        },
                        child: Switch(
                          value: _showSkeleton,
                          activeColor: const Color(0xFF8B2E2E),
                          onChanged: (value) {
                            setState(() {
                              _showSkeleton = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showSkeleton)
                  PopupMenuItem<String>(
                    value: 'skeleton_config',
                    child: Row(
                      children: [
                        const Icon(Icons.tune, color: Color(0xFF8B2E2E), size: 18),
                        const SizedBox(width: 12),
                        Text('Skeleton Settings', style: GoogleFonts.ptSans(fontSize: 14)),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'switch_camera',
                  child: Row(
                    children: [
                      const Icon(Icons.cameraswitch_rounded, color: Color(0xFF8B2E2E), size: 18),
                      const SizedBox(width: 12),
                      Text('Switch Camera', style: GoogleFonts.ptSans(fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: _selectedSide == 'Left' ? 'right_side' : 'left_side',
                  child: Row(
                    children: [
                      Icon(
                        _selectedSide == 'Left' ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_left,
                        color: const Color(0xFF8B2E2E),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text('Switch to ${_selectedSide == 'Left' ? 'Right' : 'Left'} Side', style: GoogleFonts.ptSans(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera and Assessment Area
          Expanded(
            child: Stack(
              children: [

                // Camera preview optimized for mobile screens
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF8B2E2E).withOpacity(0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18.5),
                    child: _isCameraInitialized
                        ? Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: CameraPreview(_controller),
                              ),
                              // Pain detection status indicator
                              if (_isPainDetectionEnabled) _buildPainDetectionOverlay(),
                              // Pain banner for moderate pain
                              if (_showPainBanner) _buildModeratePainBanner(),
                            ],
                          )
                        : Container(
                            height: 250,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18.5),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    color: Color(0xFF8B2E2E),
                                    strokeWidth: 2.5,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Initializing Camera...',
                                    style: GoogleFonts.ptSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),

                // Consolidated status indicators overlay - mobile optimized
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      // Skeleton toggle indicator
                      if (_showSkeleton)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B2E2E).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility, color: Colors.white, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                'SKELETON',
                                style: GoogleFonts.ptSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (currentAngle != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.straighten, color: Colors.white, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                '${currentAngle.toStringAsFixed(1)}°',
                                style: GoogleFonts.ptSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // Pain score indicator - mobile optimized
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        // Use facial recognition color only
                        color: _getPainColor(_currentPainLevel).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                // Display pain level from facial recognition model (Low, Moderate, or Severe)
                                _currentPainLevel != null && ['Low', 'Moderate', 'Severe'].contains(_currentPainLevel)
                                    ? '$_currentPainLevel Pain'
                                    : _isPainDetectionEnabled 
                                        ? 'Analyzing...' // Show analyzing if model is enabled but no result yet
                                        : 'N/A', // Show N/A if model not enabled
                                style: GoogleFonts.ptSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                // Display pain scale mapped from facial recognition (2, 5, or 8)
                                _currentPainLevel != null && ['Low', 'Moderate', 'Severe'].contains(_currentPainLevel)
                                    ? '${_mapFacialPainScore(_currentPainLevel)}/10'
                                    : '--/10', // Show --/10 if no valid prediction
                                style: GoogleFonts.ptSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),

                // Enhanced pose skeleton overlay with improved positioning
                if (_showSkeleton && _currentKeypoints.isNotEmpty && _cameraImageSize != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Ensure we have valid constraints
                              if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                                return const SizedBox.shrink();
                              }
                              
                              final isFrontCamera = cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front;
                              
                              return CustomPaint(
                                painter: CustomPoseSkeletonPainter(
                                  keypoints: _currentKeypoints,
                                  imageSize: _cameraImageSize,
                                  previewSize: Size(constraints.maxWidth, constraints.maxHeight),
                                  showLandmarkLabels: _skeletonConfig.showLandmarkLabels,
                                  strokeWidth: _skeletonConfig.strokeWidth,
                                  pointRadius: _skeletonConfig.pointRadius,
                                  showConfidence: _skeletonConfig.showConfidence,
                                  mirrorHorizontally: isFrontCamera,
                                ),
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                // Enhanced assessment results panel - translucent and color-coded
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getPainBasedBackgroundColor().withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPainBasedBorderColor().withOpacity(0.6), 
                        width: 1.5
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _getPainBasedAccentColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.analytics,
                                color: _getPainBasedAccentColor(),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Results",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _getPainBasedTextColor(),
                              ),
                            ),
                            const Spacer(),
                            // Assessment mode indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _enableVideoRecording 
                                    ? const Color(0xFF8B2E2E).withOpacity(0.2)
                                    : const Color(0xFF10B981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _enableVideoRecording 
                                      ? const Color(0xFF8B2E2E).withOpacity(0.4)
                                      : const Color(0xFF10B981).withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _enableVideoRecording ? Icons.videocam : Icons.speed,
                                    color: _enableVideoRecording ? const Color(0xFF8B2E2E) : const Color(0xFF10B981),
                                    size: 10,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _enableVideoRecording ? 'VIDEO' : 'REAL-TIME',
                                    style: GoogleFonts.ptSans(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: _enableVideoRecording ? const Color(0xFF8B2E2E) : const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Display assessment results using modular services
                        if (_currentAssessmentResult != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getPainBasedAccentColor().withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getPainBasedAccentColor().withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: _getPainBasedAccentColor(),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _currentAssessmentResult!.displayLabel,
                                        style: GoogleFonts.ptSans(
                                          fontSize: 11,
                                          color: _getPainBasedAccentColor(),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (_currentAssessmentResult!.additionalData['angle'] != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.straighten, color: _getPainBasedTextColor(), size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Angle: ${_currentAssessmentResult!.additionalData['angle'].toStringAsFixed(1)}°',
                                        style: GoogleFonts.ptSans(
                                          fontSize: 10,
                                          color: _getPainBasedTextColor(),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                ],
                                if (_currentAssessmentResult!.additionalData['absNormalizedDisplacement'] != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.trending_up, color: _getPainBasedTextColor(), size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Disp: ${_currentAssessmentResult!.additionalData['absNormalizedDisplacement'].toStringAsFixed(2)}',
                                        style: GoogleFonts.ptSans(
                                          fontSize: 10,
                                          color: _getPainBasedTextColor(),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                ],
                                if (_currentAssessmentResult!.alignment != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.align_horizontal_center, color: _getPainBasedTextColor(), size: 12),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _currentAssessmentResult!.alignment!,
                                          style: GoogleFonts.ptSans(
                                            fontSize: 9,
                                            color: _getPainBasedTextColor(),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                ],
                                if (_currentAssessmentResult!.compensation != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.warning, color: _getPainBasedTextColor(), size: 12),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _currentAssessmentResult!.compensation!,
                                          style: GoogleFonts.ptSans(
                                            fontSize: 9,
                                            color: _getPainBasedTextColor(),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.hourglass_empty, color: Colors.grey, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  '${UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle : 'Muscle'}: Not assessed yet',
                                  style: GoogleFonts.ptSans(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Enhanced bottom action buttons - mobile optimized
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(color: const Color(0xFF8B2E2E).withOpacity(0.06), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -6),
                ),
                BoxShadow(
                  color: const Color(0xFF8B2E2E).withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                
                // Enhanced record button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _isRecording 
                          ? null 
                          : const LinearGradient(
                              colors: [Color(0xFF8B2E2E), Color(0xFFC24A4A)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                      color: _isRecording ? Colors.grey : null,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isRecording 
                            ? Colors.grey.withOpacity(0.2)
                            : const Color(0xFF8B2E2E).withOpacity(0.2), 
                        width: 1
                      ),
                      boxShadow: _isRecording ? [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ] : [
                        BoxShadow(
                          color: const Color(0xFF8B2E2E).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isRecording || _isRealTimeAssessment
                          ? null
                          : () async {
                              setState(() => _isRecording = true);
                              XFile? videoFile = await _startAssessment();
                              setState(() => _isRecording = false);

                            if (videoFile != null) {
                                File file = File(videoFile.path);
                                UserAssess.painVideo = file;
                                
                                if (context.mounted) {
                                  // Bypass video preview and go directly to pain level confirmation
                                  _showPainLevelConfirmationDialog();
                                }
                              } else if (_enableVideoRecording) {
                                debugPrint('Video recording failed or was cancelled.');
                              } else {
                                // Real-time assessment completed
                                if (context.mounted) {
                                  _showPainLevelConfirmationDialog();
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _isRecording || _isRealTimeAssessment
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.5,
                              ),
                            )
                          : Icon(
                              _enableVideoRecording ? Icons.videocam_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                      label: Text(
                        _isRecording 
                            ? (_enableVideoRecording ? "Recording..." : "Assessing...")
                            : (_enableVideoRecording ? "Record Video" : "Start Assessment"),
                        style: GoogleFonts.ptSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    } catch (e) {
      print('AssessPainCamera: ERROR in build() - $e');
      return Container(
        color: kBackgroundColor,
        child: Center(
          child: Text(
            'Error loading camera page: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  // ROM Display Update Methods - moved to modular services

  /// Show comprehensive help dialog for muscle-specific assessment guidance
  /// 
  /// Displays detailed instructions, positioning tips, and troubleshooting
  /// information specific to the selected muscle group and side.
  /// 
  /// The dialog includes:
  /// - Overview of what the assessment measures
  /// - Step-by-step instructions for proper positioning and movement
  /// - Positioning tips for optimal camera capture
  /// - Information about what measurements are taken
  /// - Troubleshooting tips for common issues
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AssessmentHelpDialog(
          muscleGroup: UserAssess.specificMuscle,
          side: _selectedSide,
        );
      },
    );
  }

  void _showSkeletonConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Skeleton Overlay Settings',
                style: GoogleFonts.ptSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show landmark labels toggle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Show Landmark Labels',
                          style: GoogleFonts.ptSans(
                            fontSize: 14,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Switch(
                        value: _skeletonConfig.showLandmarkLabels,
                        activeColor: const Color(0xFF8B2E2E),
                        onChanged: (value) {
                          setDialogState(() {
                            _skeletonConfig = _skeletonConfig.copyWith(showLandmarkLabels: value);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Stroke width slider
                  Text(
                    'Line Thickness: ${_skeletonConfig.strokeWidth.toStringAsFixed(1)}',
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Slider(
                    value: _skeletonConfig.strokeWidth,
                    min: 2.0,
                    max: 8.0,
                    divisions: 12,
                    activeColor: const Color(0xFF8B2E2E),
                    onChanged: (value) {
                      setDialogState(() {
                        _skeletonConfig = _skeletonConfig.copyWith(strokeWidth: value);
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Point radius slider
                  Text(
                    'Point Size: ${_skeletonConfig.pointRadius.toStringAsFixed(1)}',
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Slider(
                    value: _skeletonConfig.pointRadius,
                    min: 3.0,
                    max: 12.0,
                    divisions: 18,
                    activeColor: const Color(0xFF8B2E2E),
                    onChanged: (value) {
                      setDialogState(() {
                        _skeletonConfig = _skeletonConfig.copyWith(pointRadius: value);
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.ptSans(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _skeletonConfig = const SkeletonOverlayConfig();
                    });
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.ptSans(
                      color: const Color(0xFF8B2E2E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // (Removed unused _buildActionButton to satisfy linter)
}


