import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/custom_pose_detection_service.dart';
import '../data/pose_diagnostics.dart';
import '../data/pose_model_manager.dart';
import '../data/pose_verification_sample.dart';
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

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _isCameraInitialized = false;
  bool _isStreaming = false;
  bool _processingFrame = false;
  Timer? _throttleTimer;
  int? _lastProcessedTime;

  // Pose detection state
  List<Map<String, dynamic>> _currentKeypoints = [];
  Size?
  _cameraImageSize; // Store camera image dimensions for coordinate scaling
  bool _showSkeleton = true;
  bool _showLandmarkLabels = false;
  bool _showConfidence = false;
  double _strokeWidth = 3.0;
  double _pointRadius = 6.0;

  final PoseDiagnostics _diagnostics = PoseDiagnostics.instance;
  PoseDiagnosticSnapshot _diagnosticSnapshot =
      PoseDiagnosticSnapshot.initial();
  late final VoidCallback _diagnosticsListener;
  bool _diagnosticsMode = false;
  PoseVerificationSample? _verificationSample;
  bool _loadingVerificationSample = false;
  String? _verificationError;
  static const String _verificationAssetPath =
      'assets/data/pose_sample_frame.json';

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
    _diagnosticsListener = () {
      if (!mounted) return;
      setState(() {
        _diagnosticSnapshot = _diagnostics.snapshot.value;
      });
    };
    _diagnostics.snapshot.addListener(_diagnosticsListener);
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
        if (_isCameraInitialized) {
          await _startImageStream();
        }
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
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      final selectedCamera = _cameras.first;
      final resolutionPreset =
          kIsWeb ? ResolutionPreset.high : ResolutionPreset.medium;
      final controller = CameraController(
        selectedCamera,
        resolutionPreset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
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
    if (!_isCameraInitialized) {
      return;
    }
    final controller = _controller;
    if (controller == null) return;
    if (_diagnosticsMode ||
        _isStreaming ||
        !controller.value.isInitialized ||
        !_modelInitialized) {
      return;
    }

    try {
      _isStreaming = true;
      await controller.startImageStream((CameraImage image) async {
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
          // Store camera image size for coordinate scaling, accounting for rotation
          final activeController = _controller;
          if (activeController == null) return;
          final camera = activeController.description;
          final sensorOrientation = camera.sensorOrientation;
          final isPortrait = sensorOrientation == 90 || sensorOrientation == 270;
          
          _cameraImageSize = Size(
            isPortrait ? image.height.toDouble() : image.width.toDouble(),
            isPortrait ? image.width.toDouble() : image.height.toDouble(),
          );

          // Run pose detection
          final keypoints = await _poseService.detectPosesFromCameraImage(
            image: image,
            camera: camera,
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
    if (_cameras.length <= 1 || _controller == null) return;

    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      await _controller!.dispose();
      setState(() {
        _isCameraInitialized = false;
        _isStreaming = false;
        _currentKeypoints = [];
      });

      // Switch to next camera
      final nextIndex =
          (_cameras.indexOf(_controller!.description) + 1) % _cameras.length;
      final resolutionPreset =
          kIsWeb ? ResolutionPreset.high : ResolutionPreset.medium;
      final controller = CameraController(
        _cameras[nextIndex],
        resolutionPreset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      if (mounted) {
        setState(() {
          _controller = controller;
          _isCameraInitialized = true;
        });
        await _startImageStream();
      }
    } catch (e) {
      debugPrint('Camera switch error: $e');
    }
  }

  Future<void> _toggleDiagnosticsMode() async {
    if (_loadingVerificationSample) return;

    if (_diagnosticsMode) {
      if (mounted) {
        setState(() {
          _diagnosticsMode = false;
          _verificationSample = null;
          _verificationError = null;
          _currentKeypoints = [];
          _cameraImageSize = null;
        });
      }
      _diagnostics.resetFrameStreak();
      if (_isCameraInitialized && !_isStreaming) {
        await _startImageStream();
      }
      return;
    }

    setState(() {
      _loadingVerificationSample = true;
      _verificationError = null;
    });

    try {
      final controller = _controller;
      if (_isStreaming &&
          controller != null &&
          controller.value.isInitialized &&
          controller.value.isStreamingImages) {
        await controller.stopImageStream();
        _isStreaming = false;
      }
      final sample =
          await PoseVerificationSample.loadFromAsset(_verificationAssetPath);

      final isValid = _validateSampleMetadata(sample);
      if (!isValid) {
        throw Exception(
          'Sample metadata mismatch. Regenerate pose_sample_frame.json.',
        );
      }

      if (!mounted) return;
      setState(() {
        _diagnosticsMode = true;
        _verificationSample = sample;
        _currentKeypoints = sample.keypoints;
        _cameraImageSize = sample.imageSize;
      });
      _diagnostics.resetFrameStreak();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verificationError = 'Diagnostics sample error: $e';
        _diagnosticsMode = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingVerificationSample = false;
        });
      }
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
    try {
      _controller?.stopImageStream();
    } catch (_) {}
    _controller?.dispose();
    _poseService.dispose(); // Dispose is async but we can't await in dispose()
    _diagnostics.snapshot.removeListener(_diagnosticsListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? Theme.of(context).scaffoldBackgroundColor : _backgroundColor,
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
            icon: Icon(
              Icons.bug_report,
              color: _diagnosticsMode ? Colors.amberAccent : Colors.white,
            ),
            tooltip: _diagnosticsMode
                ? 'Exit verification mode'
                : 'Verification mode',
            onPressed: _toggleDiagnosticsMode,
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
                    border: Border.all(
                      color: _mainColor.withOpacity(0.2),
                      width: 1.5,
                    ),
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
                  child: _diagnosticsMode
                      ? _buildDiagnosticsPreview()
                      : _isCameraInitialized
                          ? _buildCameraPreview()
                          : _buildPreviewPlaceholder(),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _modelInitialized
                                  ? Colors.green.withOpacity(0.9)
                                  : Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _modelInitialized
                                  ? Icons.check_circle
                                  : Icons.hourglass_empty,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.speed,
                                color: Colors.white,
                                size: 12,
                              ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.accessibility,
                                color: Colors.white,
                                size: 12,
                              ),
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

                if (!_diagnosticsMode &&
                    _diagnosticSnapshot.emptyFrameStreak >=
                        PoseDiagnosticSnapshot.emptyFrameThreshold)
                  Positioned(
                    bottom: 140,
                    left: 24,
                    right: 24,
                    child: _buildWarningBanner(),
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
                      border: Border.all(
                        color: _mainColor.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 14,
                            ),
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
                if (_cameras.length > 1)
                  Container(
                    decoration: BoxDecoration(
                      color: _mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.cameraswitch_rounded,
                        color: _mainColor,
                      ),
                      onPressed: _switchCamera,
                    ),
                  ),

                if (_cameras.length > 1) const SizedBox(width: 12),

                // Model + diagnostics info
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _modelInitialized
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _modelInitialized
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _modelInitialized
                                  ? Icons.check_circle
                                  : Icons.hourglass_empty,
                              color:
                                  _modelInitialized ? Colors.green : Colors.orange,
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
                                  color:
                                      _modelInitialized
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDiagnosticsFooter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _validateSampleMetadata(PoseVerificationSample sample) {
    final width = sample.imageSize.width;
    final height = sample.imageSize.height;
    if (width == 0 || height == 0) {
      return false;
    }

    final scale = math.min(
      PoseModelManager.modelInputSize / width,
      PoseModelManager.modelInputSize / height,
    );
    final padX =
        (PoseModelManager.modelInputSize - width * scale) / 2;
    final padY =
        (PoseModelManager.modelInputSize - height * scale) / 2;

    return sample.validateScaleAndPadding(
      computedScale: scale,
      computedPadX: padX,
      computedPadY: padY,
      tolerance: 1.0,
    );
  }

  Widget _buildCameraPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _buildPreviewPlaceholder();
    }
    final isFrontCamera =
        controller.description.lensDirection == CameraLensDirection.front;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        if (_showSkeleton && _currentKeypoints.isNotEmpty)
          IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                  return const SizedBox.shrink();
                }

                final overlaySize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return CustomPaint(
                  painter: CustomPoseSkeletonPainter(
                    keypoints: _currentKeypoints,
                    imageSize: _cameraImageSize,
                    previewSize: overlaySize,
                    showLandmarkLabels: _showLandmarkLabels,
                    strokeWidth: _strokeWidth,
                    pointRadius: _pointRadius,
                    showConfidence: _showConfidence,
                    mirrorHorizontally: isFrontCamera,
                  ),
                  size: overlaySize,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDiagnosticsPreview() {
    if (_loadingVerificationSample) {
      return _buildPreviewMessage(
        title: 'Loading verification frame',
        subtitle: 'Please wait…',
        icon: Icons.bug_report,
        iconColor: Colors.amberAccent,
        showSpinner: true,
      );
    }

    if (_verificationError != null) {
      return _buildPreviewMessage(
        title: 'Diagnostics Error',
        subtitle: _verificationError!,
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
      );
    }

    final sample = _verificationSample;
    if (sample == null) {
      return _buildPreviewMessage(
        title: 'Diagnostics Sample Not Loaded',
        subtitle: 'Toggle the bug icon to load the stored pose frame.',
        icon: Icons.info_outline,
        iconColor: Colors.white,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final overlaySize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bug_report,
                      color: Colors.amberAccent,
                      size: 42,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verification Frame ${sample.frameId}',
                      style: GoogleFonts.ptSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Image ${sample.imageSize.width.toInt()}×${sample.imageSize.height.toInt()} '
                      '| scale ${sample.expectedScale.toStringAsFixed(2)} | padX ${sample.expectedPadX}',
                      style: GoogleFonts.ptSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            if (_showSkeleton)
              IgnorePointer(
                child: CustomPaint(
                  painter: CustomPoseSkeletonPainter(
                    keypoints: sample.keypoints,
                    imageSize: sample.imageSize,
                    previewSize: overlaySize,
                    showLandmarkLabels: _showLandmarkLabels,
                    strokeWidth: _strokeWidth,
                    pointRadius: _pointRadius,
                    showConfidence: _showConfidence,
                  ),
                  size: overlaySize,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewPlaceholder() {
    if (_modelError != null) {
      return _buildPreviewMessage(
        title: 'Model Error',
        subtitle: _modelError!,
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }

    return _buildPreviewMessage(
      title: 'Initializing…',
      subtitle: 'Camera + model are starting up',
      icon: Icons.hourglass_empty,
      iconColor: _mainColor,
      showSpinner: true,
    );
  }

  Widget _buildPreviewMessage({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    bool showSpinner = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.ptSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                subtitle,
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (showSpinner) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                color: _mainColor,
                strokeWidth: 2.5,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    final warning = _diagnosticSnapshot.lastWarning ??
        'No pose detected for ${_diagnosticSnapshot.emptyFrameStreak} frames';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning,
              style: GoogleFonts.ptSans(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _toggleDiagnosticsMode,
            child: Text(
              'VERIFY',
              style: GoogleFonts.ptSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsFooter() {
    final snapshot = _diagnosticSnapshot;
    final inferenceText =
        snapshot.lastInferenceMs != null && snapshot.lastInferenceMs! > 0
            ? '${snapshot.lastInferenceMs!.toStringAsFixed(1)} ms'
            : '--';
    final keypointCount =
        snapshot.lastKeypointCount ?? _currentKeypoints.length;
    final streak = snapshot.emptyFrameStreak;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: Colors.deepPurple.shade400,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Last inference $inferenceText',
                  style: GoogleFonts.ptSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Keypoints $keypointCount | Empty streak $streak',
                  style: GoogleFonts.ptSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (_diagnosticsMode)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'VERIFICATION',
                style: GoogleFonts.ptSans(
                  fontSize: 10,
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
