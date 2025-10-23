import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../data/custom_pose_detection_service.dart';
import '../widgets/custom_pose_skeleton_painter.dart';

/// Pose Estimation Model Demo Page
/// 
/// This page demonstrates the custom pose estimation model functionality
/// with real-time camera feed and skeleton overlay visualization.
class PoseEstimationDemo extends StatefulWidget {
  const PoseEstimationDemo({super.key});

  @override
  State<PoseEstimationDemo> createState() => _PoseEstimationDemoState();
}

class _PoseEstimationDemoState extends State<PoseEstimationDemo> {
  final CustomPoseDetectionService _poseService = CustomPoseDetectionService();
  
  // Color constants
  static const Color _mainColor = Color(0xFF8B2E2E); // Muscular maroon
  static const Color _backgroundColor = Color(0xFFF8FAFC); // Light background
  
  late CameraController _controller;
  late List<CameraDescription> cameras;
  bool _isCameraInitialized = false;
  bool _isStreaming = false;
  bool _processingFrame = false;
  Timer? _throttleTimer;
  int? _lastProcessedTime;
  
  // Pose detection state
  List<Map<String, dynamic>> _currentKeypoints = [];
  bool _showSkeleton = true;
  bool _showLandmarkLabels = false;
  bool _showConfidence = false;
  double _strokeWidth = 3.0;
  double _pointRadius = 6.0;
  
  // Performance monitoring
  int _frameCount = 0;
  int _lastFpsTime = 0;
  double _currentFps = 0.0;
  
  // Model status
  bool _modelInitialized = false;
  String? _modelError;
  
  @override
  void initState() {
    super.initState();
    _initializeModel();
    _initializeCamera();
  }
  
  /// Initialize the pose estimation model
  Future<void> _initializeModel() async {
    try {
      await _poseService.initialize();
      if (mounted) {
        setState(() {
          _modelInitialized = true;
          _modelError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _modelError = e.toString();
        });
      }
    }
  }
  
