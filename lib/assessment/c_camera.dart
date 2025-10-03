// Import necessary packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import '../data/globals.dart';
import '../main.dart';
import '../data/pose_detection_service.dart';
import '../widgets/enhanced_pose_skeleton_painter.dart';
import 'c_video.dart';
import 'c_upload.dart';
import 'c_videopreview.dart';

class AssessPainCamera extends StatefulWidget {
  const AssessPainCamera({super.key});

  @override
  State<AssessPainCamera> createState() => _AssessPainCameraState();
}

class _AssessPainCameraState extends State<AssessPainCamera> {
  // Constants matching Jupyter Python code
  static const double CALF_SEVERE_THRESHOLD = 0.15;  // Normalized displacement < 0.15 -> Severe
  static const double CALF_MODERATE_THRESHOLD = 0.30;  // 0.15 <= displacement < 0.30 -> Moderate
  static const double HAMSTRING_SEVERE_THRESHOLD = 60.0;  // Angle < 60° -> Severe
  static const double HAMSTRING_MODERATE_THRESHOLD = 80.0;  // 60° <= Angle < 80° -> Moderate
  static const double PELVIC_COMPENSATION_THRESHOLD_NORM = 0.05; // Vertical difference > 5% of body height proxy -> Warning

  int painScale = UserAssess.painScale;
  late CameraController _controller;
  late List<CameraDescription> cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;

  // New: pose estimation and camera switching state
  int _selectedCameraIndex = 0;
  String _mode = 'Triceps'; // 'Triceps' or 'Shoulders' (matching Jupyter focus)
  String _selectedSide = 'Right'; // 'Left' or 'Right' side to assess
  final PoseDetectionService _poseService = PoseDetectionService();
  bool _isStreaming = false;
  bool _processingFrame = false;
  Timer? _throttleTimer;
  double? _lastComputedAngle;
  int? _lastProcessedTime; // ms timestamp for throttling
  
  // ROM Assessment Results
  Map<String, dynamic>? _romResults;
  Map<String, dynamic>? _compensations;
  String? _currentROMLabel;
  Color? _currentROMColor;
  int _overallPainScore = 0;

  // New: Calf dorsiflexion analysis state
  String _calfROMLevel = "Calf: Not visible";
  Color _calfDisplayColor = Colors.white;
  String _calfAlignment = "Alignment: N/A";
  double? _calfNormDisplacement;

  // New: Hamstring ROM analysis state
  String _hamstringROMLevel = "Hamstring: Not visible";
  Color _hamstringDisplayColor = Colors.white;
  String _hamstringCompensation = "Compensation: N/A";
  double _hamstringAngle = 0.0;

  // New: Skeleton visualization state
  bool _showSkeleton = false;
  Map<String, Offset>? _currentLandmarks;
  SkeletonOverlayConfig _skeletonConfig = const SkeletonOverlayConfig();

  // Start recording video while maintaining pose detection
  Future<XFile?> _startRecording() async {
    if (!_controller.value.isInitialized || _controller.value.isRecordingVideo) {
      return null;
    }

    try {
      // Start video recording while keeping image stream active for pose detection
      await _controller.startVideoRecording();
      
      // Continue pose detection during recording
      // Wait for 10 seconds while pose detection continues
      await Future.delayed(const Duration(seconds: 10));

      // Stop video recording but keep image stream for pose detection
      XFile videoFile = await _controller.stopVideoRecording();
      return videoFile;
    } catch (e) {
      debugPrint('Error recording video: $e');
      return null;
    }
  }

