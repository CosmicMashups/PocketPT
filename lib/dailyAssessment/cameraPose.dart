// Import necessary packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math' as math;

import '../data/globals.dart';
import '../data/custom_pose_detection_service.dart';
import '../widgets/custom_pose_skeleton_painter.dart';
import '../assessment/arom/assessment_service.dart';
import 'instructionVideo.dart';
import 'painLevel.dart';

class CameraPosePage extends StatefulWidget {
  const CameraPosePage({super.key});

  @override
  State<CameraPosePage> createState() => _CameraPosePageState();
}

class _CameraPosePageState extends State<CameraPosePage> {

  int painScale = UserAssess.painScale;
  late CameraController _controller;
  late List<CameraDescription> cameras;
  bool _isCameraInitialized = false;

  // New: pose estimation and camera switching state
  int _selectedCameraIndex = 0;
  String _mode = 'Triceps'; // 'Triceps' or 'Shoulders' (matching Jupyter focus)
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
  bool _isStreaming = false;
  bool _processingFrame = false;
  Timer? _throttleTimer;
  
  // New: Skeleton visualization state
  bool _showSkeleton = false;
  List<Map<String, dynamic>> _currentKeypoints = []; // Raw keypoints from custom model
  Size? _cameraImageSize; // Store camera image dimensions for coordinate scaling

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


  // Initialize the camera
  @override
  void initState() {
    super.initState();
    _initializePoseDetection();
    _initializeCamera();
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
    try {
      cameras = await availableCameras();  // Get available cameras
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }
      
      _controller = CameraController(
        cameras[_selectedCameraIndex],  // Use the selected camera
        ResolutionPreset.high,  // Set the camera resolution
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller.initialize();  // Initialize the camera
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;  // Camera is initialized
      });
      
      // Start image stream after a short delay to ensure camera is ready
      await Future.delayed(const Duration(milliseconds: 500));
      await _startImageStream();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      // Show a friendly permission/setup message if camera can't initialize
      if (mounted) {
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
              return;
            }
            
            // Store keypoints for skeleton visualization
            _currentKeypoints = keypoints;
            debugPrint('Pose detected: ${landmarks.length} landmarks, ${keypoints.length} keypoints');
            
            // Force UI update to show skeleton if enabled
            if (_showSkeleton && mounted) {
              setState(() {});
            }
            
            // Perform ROM assessment using modular AROM services
            try {
              final assessmentResult = AssessmentService.assess(_getAssessmentMode(), landmarks, _selectedSide);
              
              if (mounted) {
                setState(() {
                  // Update UserAssess for integration (continuous tracking)
                  UserAssess.painScale = assessmentResult.painScore;
                  UserAssess.painLevel = assessmentResult.clinicalContext;
                  
                  PainHistory.recordTodayAndSave(
                    painScale: UserAssess.painScale,
                    painLevel: UserAssess.painLevel,
                  );
                });
              }
            } catch (e) {
              debugPrint('Assessment failed: $e');
              // Fallback to basic angle calculation if assessment fails
              final angle = _computeRelevantAngle(landmarks);
              if (angle != null) {
                final score = _mapAngleToScore(angle);
                if (score != UserAssess.painScale) {
                  UserAssess.painScale = score;
                  UserAssess.painLevel = score.toString();
                  PainHistory.recordTodayAndSave(
                    painScale: UserAssess.painScale,
                    painLevel: UserAssess.painLevel,
                  );
                  if (mounted) setState(() {});
                }
              }
            }
          } catch (e) {
            debugPrint('Landmark processing error: $e');
            // Continue processing even if landmark extraction fails
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
                    
                    if (landmarks.isEmpty) return;
                    
                    // Store keypoints for skeleton visualization
                    _currentKeypoints = keypoints;
                    
                    if (_showSkeleton && mounted) {
                      setState(() {});
                    }
                    
                    // Perform ROM assessment using modular AROM services
                    try {
                      final assessmentResult = AssessmentService.assess(_getAssessmentMode(), landmarks, _selectedSide);
                      
                      if (mounted) {
                        setState(() {
                          // Update UserAssess for integration (continuous tracking)
                          UserAssess.painScale = assessmentResult.painScore;
                          UserAssess.painLevel = assessmentResult.clinicalContext;
                          
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

  

  double? _computeRelevantAngle(Map<String, Offset> lm) {
    final side = _selectedSide.toLowerCase();
    
    // Helper function to calculate angle between three points
    double calculateAngle(Offset pointA, Offset vertex, Offset pointB) {
      final v1 = pointA - vertex;
      final v2 = pointB - vertex;
      final dot = v1.dx * v2.dx + v1.dy * v2.dy;
      final mag1 = v1.distance;
      final mag2 = v2.distance;
      if (mag1 == 0 || mag2 == 0) return 0.0;
      final cosTheta = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
      final radians = math.acos(cosTheta);
      return radians * 180.0 / math.pi;
    }
    
    if (_mode == 'Triceps') {
      if (side == 'left' && lm.containsKey('leftHip') && lm.containsKey('leftShoulder') && lm.containsKey('leftElbow')) {
        return calculateAngle(lm['leftHip']!, lm['leftShoulder']!, lm['leftElbow']!);
      } else if (side == 'right' && lm.containsKey('rightHip') && lm.containsKey('rightShoulder') && lm.containsKey('rightElbow')) {
        return calculateAngle(lm['rightHip']!, lm['rightShoulder']!, lm['rightElbow']!);
      }
    } else if (_mode == 'Shoulders') {
      if (side == 'left' && lm.containsKey('leftHip') && lm.containsKey('leftShoulder') && lm.containsKey('leftElbow')) {
        return calculateAngle(lm['leftHip']!, lm['leftShoulder']!, lm['leftElbow']!);
      } else if (side == 'right' && lm.containsKey('rightHip') && lm.containsKey('rightShoulder') && lm.containsKey('rightElbow')) {
        return calculateAngle(lm['rightHip']!, lm['rightShoulder']!, lm['rightElbow']!);
      }
    }
    return null;
  }

  int? _lastProcessedTime; // ms timestamp for throttling

  // Standardized angle to pain score mapping (aligned with clinical standards)
  int _mapAngleToScore(double angle) {
    if (_mode == 'Triceps') {
      // Triceps: 0° (flexed) -> 180° (extended)
      // Using standardized clinical pain scale
      if (angle < 90) return 9; // Severe limitation (8-10 range)
      if (angle < 135) return 6; // Moderate limitation (5-7 range)
      return 1; // Good ROM (0-1 range)
    } else if (_mode == 'Shoulders') {
      // Shoulders: 180° (arm down) -> 90° (T-pose) -> <90° (overhead)
      // Using standardized clinical pain scale
      if (angle < 90) return 9; // Severe pain (8-10 range)
      if (angle <= 110) return 6; // Moderate pain (5-7 range)
      if (angle <= 150) return 3; // Low pain (2-4 range)
      return 1; // Good mobility (0-1 range)
    }
    return 5; // Default moderate when mode is unknown
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

  // Dispose of the camera controller when not needed
  @override
  void dispose() {
    try { _controller.stopImageStream(); } catch (_) {}
    _throttleTimer?.cancel();
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
                  "${_mode} (${_selectedSide})",
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
            "Position yourself in front of the camera and follow the on-screen instructions to assess your ${_mode.toLowerCase()} range of motion.",
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
                              switch (value) {
                                case 'skeleton':
                                  setState(() {
                                    _showSkeleton = !_showSkeleton;
                                    if (!_showSkeleton) {
                                      _currentKeypoints = [];
                                    }
                                  });
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