  /// Initialize the camera
  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }
      
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
      
      // Start image stream after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      await _startImageStream();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }
  
  /// Start image stream for pose detection
  Future<void> _startImageStream() async {
    if (_isStreaming || !_controller.value.isInitialized || !_modelInitialized) {
      return;
    }
    
    try {
      _isStreaming = true;
      await _controller.startImageStream((CameraImage image) async {
        if (_processingFrame) return;
        if (_throttleTimer != null && _throttleTimer!.isActive) return;
        _throttleTimer = Timer(const Duration(milliseconds: 150), () {});
        
        // Throttle processing
        final int nowMs = DateTime.now().millisecondsSinceEpoch;
        _lastProcessedTime ??= nowMs;
        if (nowMs - _lastProcessedTime! < 120) {
          return;
        }
        _lastProcessedTime = nowMs;
        
        // Performance monitoring
        _frameCount++;
        if (_lastFpsTime == 0) {
          _lastFpsTime = nowMs;
        } else if (nowMs - _lastFpsTime >= 1000) {
          _currentFps = _frameCount * 1000.0 / (nowMs - _lastFpsTime);
          _frameCount = 0;
          _lastFpsTime = nowMs;
        }

        _processingFrame = true;
        try {
          // Run pose detection
          final keypoints = await _poseService.detectPosesFromCameraImage(
            image: image,
            camera: cameras[0],
          );
          
          if (mounted) {
            setState(() {
              _currentKeypoints = keypoints;
            });
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
    }
  }
  
  /// Switch camera
  Future<void> _switchCamera() async {
    if (cameras.length <= 1) return;
    
    try {
      await _controller.stopImageStream();
      await _controller.dispose();
      setState(() {
        _isCameraInitialized = false;
        _isStreaming = false;
        _currentKeypoints = [];
      });
      
      // Switch to next camera
      final nextIndex = (cameras.indexOf(_controller.description) + 1) % cameras.length;
      _controller = CameraController(
        cameras[nextIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        await _startImageStream();
      }
    } catch (e) {
      debugPrint('Camera switch error: $e');
    }
  }
  
  /// Show skeleton configuration dialog
  void _showSkeletonConfigDialog() {
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
                        value: _showLandmarkLabels,
                        activeColor: _mainColor,
                        onChanged: (value) {
                          setDialogState(() {
                            _showLandmarkLabels = value;
                          });
                        },
                      ),
                    ],
                  ),
                  
                  // Show confidence toggle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Show Confidence',
                          style: GoogleFonts.ptSans(
                            fontSize: 14,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Switch(
                        value: _showConfidence,
                        activeColor: _mainColor,
                        onChanged: (value) {
                          setDialogState(() {
                            _showConfidence = value;
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Stroke width slider
                  Text(
                    'Line Thickness: ${_strokeWidth.toStringAsFixed(1)}',
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Slider(
                    value: _strokeWidth,
                    min: 2.0,
                    max: 8.0,
                    divisions: 12,
                    activeColor: _mainColor,
                    onChanged: (value) {
                      setDialogState(() {
                        _strokeWidth = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Point radius slider
                  Text(
                    'Point Size: ${_pointRadius.toStringAsFixed(1)}',
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Slider(
                    value: _pointRadius,
                    min: 3.0,
                    max: 12.0,
                    divisions: 18,
                    activeColor: _mainColor,
                    onChanged: (value) {
                      setDialogState(() {
                        _pointRadius = value;
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
                      _showLandmarkLabels = false;
                      _showConfidence = false;
                      _strokeWidth = 3.0;
                      _pointRadius = 6.0;
                    });
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.ptSans(
                      color: _mainColor,
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
  
  @override
  void dispose() {
    try { _controller.stopImageStream(); } catch (_) {}
    _controller.dispose();
    _poseService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : _backgroundColor,
      appBar: AppBar(
        backgroundColor: _mainColor,
        title: Text(
          'Pose Estimation Demo',
          style: GoogleFonts.ptSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSkeleton ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showSkeleton = !_showSkeleton;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSkeletonConfigDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera and Pose Detection Area
          Expanded(
            child: Stack(
              children: [
                // Camera preview
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _mainColor.withOpacity(0.2), width: 1.5),
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
                              // Skeleton overlay
                              if (_showSkeleton && _currentKeypoints.isNotEmpty)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      margin: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                                              return const SizedBox.shrink();
                                            }
                                            
                                            return CustomPaint(
                                              painter: CustomPoseSkeletonPainter(
                                                keypoints: _currentKeypoints,
                                                showLandmarkLabels: _showLandmarkLabels,
                                                strokeWidth: _strokeWidth,
                                                pointRadius: _pointRadius,
                                                showConfidence: _showConfidence,
                                              ),
                                              size: Size(constraints.maxWidth, constraints.maxHeight),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
                                  if (_modelError != null) ...[
                                    const Icon(Icons.error, color: Colors.red, size: 48),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Model Error',
                                      style: GoogleFonts.ptSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _modelError!,
                                      style: GoogleFonts.ptSans(
                                        fontSize: 14,
                                        color: Colors.red,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ] else ...[
                                    const CircularProgressIndicator(
                                      color: _mainColor,
                                      strokeWidth: 2.5,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Initializing...',
                                      style: GoogleFonts.ptSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                
                // Status indicators
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      // Model status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _modelInitialized 
                              ? Colors.green.withOpacity(0.9)
                              : Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _modelInitialized ? Icons.check_circle : Icons.hourglass_empty,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _modelInitialized ? 'MODEL' : 'LOADING',
                              style: GoogleFonts.ptSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // FPS indicator
                      if (_currentFps > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.speed, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentFps.toStringAsFixed(1)} FPS',
                                style: GoogleFonts.ptSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // Keypoints count
                      if (_currentKeypoints.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.accessibility, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentKeypoints.length} KP',
                                style: GoogleFonts.ptSans(
                                  fontSize: 9,
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
                
                // Instructions overlay
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _mainColor.withOpacity(0.4), width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "Pose Estimation Demo",
                              style: GoogleFonts.ptSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "This demo uses the custom trained pose estimation model. "
                          "The skeleton overlay shows detected keypoints in real-time.",
                          style: GoogleFonts.ptSans(
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Switch camera button
                if (cameras.length > 1)
                  Container(
                    decoration: BoxDecoration(
                      color: _mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.cameraswitch_rounded, color: _mainColor),
                      onPressed: _switchCamera,
                    ),
                  ),
                
                if (cameras.length > 1) const SizedBox(width: 12),
                
                // Model info
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _modelInitialized 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _modelInitialized 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _modelInitialized ? Icons.check_circle : Icons.hourglass_empty,
                          color: _modelInitialized ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _modelInitialized 
                                ? 'Custom Model Active'
                                : 'Loading Model...',
                            style: GoogleFonts.ptSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _modelInitialized ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
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
}