  // Initialize the camera
  @override
  void initState() {
    super.initState();
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
        final poses = await _poseService.detectFromCameraImage(image: image, camera: cameras[_selectedCameraIndex]);
        if (poses.isNotEmpty) {
          final landmarks = _poseService.getPoseLandmarks(poses.first);
          
          // Validate landmarks before processing
          if (landmarks.isEmpty) {
            return;
          }
          
          // Store landmarks for skeleton visualization
          if (_showSkeleton) {
            _currentLandmarks = landmarks;
            debugPrint('Pose detected: ${landmarks.length} landmarks'); // Debug output
            // Force UI update to show skeleton
            if (mounted) setState(() {});
          }
          
          // Perform ROM assessment based on selected mode (continues during recording)
          if (_mode == 'Triceps' || _mode == 'Shoulders') {
            // Use existing comprehensive ROM assessment for upper body
            try {
              final assessment = _poseService.performComprehensiveROMAssessment(landmarks);
              
              if (mounted && assessment.isNotEmpty) {
                setState(() {
                  _romResults = assessment;
                  _compensations = assessment['compensations'];
                  _overallPainScore = assessment['overallPainScore'] ?? 0;
                  
                  // Update current ROM display based on mode
                  _updateCurrentROMDisplay();
                  
                  // Update UserAssess for integration (persists during recording)
                  UserAssess.painScale = _overallPainScore;
                  UserAssess.painLevel = _overallPainScore.toString();
                  
                  // Add clinical context for better user understanding
                  if (assessment.containsKey('painDescription')) {
                    UserAssess.painLevel = assessment['painDescription'];
                  }
                  
                  PainHistory.recordTodayAndSave(
                    painScale: UserAssess.painScale,
                    painLevel: UserAssess.painLevel,
                  );
                });
              }
            } catch (e) {
              debugPrint('Comprehensive assessment failed: $e');
              // Fallback to basic angle calculation if comprehensive assessment fails
              final angle = _computeRelevantAngle(landmarks);
              if (angle != null) {
                _lastComputedAngle = angle;
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
          } else if (_mode == 'Calf') {
            // Use new calf analysis (continues during recording)
            _analyzeCalfDorsiflexion(landmarks);
            if (mounted) setState(() {});
          } else if (_mode == 'Hamstrings') {
            // Use new hamstring analysis (continues during recording)
            _analyzeHamstringROM(landmarks);
            if (mounted) setState(() {});
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
                final poses = await _poseService.detectFromCameraImage(image: image, camera: cameras[_selectedCameraIndex]);
                if (poses.isNotEmpty) {
                  final landmarks = _poseService.getPoseLandmarks(poses.first);
                  if (landmarks.isEmpty) return;
                  if (_showSkeleton) {
                    _currentLandmarks = landmarks;
                    if (mounted) setState(() {});
                  }
                  if (_mode == 'Triceps' || _mode == 'Shoulders') {
                    try {
                      final assessment = _poseService.performComprehensiveROMAssessment(landmarks);
                      if (mounted && assessment.isNotEmpty) {
                        setState(() {
                          _romResults = assessment;
                          _compensations = assessment['compensations'];
                          _overallPainScore = assessment['overallPainScore'] ?? 0;
                          _updateCurrentROMDisplay();
                          UserAssess.painScale = _overallPainScore;
                          UserAssess.painLevel = _overallPainScore.toString();
                          if (assessment.containsKey('painDescription')) {
                            UserAssess.painLevel = assessment['painDescription'];
                          }
                          PainHistory.recordTodayAndSave(
                            painScale: UserAssess.painScale,
                            painLevel: UserAssess.painLevel,
                          );
                        });
                      }
                    } catch (_) {}
                  } else if (_mode == 'Calf') {
                    _analyzeCalfDorsiflexion(landmarks);
                    if (mounted) setState(() {});
                  } else if (_mode == 'Hamstrings') {
                    _analyzeHamstringROM(landmarks);
                    if (mounted) setState(() {});
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
    
    if (_mode == 'Triceps') {
      if (side == 'left' && lm.containsKey('leftShoulder') && lm.containsKey('leftElbow') && lm.containsKey('leftWrist')) {
        return _poseService.calculateAngle(lm['leftShoulder']!, lm['leftElbow']!, lm['leftWrist']!);
      } else if (side == 'right' && lm.containsKey('rightShoulder') && lm.containsKey('rightElbow') && lm.containsKey('rightWrist')) {
        return _poseService.calculateAngle(lm['rightShoulder']!, lm['rightElbow']!, lm['rightWrist']!);
      }
    } else if (_mode == 'Shoulders') {
      if (side == 'left' && lm.containsKey('leftHip') && lm.containsKey('leftShoulder') && lm.containsKey('leftElbow')) {
        return _poseService.calculateAngle(lm['leftHip']!, lm['leftShoulder']!, lm['leftElbow']!);
      } else if (side == 'right' && lm.containsKey('rightHip') && lm.containsKey('rightShoulder') && lm.containsKey('rightElbow')) {
        return _poseService.calculateAngle(lm['rightHip']!, lm['rightShoulder']!, lm['rightElbow']!);
      }
    }
    return null;
  }

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

  // New: Calf dorsiflexion analysis based on Jupyter code
  void _analyzeCalfDorsiflexion(Map<String, Offset> landmarks) {
    try {
      // Get relevant landmarks based on selected side
      final side = _selectedSide.toLowerCase();
      final hip = landmarks['${side}Hip'];
      final knee = landmarks['${side}Knee'];
      final ankle = landmarks['${side}Ankle'];
      final heel = landmarks['${side}Heel'];

      if (hip == null || knee == null || ankle == null || heel == null) {
        _calfROMLevel = "Calf: Not visible";
        _calfDisplayColor = Colors.white;
        _calfAlignment = "Alignment: N/A";
        _calfNormDisplacement = null;
        return;
      }

      // Calculate horizontal displacement between knee and ankle
      final horizontalDisplacement = knee.dx - ankle.dx;
      
      // Calculate vertical distance between hip and ankle as body height proxy
      final bodySegmentHeight = (hip.dy - ankle.dy).abs();
      
      if (bodySegmentHeight < 10) {
        _calfROMLevel = "Calf: Adjust position";
        _calfDisplayColor = Colors.yellow;
        _calfNormDisplacement = null;
        _calfAlignment = "Alignment: N/A";
        return;
      }

      // Normalize horizontal displacement by body segment height
      _calfNormDisplacement = horizontalDisplacement / bodySegmentHeight;
      final absNormDisplacement = _calfNormDisplacement?.abs() ?? 0.0;

      // ROM Classification based on normalized displacement
      // Using exact thresholds from Jupyter code
      if (absNormDisplacement < CALF_SEVERE_THRESHOLD) {
        _calfROMLevel = "Calf ROM: Severe (< ${CALF_SEVERE_THRESHOLD.toStringAsFixed(2)})";
        _calfDisplayColor = Colors.red;
      } else if (absNormDisplacement < CALF_MODERATE_THRESHOLD) {
        _calfROMLevel = "Calf ROM: Moderate (${CALF_SEVERE_THRESHOLD.toStringAsFixed(2)}-${CALF_MODERATE_THRESHOLD.toStringAsFixed(2)})";
        _calfDisplayColor = Colors.orange;
      } else { // absNormDisplacement >= CALF_MODERATE_THRESHOLD
        _calfROMLevel = "Calf ROM: Good (> ${CALF_MODERATE_THRESHOLD.toStringAsFixed(2)})";
        _calfDisplayColor = Colors.green;
      }

      // Check knee-over-ankle alignment
      if (knee.dx > ankle.dx) {
        _calfAlignment = "Alignment: Knee Forward";
      } else {
        _calfAlignment = "Alignment: Knee Behind/Inline";
      }

      // Update pain score based on ROM level (using standardized clinical scale)
      if (absNormDisplacement < CALF_SEVERE_THRESHOLD) {
        UserAssess.painScale = 9; // Severe (8-10 range)
      } else if (absNormDisplacement < CALF_MODERATE_THRESHOLD) {
        UserAssess.painScale = 6; // Moderate (5-7 range)
      } else { // absNormDisplacement >= CALF_MODERATE_THRESHOLD
        UserAssess.painScale = 1; // Good (0-1 range)
      }
      UserAssess.painLevel = UserAssess.painScale.toString();
      PainHistory.recordTodayAndSave(
        painScale: UserAssess.painScale,
        painLevel: UserAssess.painLevel,
      );

    } catch (e) {
      debugPrint('Calf analysis error: $e');
      _calfROMLevel = "Calf: Error";
      _calfDisplayColor = Colors.red;
      _calfAlignment = "Alignment: Error";
      _calfNormDisplacement = null;
    }
  }

  // New: Hamstring ROM analysis based on Jupyter code
  void _analyzeHamstringROM(Map<String, Offset> landmarks) {
    try {
      // Get relevant landmarks based on selected side
      final side = _selectedSide.toLowerCase();
      final hip = landmarks['${side}Hip'];
      final knee = landmarks['${side}Knee'];
      final ankle = landmarks['${side}Ankle'];
      final hipL = landmarks['leftHip'];
      final hipR = landmarks['rightHip'];
      final shoulderR = landmarks['rightShoulder'];
      final shoulderL = landmarks['leftShoulder'];

      if (hip == null || knee == null || ankle == null || 
          hipL == null || hipR == null || shoulderR == null || shoulderL == null) {
        _hamstringROMLevel = "Hamstring: Not visible";
        _hamstringDisplayColor = Colors.white;
        _hamstringCompensation = "Compensation: N/A";
        return;
      }

      // Calculate hamstring angle (angle between hip-ankle and vertical axis)
      _hamstringAngle = _calculateVerticalAngle(hip, ankle);

      // ROM Classification based on angle (using standardized clinical scale)
      if (_hamstringAngle < HAMSTRING_SEVERE_THRESHOLD) {
        _hamstringROMLevel = "Hamstring ROM: Severe (< ${HAMSTRING_SEVERE_THRESHOLD.toInt()}°)";
        _hamstringDisplayColor = Colors.red;
        UserAssess.painScale = 9; // Severe (8-10 range)
      } else if (_hamstringAngle < HAMSTRING_MODERATE_THRESHOLD) {
        _hamstringROMLevel = "Hamstring ROM: Moderate (${HAMSTRING_SEVERE_THRESHOLD.toInt()}-${HAMSTRING_MODERATE_THRESHOLD.toInt()}°)";
        _hamstringDisplayColor = Colors.orange;
        UserAssess.painScale = 6; // Moderate (5-7 range)
      } else { // _hamstringAngle >= HAMSTRING_MODERATE_THRESHOLD
        _hamstringROMLevel = "Hamstring ROM: Good (> ${HAMSTRING_MODERATE_THRESHOLD.toInt()}°)";
        _hamstringDisplayColor = Colors.green;
        UserAssess.painScale = 1; // Good (0-1 range)
      }
      UserAssess.painLevel = UserAssess.painScale.toString();
      PainHistory.recordTodayAndSave(
        painScale: UserAssess.painScale,
        painLevel: UserAssess.painLevel,
      );

      // Check for pelvic compensation
      final verticalHipDifference = (hipR.dy - hipL.dy).abs();
      final avgShoulderY = (shoulderR.dy + shoulderL.dy) / 2;
      final avgHipY = (hipR.dy + hipL.dy) / 2;
      final torsoHeightProxy = (avgShoulderY - avgHipY).abs();

      if (torsoHeightProxy > 5) {
        final normVerticalHipDifference = verticalHipDifference / torsoHeightProxy;
        
        if (normVerticalHipDifference > PELVIC_COMPENSATION_THRESHOLD_NORM) { // 5% threshold from Jupyter code
          _hamstringCompensation = "Compensation: Pelvic Tilt (${normVerticalHipDifference.toStringAsFixed(2)})";
        } else {
          _hamstringCompensation = "Compensation: Stable";
        }
      } else {
        _hamstringCompensation = "Compensation: Cannot assess (Torso too flat)";
      }

    } catch (e) {
      debugPrint('Hamstring analysis error: $e');
      _hamstringROMLevel = "Hamstring: Error";
      _hamstringDisplayColor = Colors.red;
      _hamstringCompensation = "Compensation: Error";
      _hamstringAngle = 0.0;
    }
  }

  // Helper method to calculate vertical angle
  double _calculateVerticalAngle(Offset point1, Offset point2) {
    // Vector from point1 to point2
    final vector = point2 - point1;
    
    // Vertical vector pointing upwards (negative Y in Flutter)
    final verticalVector = const Offset(0, -1);
    
    final normVector = vector.distance;
    final normVertical = verticalVector.distance;
    
    if (normVector == 0 || normVertical == 0) {
      return 0.0;
    }
    
    // Calculate cosine of the angle
    final cosineAngle = (vector.dx * verticalVector.dx + vector.dy * verticalVector.dy) / (normVector * normVertical);
    
    // Clamp to prevent floating point errors
    final clampedCosine = cosineAngle.clamp(-1.0, 1.0);
    
    // Calculate angle in radians and convert to degrees
    final angleRadians = math.acos(clampedCosine);
    final angleDegrees = (angleRadians * 180) / math.pi;
    
    return angleDegrees;
  }

  // Color coding for pain scores
  Color _getScoreColor(int score) {
    if (score <= 3) return Colors.green;      // Good (0-3)
    if (score <= 7) return Colors.orange;     // Moderate (4-7)
    return Colors.red;                         // Severe (8-10)
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
    });
    await _initializeCamera();
  }

  // Dispose of the camera controller when not needed
  @override
  void dispose() {
    try { _controller.stopImageStream(); } catch (_) {}
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width;

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              "${_mode} (${_selectedSide} Side)",
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
          // Assessment mode dropdown
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _mode,
              items: const [
                DropdownMenuItem(value: 'Triceps', child: Text('Triceps')),
                DropdownMenuItem(value: 'Shoulders', child: Text('Shoulders')),
                DropdownMenuItem(value: 'Hamstrings', child: Text('Hamstrings')),
                DropdownMenuItem(value: 'Calf', child: Text('Calf')),
              ],
              onChanged: (val) {
                if (val == null) return;
                setState(() => _mode = val);
              },
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
            ),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF6B7280)),
          ),
            ),
          ),
          // Side selection dropdown
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSide,
                items: const [
                  DropdownMenuItem(value: 'Left', child: Text('Left')),
                  DropdownMenuItem(value: 'Right', child: Text('Right')),
                ],
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedSide = val);
                },
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF6B7280)),
                ),
              ),
            ),
          // Enhanced skeleton overlay toggle with configuration
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.scatter_plot, size: 16, color: Color(0xFF8B2E2E)),
                const SizedBox(width: 6),
                Text('Skeleton', style: GoogleFonts.ptSans(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF1F2937))),
                Switch(
                  value: _showSkeleton,
                  activeColor: const Color(0xFF8B2E2E),
                  onChanged: (val) => setState(() {
                    _showSkeleton = val;
                    if (!val) _currentLandmarks = null;
                  }),
                ),
                if (_showSkeleton) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showSkeletonConfigDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B2E2E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.settings, size: 12, color: Color(0xFF8B2E2E)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Camera switch button
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
            child: IconButton(
            tooltip: 'Switch camera',
              icon: const Icon(Icons.cameraswitch_rounded, color: Color(0xFF6B7280), size: 20),
            onPressed: _switchCamera,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Compact Progress Section
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B2E2E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF8B2E2E),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ROM Assessment",
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: 0.6,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "3/5",
                  style: GoogleFonts.ptSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B2E2E),
                  ),
                ),
              ],
            ),
          ),

          // Camera and Assessment Area
          Expanded(
            child: Stack(
              children: [

                // Camera preview with cleaner design
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _isCameraInitialized
                        ? Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: CameraPreview(_controller),
                              ),
                              // Minimal status indicator
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'LIVE',
                                        style: GoogleFonts.ptSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
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

                // Clean status indicators overlay
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      // Skeleton toggle indicator
                      if (_showSkeleton)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B2E2E).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'SKELETON',
                                style: GoogleFonts.ptSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // Pain score indicator - more prominent
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getScoreColor(UserAssess.painScale).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${UserAssess.painScale}/10',
                              style: GoogleFonts.ptSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Enhanced pose skeleton overlay
                if (_showSkeleton && _currentLandmarks != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CustomPaint(
                            painter: EnhancedPoseSkeletonPainter(
                              landmarks: _currentLandmarks!,
                              showLandmarkLabels: _skeletonConfig.showLandmarkLabels,
                              strokeWidth: _skeletonConfig.strokeWidth,
                              pointRadius: _skeletonConfig.pointRadius,
                              showConfidence: _skeletonConfig.showConfidence,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Clean instructions overlay
                Positioned(
                  bottom: 120,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF8B2E2E).withOpacity(0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Assessment Instructions",
                              style: GoogleFonts.ptSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getModeInstructions(),
                          style: GoogleFonts.ptSans(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B2E2E).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF8B2E2E).withOpacity(0.5), width: 1),
                          ),
                          child: Text(
                            '${_selectedSide} Side',
                            style: GoogleFonts.ptSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Compact assessment results
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
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
                            Icon(
                              Icons.analytics,
                              color: const Color(0xFF8B2E2E),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Results",
                              style: GoogleFonts.ptSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Display results based on mode
                        if (_mode == 'Triceps' || _mode == 'Shoulders') ...[
                          if (_currentROMLabel != null) ...[
                            Text(
                              _currentROMLabel!,
                              style: GoogleFonts.ptSans(
                                fontSize: 11,
                                color: _currentROMColor ?? const Color(0xFF1F2937),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            'Angle: ${_lastComputedAngle?.toStringAsFixed(1) ?? '--'}°',
                            style: GoogleFonts.ptSans(
                              fontSize: 10,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          if (_compensations != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Comp: ${_compensations.toString().length > 20 ? _compensations.toString().substring(0, 20) + '...' : _compensations.toString()}',
                              style: GoogleFonts.ptSans(
                                fontSize: 9,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ] else if (_mode == 'Calf') ...[
                          Text(
                            _calfROMLevel,
                            style: GoogleFonts.ptSans(
                              fontSize: 11,
                              color: _calfDisplayColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Disp: ${_calfNormDisplacement?.toStringAsFixed(2) ?? 'N/A'}',
                            style: GoogleFonts.ptSans(
                              fontSize: 10,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _calfAlignment,
                            style: GoogleFonts.ptSans(
                              fontSize: 9,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ] else if (_mode == 'Hamstrings') ...[
                          Text(
                            _hamstringROMLevel,
                            style: GoogleFonts.ptSans(
                              fontSize: 11,
                              color: _hamstringDisplayColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Angle: ${_hamstringAngle.toStringAsFixed(1)}°',
                            style: GoogleFonts.ptSans(
                              fontSize: 10,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _hamstringCompensation,
                            style: GoogleFonts.ptSans(
                              fontSize: 9,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Clean bottom action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Upload button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
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
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AssessPainUpload()));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.upload_file, color: Color(0xFF6B7280), size: 18),
                      label: Text(
                        "Upload Video",
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Record button
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
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isRecording ? null : [
                        BoxShadow(
                          color: const Color(0xFF8B2E2E).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isRecording
                          ? null
                          : () async {
                              setState(() => _isRecording = true);
                              XFile? videoFile = await _startRecording();
                              setState(() => _isRecording = false);

                            if (videoFile != null) {
                                File file = File(videoFile.path);
                                UserAssess.painVideo = file;
                                
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AssessPainVideoPreview(videoPath: file.path)),
                                  );
                                }
                              } else {
                                debugPrint('Recording failed or was cancelled.');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isRecording 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                      label: Text(
                        _isRecording ? "Recording..." : "Record Video",
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
            ),
          ),
        ],
      ),
    );
  }

  // ROM Display Update Methods
  void _updateCurrentROMDisplay() {
    if (_romResults == null) return;
    
    switch (_mode) {
      case 'Triceps':
        final leftTriceps = _romResults!['triceps']['leftTricepsLabel'];
        final rightTriceps = _romResults!['triceps']['rightTricepsLabel'];
        _currentROMLabel = 'Left: $leftTriceps\nRight: $rightTriceps';
        _currentROMColor = _getROMColor(_romResults!['triceps']['leftTricepsROM'] ?? 'good');
        break;
      case 'Shoulders':
        final leftShoulder = _romResults!['shoulders']['leftShoulderLabel'];
        final rightShoulder = _romResults!['shoulders']['rightShoulderLabel'];
        _currentROMLabel = 'Left: $leftShoulder\nRight: $rightShoulder';
        _currentROMColor = _getROMColor(_romResults!['shoulders']['leftShoulderROM'] ?? 'good');
        break;
      case 'Calf':
        _currentROMLabel = _calfROMLevel;
        _currentROMColor = _calfDisplayColor;
        break;
      case 'Hamstrings':
        _currentROMLabel = _hamstringROMLevel;
        _currentROMColor = _hamstringDisplayColor;
        break;
    }
  }

  Color _getROMColor(String romLevel) {
    switch (romLevel) {
      case 'severe':
        return Colors.red; // Red for severe
      case 'moderate':
        return Colors.orange; // Orange for moderate
      case 'low':
        return Colors.yellow; // Yellow for low pain
      case 'good':
        return Colors.green; // Green for good
      default:
        return Colors.grey;
    }
  }

  String _getModeInstructions() {
    switch (_mode) {
      case 'Triceps':
        return "Extend your ${_selectedSide.toLowerCase()} arm fully (elbow straight) for triceps assessment";
      case 'Shoulders':
        return "Raise your ${_selectedSide.toLowerCase()} arm overhead or to T-pose for shoulder assessment";
      case 'Calf':
        return "Stand side-on to camera, perform knee-to-wall motion with your ${_selectedSide.toLowerCase()} leg for calf assessment";
      case 'Hamstrings':
        return "Lie on back, side-on to camera, raise your ${_selectedSide.toLowerCase()} leg straight for hamstring assessment";
      default:
        return "Follow the on-screen instructions";
    }
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


