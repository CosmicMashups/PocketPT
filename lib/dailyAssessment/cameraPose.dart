// Import necessary packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math' as math;

import '../data/globals.dart';
import '../data/pose_detection_service.dart';
import 'instructionVideo.dart';
import 'painLevel.dart';

class CameraPosePage extends StatefulWidget {
  const CameraPosePage({super.key});

  @override
  State<CameraPosePage> createState() => _CameraPosePageState();
}

class _CameraPosePageState extends State<CameraPosePage> {
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

  // New: pose estimation and camera switching state
  int _selectedCameraIndex = 0;
  String _mode = 'Triceps'; // 'Triceps' or 'Shoulders' (matching Jupyter focus)
  String _selectedSide = 'Right'; // 'Left' or 'Right' side to assess
  final PoseDetectionService _poseService = PoseDetectionService();
  bool _isStreaming = false;
  bool _processingFrame = false;
  Timer? _throttleTimer;
  double? _lastComputedAngle;
  
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
      print('Camera not initialized, attempting to initialize...');
      _initializeCamera();
    }
  }

  // Initialize the camera and set the controller
  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();  // Get available cameras
      if (cameras.isEmpty) {
        print('No cameras available');
        return;
      }
      
      _controller = CameraController(
        cameras[_selectedCameraIndex],  // Use the selected camera
        ResolutionPreset.high,  // Set the camera resolution
        enableAudio: false,
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
      print('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _startImageStream() async {
    if (_isStreaming || !_controller.value.isInitialized) {
      print('Cannot start image stream: isStreaming=$_isStreaming, isInitialized=${_controller.value.isInitialized}');
      return;
    }
    
    try {
      _isStreaming = true;
      await _controller.startImageStream((CameraImage image) async {
      if (_processingFrame) return;
      if (_throttleTimer != null && _throttleTimer!.isActive) return;
      _throttleTimer = Timer(const Duration(milliseconds: 150), () {});

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
            print('Pose detected: ${landmarks.length} landmarks'); // Debug output
            // Force UI update to show skeleton
            if (mounted) setState(() {});
          }
          
          // Perform ROM assessment based on selected mode (continuous tracking)
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
                  
                  // Update UserAssess for integration (continuous tracking)
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
              print('Comprehensive assessment failed: $e');
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
            // Use new calf analysis (continuous tracking)
            _analyzeCalfDorsiflexion(landmarks);
            if (mounted) setState(() {});
          } else if (_mode == 'Hamstrings') {
            // Use new hamstring analysis (continuous tracking)
            _analyzeHamstringROM(landmarks);
            if (mounted) setState(() {});
          }
        }
      } catch (e) {
        print('Pose detection error: $e');
      } finally {
        _processingFrame = false;
      }
    });
    } catch (e) {
      print('Error starting image stream: $e');
      _isStreaming = false;
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
      print('Calf analysis error: $e');
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
      print('Hamstring analysis error: $e');
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
    // final screenHeight = MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "Daily Assessment",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF1F2937),
              ),
            ),
            Text(
              "${_mode} (${_selectedSide})",
              style: GoogleFonts.ptSans(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          // Assessment mode dropdown
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF8B2E2E)),
              ),
            ),
          ),
          // Side selection dropdown
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF8B2E2E)),
              ),
            ),
          ),
          // Skeleton toggle
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _showSkeleton ? const Color(0xFF8B2E2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Toggle skeleton overlay',
              icon: Icon(
                _showSkeleton ? Icons.visibility : Icons.visibility_off,
                color: _showSkeleton ? Colors.white : const Color(0xFF8B2E2E),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _showSkeleton = !_showSkeleton;
                  if (!_showSkeleton) {
                    _currentLandmarks = null;
                  }
                });
              },
            ),
          ),
          // Camera switch
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Switch camera',
              icon: const Icon(Icons.cameraswitch_rounded, color: Color(0xFF8B2E2E), size: 20),
              onPressed: _switchCamera,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Progress indicator at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B2E2E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.camera_alt, color: Color(0xFF8B2E2E), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Step 2 of 3",
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B2E2E),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "66%",
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.66,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
                  ),
                ],
              ),
            ),
          ),

          // Camera preview with margin for progress bar
          Positioned.fill(
            top: 100,
            child: _isCameraInitialized
                ? Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CameraPreview(_controller),
                        ),
                      ),
                      // Camera status indicator
                      Positioned(
                        top: 26,
                        right: 26,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
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
                              const Icon(Icons.circle, color: Colors.white, size: 8),
                              const SizedBox(width: 6),
                              Text(
                                'Camera Active',
                                style: GoogleFonts.ptSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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

          // Top status bar - compact horizontal layout
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Skeleton indicator
                if (_showSkeleton)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Skeleton',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Spacer(),
                
                // Tracking indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green, width: 1),
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
                      const SizedBox(width: 6),
                      Text(
                        'Tracking',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Pain score indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(UserAssess.painScale).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getScoreColor(UserAssess.painScale),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${UserAssess.painScale}/10',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pose skeleton overlay - positioned on top of everything except bottom buttons
          if (_showSkeleton)
            Positioned.fill(
              top: 6,
              bottom: 150, // Leave space for bottom buttons
              child: IgnorePointer(
                child: Container(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      // Skeleton painter (only if landmarks exist)
                      if (_currentLandmarks != null)
                        CustomPaint(
                          painter: PoseSkeletonPainter(_currentLandmarks!),
                          size: Size.infinite,
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Instructions overlay - positioned at top but below status bar
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF800020), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getModeInstructions(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF800020).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF800020), width: 1),
                    ),
                    child: Text(
                      '$_selectedSide Side',
                      style: GoogleFonts.poppins(
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

          // Assessment results - positioned at bottom left to avoid center
          Positioned(
            bottom: 120,
            left: 16,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF800020), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display results based on mode
                  if (_mode == 'Triceps' || _mode == 'Shoulders') ...[
                    if (_currentROMLabel != null) ...[
                      Text(
                        _currentROMLabel!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _currentROMColor ?? Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      'Angle: ${_lastComputedAngle?.toStringAsFixed(1) ?? '--'}°',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                    if (_compensations != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Comp: ${_compensations.toString()}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ] else if (_mode == 'Calf') ...[
                    Text(
                      _calfROMLevel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _calfDisplayColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Disp: ${_calfNormDisplacement?.toStringAsFixed(2) ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _calfAlignment,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ] else if (_mode == 'Hamstrings') ...[
                    Text(
                      _hamstringROMLevel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _hamstringDisplayColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Angle: ${_hamstringAngle.toStringAsFixed(1)}°',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _hamstringCompensation,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
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
              ),
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


  // Helper method to build action buttons
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Tooltip(
        message: tooltip,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            elevation: 0,
          ),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
      ),
    );
  }
}

// Custom painter for drawing pose skeleton overlay
class PoseSkeletonPainter extends CustomPainter {
  final Map<String, Offset> landmarks;

  PoseSkeletonPainter(this.landmarks);

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    // Scale the landmarks to fit the canvas size
    // ML Kit coordinates are normalized (0.0 to 1.0), so we need to scale them to the actual canvas size
    final scaledLandmarks = <String, Offset>{};
    for (final entry in landmarks.entries) {
      scaledLandmarks[entry.key] = Offset(
        entry.value.dx * size.width,
        entry.value.dy * size.height,
      );
    }

    // Enhanced paint styles with better visibility
    final torsoPaint = Paint()
      ..color = const Color(0xFF00BFFF) // Bright blue
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final armPaint = Paint()
      ..color = const Color(0xFF00FF00) // Bright green
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final legPaint = Paint()
      ..color = const Color(0xFFFF8C00) // Bright orange
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final headPaint = Paint()
      ..color = const Color(0xFF8A2BE2) // Blue violet
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = const Color(0xFFFF0000) // Bright red
      ..style = PaintingStyle.fill;

    // Draw landmark points with better visibility
    for (final landmark in scaledLandmarks.values) {
      // Draw a white outline for better contrast
      final outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(landmark, 10, outlinePaint);
      canvas.drawCircle(landmark, 6, pointPaint);
    }

    // Draw skeleton connections with different colors
    _drawSkeletonConnections(canvas, torsoPaint, armPaint, legPaint, headPaint, scaledLandmarks);
  }

  void _drawSkeletonConnections(Canvas canvas, Paint torsoPaint, Paint armPaint, Paint legPaint, Paint headPaint, Map<String, Offset> scaledLandmarks) {
    // Head and neck
    _drawConnectionIfExists('nose', 'leftEye', canvas, headPaint, scaledLandmarks);
    _drawConnectionIfExists('nose', 'rightEye', canvas, headPaint, scaledLandmarks);
    _drawConnectionIfExists('leftEye', 'leftShoulder', canvas, headPaint, scaledLandmarks);
    _drawConnectionIfExists('rightEye', 'rightShoulder', canvas, headPaint, scaledLandmarks);

    // Torso
    _drawConnectionIfExists('leftShoulder', 'rightShoulder', canvas, torsoPaint, scaledLandmarks);
    _drawConnectionIfExists('leftShoulder', 'leftHip', canvas, torsoPaint, scaledLandmarks);
    _drawConnectionIfExists('rightShoulder', 'rightHip', canvas, torsoPaint, scaledLandmarks);
    _drawConnectionIfExists('leftHip', 'rightHip', canvas, torsoPaint, scaledLandmarks);

    // Left arm
    _drawConnectionIfExists('leftShoulder', 'leftElbow', canvas, armPaint, scaledLandmarks);
    _drawConnectionIfExists('leftElbow', 'leftWrist', canvas, armPaint, scaledLandmarks);

    // Right arm
    _drawConnectionIfExists('rightShoulder', 'rightElbow', canvas, armPaint, scaledLandmarks);
    _drawConnectionIfExists('rightElbow', 'rightWrist', canvas, armPaint, scaledLandmarks);

    // Left leg
    _drawConnectionIfExists('leftHip', 'leftKnee', canvas, legPaint, scaledLandmarks);
    _drawConnectionIfExists('leftKnee', 'leftAnkle', canvas, legPaint, scaledLandmarks);

    // Right leg
    _drawConnectionIfExists('rightHip', 'rightKnee', canvas, legPaint, scaledLandmarks);
    _drawConnectionIfExists('rightKnee', 'rightAnkle', canvas, legPaint, scaledLandmarks);

    // Additional connections for more detailed skeleton
    if (scaledLandmarks.containsKey('leftHeel')) {
      _drawConnectionIfExists('leftAnkle', 'leftHeel', canvas, legPaint, scaledLandmarks);
    }
    if (scaledLandmarks.containsKey('rightHeel')) {
      _drawConnectionIfExists('rightAnkle', 'rightHeel', canvas, legPaint, scaledLandmarks);
    }
    
    // Additional facial features if available
    if (scaledLandmarks.containsKey('leftEar') && scaledLandmarks.containsKey('leftEye')) {
      _drawConnectionIfExists('leftEye', 'leftEar', canvas, headPaint, scaledLandmarks);
    }
    if (scaledLandmarks.containsKey('rightEar') && scaledLandmarks.containsKey('rightEye')) {
      _drawConnectionIfExists('rightEye', 'rightEar', canvas, headPaint, scaledLandmarks);
    }
    
    // Hand connections if available
    if (scaledLandmarks.containsKey('leftWrist') && scaledLandmarks.containsKey('leftThumb')) {
      _drawConnectionIfExists('leftWrist', 'leftThumb', canvas, armPaint, scaledLandmarks);
    }
    if (scaledLandmarks.containsKey('rightWrist') && scaledLandmarks.containsKey('rightThumb')) {
      _drawConnectionIfExists('rightWrist', 'rightThumb', canvas, armPaint, scaledLandmarks);
    }
  }

  void _drawConnectionIfExists(String fromKey, String toKey, Canvas canvas, Paint paint, Map<String, Offset> scaledLandmarks) {
    final from = scaledLandmarks[fromKey];
    final to = scaledLandmarks[toKey];
    
    if (from != null && to != null) {
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
