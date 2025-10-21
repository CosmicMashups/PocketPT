// Import necessary packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import '../data/globals.dart';
import '../main.dart';
import '../data/pose_detection_service.dart';
import '../widgets/enhanced_pose_skeleton_painter.dart';
import 'assessment_data.dart';
import 'arom/assessment_service.dart';
import 'arom/assessment_result.dart';
import 'c_video.dart';
import 'c_upload.dart';
import 'c_videopreview.dart';
class AssessPainCamera extends StatefulWidget {
  const AssessPainCamera({super.key});

  @override
  State<AssessPainCamera> createState() => _AssessPainCameraState();
}

class _AssessPainCameraState extends State<AssessPainCamera> {
  // Assessment logic moved to modular services

  int painScale = 0;
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
  int? _lastProcessedTime; // ms timestamp for throttling
  
  // Performance monitoring
  int _frameCount = 0;
  int _lastFpsTime = 0;
  double _currentFps = 0.0;
  
  // Current assessment result from modular services
  AssessmentResult? _currentAssessmentResult;

  // Skeleton visualization state - improved for better synchronization
  bool _showSkeleton = false;
  Map<String, Offset>? _currentLandmarks; // Always updated regardless of toggle state
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
    print('AssessPainCamera: initState() called');
    print('AssessPainCamera: Current AssessmentData.painScale = "${AssessmentData.painScale}"');
    print('AssessPainCamera: Current UserAssess.painScale = "${UserAssess.painScale}"');
    
    // Initialize pain scale from local data
    painScale = UserAssess.painScale;
    print('AssessPainCamera: painScale initialized to: $painScale');
    
    _initializeCamera();
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
        final poses = await _poseService.detectFromCameraImage(image: image, camera: cameras[_selectedCameraIndex]);
        if (poses.isNotEmpty) {
          try {
            final landmarks = _poseService.getPoseLandmarks(poses.first);
            
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
          
          // Store landmarks for skeleton visualization (always update regardless of toggle state)
          _currentLandmarks = landmarks;
          debugPrint('Pose detected: ${landmarks.length} landmarks'); // Debug output
          
          // Only trigger UI update if skeleton is visible to avoid unnecessary repaints
          if (_showSkeleton && mounted) {
            setState(() {});
          }
          
          // Perform ROM assessment using modular services
          try {
            final assessmentResult = AssessmentService.assess(_mode, landmarks, _selectedSide);
            
            if (mounted) {
              setState(() {
                _currentAssessmentResult = assessmentResult;
                
                // Update UserAssess for integration (persists during recording)
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
                  try {
                    final landmarks = _poseService.getPoseLandmarks(poses.first);
                    
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
                  
                  // Store landmarks for skeleton visualization (always update regardless of toggle state)
                  _currentLandmarks = landmarks;
                  
                  // Only trigger UI update if skeleton is visible to avoid unnecessary repaints
                  if (_showSkeleton && mounted) {
                    setState(() {});
                  }
                  // Perform ROM assessment using modular services
                  try {
                    final assessmentResult = AssessmentService.assess(_mode, landmarks, _selectedSide);
                    
                    if (mounted) {
                      setState(() {
                        _currentAssessmentResult = assessmentResult;
                        
                        // Update UserAssess for integration (persists during recording)
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
      // Clear landmarks when switching cameras to prevent stale data
      _currentLandmarks = null;
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
    print('AssessPainCamera: build() called');
    print('AssessPainCamera: Current AssessmentData.painScale in build = "${AssessmentData.painScale}"');
    print('AssessPainCamera: Current UserAssess.painScale in build = "${UserAssess.painScale}"');
    print('AssessPainCamera: Current painScale = $painScale');
    
    try {
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
                DropdownMenuItem(value: 'Gluteals', child: Text('Gluteals')),
                DropdownMenuItem(value: 'Calf', child: Text('Calf')),
                DropdownMenuItem(value: 'Chest', child: Text('Chest')),
                DropdownMenuItem(value: 'Biceps', child: Text('Biceps')),
                DropdownMenuItem(value: 'Quadriceps', child: Text('Quadriceps')),
                DropdownMenuItem(value: 'Abdominals', child: Text('Abdominals')),
                DropdownMenuItem(value: 'Obliques', child: Text('Obliques')),
                DropdownMenuItem(value: 'Lower Back', child: Text('Lower Back')),
                DropdownMenuItem(value: 'Multifidus', child: Text('Multifidus')),
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
                  onChanged: (val) {
                    setState(() {
                      _showSkeleton = val;
                      // Don't clear landmarks when toggling off - keep them for assessment
                      // Only clear if explicitly requested or on camera switch
                    });
                    
                    // Log toggle state for debugging
                    debugPrint('Skeleton overlay toggled: $_showSkeleton');
                  },
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

                // Enhanced pose skeleton overlay with improved positioning
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Ensure we have valid constraints
                              if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                                return const SizedBox.shrink();
                              }
                              
                              return CustomPaint(
                                painter: EnhancedPoseSkeletonPainter(
                                  landmarks: _currentLandmarks!,
                                  showLandmarkLabels: _skeletonConfig.showLandmarkLabels,
                                  strokeWidth: _skeletonConfig.strokeWidth,
                                  pointRadius: _skeletonConfig.pointRadius,
                                  showConfidence: _skeletonConfig.showConfidence,
                                ),
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                              );
                            },
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
                        // Display assessment results using modular services
                        if (_currentAssessmentResult != null) ...[
                          Text(
                            _currentAssessmentResult!.displayLabel,
                            style: GoogleFonts.ptSans(
                              fontSize: 11,
                              color: _currentAssessmentResult!.displayColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_currentAssessmentResult!.additionalData['angle'] != null) ...[
                            Text(
                              'Angle: ${_currentAssessmentResult!.additionalData['angle'].toStringAsFixed(1)}°',
                              style: GoogleFonts.ptSans(
                                fontSize: 10,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          if (_currentAssessmentResult!.additionalData['absNormalizedDisplacement'] != null) ...[
                            Text(
                              'Disp: ${_currentAssessmentResult!.additionalData['absNormalizedDisplacement'].toStringAsFixed(2)}',
                              style: GoogleFonts.ptSans(
                                fontSize: 10,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          if (_currentAssessmentResult!.alignment != null) ...[
                            Text(
                              _currentAssessmentResult!.alignment!,
                              style: GoogleFonts.ptSans(
                                fontSize: 9,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                          if (_currentAssessmentResult!.compensation != null) ...[
                            Text(
                              _currentAssessmentResult!.compensation!,
                              style: GoogleFonts.ptSans(
                                fontSize: 9,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ] else ...[
                          Text(
                            '${_mode}: Not assessed',
                            style: GoogleFonts.ptSans(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
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
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AssessUpload()));
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

  String _getModeInstructions() {
    return AssessmentService.getInstructions(_mode, _selectedSide);
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


