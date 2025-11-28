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
import '../assessment/assessment_data.dart';
import '../assessment/arom/assessment_service.dart';
import '../assessment/arom/assessment_result.dart';
import '../core/animations.dart';
import 'instructionVideo.dart';
import 'painLevel.dart';

class CameraPosePage extends StatefulWidget {
  const CameraPosePage({super.key});

  @override
  State<CameraPosePage> createState() => _CameraPosePageState();
}

class _CameraPosePageState extends State<CameraPosePage> with TickerProviderStateMixin {

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
  
  // Pain recognition state variables
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


  // Initialize the camera
  @override
  void initState() {
    super.initState();
    print('CameraPosePage: initState() called');
    print('CameraPosePage: Current AssessmentData.painScale = "${AssessmentData.painScale}"');
    print('CameraPosePage: Current UserAssess.painScale = "${UserAssess.painScale}"');
    
    // Initialize pain scale from local data
    painScale = UserAssess.painScale;
    print('CameraPosePage: painScale initialized to: $painScale');
    
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
    print('CameraPosePage: initState() completed');
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
      // Retry once to improve first-run reliability on some devices
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
        debugPrint('Pain detection initialized successfully for daily assessment');
      }
    } catch (e) {
      debugPrint('Error initializing pain detection: $e');
      if (mounted) {
        setState(() {
          _isPainDetectionEnabled = false;
        });
      }
      // Graceful degradation: Continue assessment without pain detection
      debugPrint('Daily assessment will continue without automatic pain detection');
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

  /// Get current pain score for display
  /// Uses AROM assessment painScore when available (more accurate),
  /// falls back to facial recognition mapping if AROM not available
  int _getCurrentPainScore() {
    // Prefer AROM assessment painScore as it's more accurate (0-10 scale)
    if (_currentAssessmentResult != null) {
      return _currentAssessmentResult!.painScore;
    }
    
    // Fallback to facial recognition mapping if AROM not available
    return _mapFacialPainScore(_currentPainLevel);
  }
  
  // Map facial pain level to pain scale
  int _mapFacialPainScore(String? painLevel) {
    switch (painLevel) {
      case 'Low':
        return 2;
      case 'Moderate':
        return 5;
      case 'Severe':
        return 8;
      default:
        // Return 0 to indicate no valid pain level instead of hardcoded 2
        return 0; // Will be handled by UI to show "N/A" or last known value
    }
  }


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
                _currentPainLevel ?? 'Low',
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
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(_painBannerSlideAnimation),
        child: FadeTransition(
          opacity: _painBannerFadeAnimation,
          child: bannerContent,
        ),
      ),
    );
  }

  // Build information button for assessment instructions
  Widget _buildInstructionsButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _showHelpDialog,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  // Dispose of the camera controller when not needed
  @override
  void dispose() {
    // Stop pain detection and lock values
    _stopPainDetection();
    try { _controller.stopImageStream(); } catch (_) {}
    _throttleTimer?.cancel();
    _painService.dispose(); // Dispose pain detection service
    _painOverlayController.dispose();
    _painBannerController.dispose();
    _painColorController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildAppBar(context, isDark),
          Expanded(
            child: _buildBody(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: const Color(0xFF8B2E2E),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () async {
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
                    pageBuilder: (context, animation, secondaryAnimation) => const InstructionVideoPage(),
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Daily Assessment",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle : 'Muscle Assessment'} (${_selectedSide} Side)",
                  style: GoogleFonts.ptSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.refresh, color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Section
            _buildProgressSection(),
            const SizedBox(height: 24),
            
            // Camera and Assessment Area
            _buildCameraSection(context, isDark),
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(context),
            const SizedBox(height: 16),
            
            // Skip Button
            _buildSkipButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt, color: Color(0xFF8B2E2E), size: 20),
              const SizedBox(width: 8),
              Text(
                "Assessment Progress",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Text(
                "Step 2 of 3",
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.66,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam, color: Color(0xFF8B2E2E), size: 20),
              const SizedBox(width: 8),
              Text(
                "Camera Assessment",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Position yourself in front of the camera and follow the on-screen instructions to assess your ${UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle.toLowerCase() : 'muscle'} range of motion.",
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          
          // Camera Preview
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: _isCameraInitialized
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CameraPreview(_controller),
                      ),
                      // Skeleton overlay
                      if (_showSkeleton && _currentKeypoints.isNotEmpty && _cameraImageSize != null)
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isFrontCamera = cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front;
                              return CustomPaint(
                                painter: CustomPoseSkeletonPainter(
                                  keypoints: _currentKeypoints,
                                  imageSize: _cameraImageSize!,
                                  previewSize: Size(constraints.maxWidth, constraints.maxHeight),
                                  showLandmarkLabels: _skeletonConfig.showLandmarkLabels,
                                  strokeWidth: _skeletonConfig.strokeWidth,
                                  pointRadius: _skeletonConfig.pointRadius,
                                  showConfidence: _skeletonConfig.showConfidence,
                                  mirrorHorizontally: isFrontCamera,
                                ),
                              );
                            },
                          ),
                        ),
                      // Pain detection status overlay
                      if (_isPainDetectionEnabled) _buildPainDetectionOverlay(),
                      // Pain banner for moderate pain
                      if (_showPainBanner) _buildModeratePainBanner(),
                      // Instructions button
                      _buildInstructionsButton(),
                      // Status indicators overlay
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          children: [
                            // LIVE indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.95),
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
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'LIVE',
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
                            // Pain score indicator - mobile optimized
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
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
                                        _currentAssessmentResult != null
                                            ? '${_currentAssessmentResult!.categoricalPainLevel} Pain (AROM)'
                                            : '${_currentPainLevel ?? 'Low'} Pain (Facial)',
                                        style: GoogleFonts.ptSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        _getCurrentPainScore() > 0 
                                            ? '${_getCurrentPainScore()}/10'
                                            : (_currentPainLevel ?? 'N/A'),
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
                            // Angle indicator if available
                            if (_getCurrentAngle() != null) ...[
                              const SizedBox(width: 6),
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
                                      '${_getCurrentAngle()!.toStringAsFixed(1)}°',
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
                            ],
                          ],
                        ),
                      ),
                      // Unified camera controls overlay
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.settings, color: Color(0xFF8B2E2E), size: 20),
                            tooltip: 'Camera Settings',
                            onSelected: (value) {
                              // Don't close menu for skeleton toggle - handled by switch directly
                              if (value == 'skeleton') {
                                return;
                              }
                              switch (value) {
                                case 'help':
                                  _showHelpDialog();
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
                                value: 'skeleton',
                                child: Row(
                                  children: [
                                    Icon(
                                      _showSkeleton ? Icons.visibility : Icons.visibility_off,
                                      color: const Color(0xFF8B2E2E),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Skeleton Overlay', style: GoogleFonts.ptSans(fontSize: 14)),
                                    const Spacer(),
                                    Switch(
                                      value: _showSkeleton,
                                      activeColor: const Color(0xFF8B2E2E),
                                      onChanged: (value) {
                                        setState(() {
                                          _showSkeleton = value;
                                          if (!_showSkeleton) {
                                            _currentKeypoints = [];
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
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
                      ),
                      // Skeleton overlay
                      if (_showSkeleton && _currentKeypoints.isNotEmpty && _cameraImageSize != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
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
                                      showLandmarkLabels: false,
                                      strokeWidth: 3.0,
                                      pointRadius: 6.0,
                                      showConfidence: false,
                                      mirrorHorizontally: isFrontCamera,
                                    ),
                                    size: Size(constraints.maxWidth, constraints.maxHeight),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF8B2E2E)),
                          SizedBox(height: 16),
                          Text(
                            'Initializing Camera...',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Skip button
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8B2E2E)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                try { await _controller.stopImageStream(); } catch (_) {}
                await _controller.dispose();
                if (mounted) {
                  setState(() {
                    _isCameraInitialized = false;
                    _isStreaming = false;
                  });
                }
                if (context.mounted) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const PainLevelPage(),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.skip_next, color: Color(0xFF8B2E2E), size: 20),
              label: Text(
                "Skip to Pain Level",
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B2E2E),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Complete button
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B2E2E), Color(0xFFC24A4A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B2E2E).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                try { await _controller.stopImageStream(); } catch (_) {}
                await _controller.dispose();
                if (mounted) {
                  setState(() {
                    _isCameraInitialized = false;
                    _isStreaming = false;
                  });
                }
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.check, color: Colors.white, size: 20),
              label: Text(
                "Complete Assessment",
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () async {
          try { await _controller.stopImageStream(); } catch (_) {}
          await _controller.dispose();
          if (mounted) {
            setState(() {
              _isCameraInitialized = false;
              _isStreaming = false;
            });
          }
          if (context.mounted) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const PainLevelPage(),
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
        child: Text(
          "Skip to Pain Level Assessment",
          style: GoogleFonts.ptSans(
            fontSize: 14,
            color: const Color(0xFF6B7280),
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


}

