import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import '../home_dialog.dart';
import '../data/rehabilitation_plan.dart';
import '../assessment/assessment_data.dart';
import '../core/animations.dart';
import '../data/facial_pain_recognition_service.dart';
import 'pre_record_page.dart';
import 'confirm_save_page.dart';
import 'cooldown_stretching_page.dart';
import 'stopwatch_service.dart';
import 'camera_service.dart';
import 'exercise_cache_service.dart';
import 'design_system.dart';
import 'dart:async';
import '../tutorials/tutorial_config.dart';
import '../tutorials/tutorial_preferences.dart';
import '../tutorials/tutorial_service.dart';
class RecordExercisePage extends StatefulWidget {
  final Exercise exercise;

  const RecordExercisePage({required this.exercise, super.key});

  @override
  State<RecordExercisePage> createState() => _RecordExercisePageState();
}

class _RecordExercisePageState extends State<RecordExercisePage> with TickerProviderStateMixin {
  final CameraService _cameraService = CameraService.instance;
  final ExerciseCacheService _cacheService = ExerciseCacheService.instance;
  final FacialPainRecognitionService _painService = FacialPainRecognitionService();
  bool _isCameraInitialized = false;
  late AnimationController _animationController;
  
  // Pain detection state
  bool _isPainDetectionEnabled = false;
  String? _currentPainLevel;
  double _painConfidence = 0.0;
  bool _showPainBanner = false;
  Timer? _painDetectionTimer;
  
  // Track if page is active - prevents pain detection after navigation
  bool _isPageActive = true;
  
  // Track if pain values are locked (after navigation)
  bool _painValuesLocked = false;
  
  bool _tutorialScheduled = false;
  
  // Severe pain dialog cooldown
  DateTime? _lastSeverePainDialogTime;
  static const Duration _severePainDialogCooldown = Duration(seconds: 15);
  
  // Camera toggle state
  int _currentCameraIndex = 0;
  bool _isSwitchingCamera = false;
  
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

  @override
  void initState() {
    super.initState();
    _animationController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.medium,
    );
    
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
    
    _initializeCamera();
    _initializePainDetection();
    StopwatchService.instance.start();
  }

  @override
  void dispose() {
    // Stop pain detection and lock values
    _stopPainDetection();
    _animationController.dispose();
    _painOverlayController.dispose();
    _painBannerController.dispose();
    _painColorController.dispose();
    _painDetectionTimer?.cancel();
    super.dispose();
  }
  
  // Stop pain detection
  void _stopPainDetection() {
    _isPageActive = false;
    _painDetectionTimer?.cancel();
    _painDetectionTimer = null;
    _painValuesLocked = true; // Lock pain values to prevent further updates
  }

  Future<void> _initializeCamera() async {
    try {
      final success = await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = success;
          // Initialize current camera index
          final cameras = _cameraService.cameras;
          if (cameras != null && cameras.isNotEmpty) {
            // Find current camera index
            final currentCamera = _cameraService.controller?.description;
            if (currentCamera != null) {
              _currentCameraIndex = cameras.indexWhere(
                (camera) => camera.name == currentCamera.name,
              );
              if (_currentCameraIndex == -1) {
                _currentCameraIndex = 0;
              }
            }
          }
        });
        if (success) {
          _scheduleCameraTutorial();
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  void _scheduleCameraTutorial() {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_isCameraInitialized) {
        _tutorialScheduled = false;
        return;
      }

      await TutorialPreferences.instance.ensureInitialized();
      if (!mounted) {
        _tutorialScheduled = false;
        return;
      }
      
      if (!TutorialPreferences.instance.tutorialsEnabled) {
        _tutorialScheduled = false;
        return;
      }

      if (TutorialPreferences.instance.isFlowCompleted('onboarding_camera')) {
        return;
      }

      if (!mounted) {
        _tutorialScheduled = false;
        return;
      }
      
      await TutorialService.instance.startFlow(context, 'onboarding_camera');
    });
  }

  Future<void> _initializePainDetection() async {
    try {
      await _painService.initialize();
      if (mounted) {
        setState(() {
          _isPainDetectionEnabled = true;
        });
        _startPainDetection();
        debugPrint('Pain detection initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing pain detection: $e');
      if (mounted) {
        setState(() {
          _isPainDetectionEnabled = false;
        });
      }
      // Graceful degradation: Continue without pain detection
      // Don't show error to user as it's not critical for exercise recording
      debugPrint('Exercise recording will continue without pain detection');
    }
  }

  void _startPainDetection() {
    if (!_isPainDetectionEnabled || !_isCameraInitialized || !_isPageActive) return;
    
    _painDetectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      // Stop detection if page is no longer active
      if (!_isPageActive || !mounted || !_cameraService.isReady) {
        timer.cancel();
        return;
      }
      
      try {
        // For now, we'll use a simulated camera image since we need to implement
        // proper camera image capture for pain detection
        // This will be replaced with actual camera image processing
        final result = await _painService.detectFacialPain(
          image: null, // Will be implemented with proper camera image capture
          camera: _cameraService.controller!.description,
        );
        
        if (_isPageActive && mounted && result['error'] == null) {
          _handlePainDetectionResult(result);
        }
      } catch (e) {
        debugPrint('Pain detection error: $e');
      }
    });
  }

  void _handlePainDetectionResult(Map<String, dynamic> result) {
    // Don't process if page is no longer active or values are locked
    if (!_isPageActive || _painValuesLocked) return;
    
    final painLevel = result['painLevel'];
    final confidence = result['confidence'];
    
    if (confidence > 0.7) {
      // Check if pain level changed for smooth animation
      final painLevelChanged = _currentPainLevel != painLevel;
      
      setState(() {
        _currentPainLevel = painLevel;
        _painConfidence = confidence;
      });
      
      // Animate color change and scale when pain level changes
      if (painLevelChanged && _currentPainLevel != null) {
        _animatePainLevelChange(_currentPainLevel!);
      }
      
      _triggerPainIntervention(painLevel);
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

  void _triggerPainIntervention(String painLevel) {
    switch (painLevel) {
      case 'Low':
        // No action needed for low pain
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

  void _showModeratePainBanner() {
    // Check if user has disabled this banner
    if (!_shouldShowModeratePainBanner()) {
      debugPrint('Moderate pain banner disabled by user preference');
      return;
    }
    
    if (_showPainBanner) return; // Prevent multiple banners
    
    setState(() {
      _showPainBanner = true;
      _moderatePainBannerDontShowAgain = false; // Reset checkbox state
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

  // Helper method to convert pain level to pain scale (0-10)
  // Maps detected pain levels to standard pain scale ranges
  int? _painLevelToPainScale(String? painLevel) {
    if (painLevel == null) return null;
    switch (painLevel) {
      case 'Low':
        return 2; // 0-3 range, use midpoint
      case 'Moderate':
        return 5; // 4-7 range, use midpoint
      case 'Severe':
        return 8; // 8-10 range, use midpoint
      default:
        return null;
    }
  }

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
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Severe Pain Detected'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We\'ve detected severe pain during your exercise. '
                    'For your safety, we recommend taking a rest. '
                    'Are you able to continue safely?'
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
                          style: TextStyle(fontSize: 14),
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
                    Navigator.pop(context);
                    _pauseExerciseForRest();
                  },
                  child: Text('Take a Rest'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_severePainDialogDontShowAgain) {
                      await _setHideSeverePainDialog(true);
                    }
                    Navigator.pop(context);
                    _continueExercise();
                  },
                  child: Text('Continue Exercise'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _pauseExerciseForRest() {
    // Pause the exercise and show rest recommendations
    StopwatchService.instance.pause();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exercise paused. Please rest and resume when ready.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _continueExercise() {
    // User chose to continue despite severe pain
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please be careful and stop if pain increases.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }


  Widget _buildCameraPreview(bool isDark) {
    if (_isCameraInitialized && _cameraService.isReady) {
      final cameraPreview = _cameraService.getEnhancedCameraPreview(context);
      if (cameraPreview != null) {
        return Stack(
          children: [
            Semantics(
              label: 'Camera preview for exercise recording',
              hint: 'Double tap to focus camera',
              child: cameraPreview,
            ),
            // Camera toggle button
            _buildCameraToggleButton(),
            // Pain detection overlay (positioned within camera bounds)
            if (_isPainDetectionEnabled)
              _buildPainDetectionOverlay(),
            // Moderate pain banner
            if (_showPainBanner)
              _buildModeratePainBanner(),
          ],
        );
      }
    }

    // Show loading state with enhanced design
    return _cameraService.getLoadingIndicator(context);
  }

  Widget _buildCameraToggleButton() {
    final cameras = _cameraService.cameras;
    // Only show toggle if multiple cameras are available
    if (cameras == null || cameras.length < 2) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        key: TutorialAnchors.recordCameraToggle,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
          boxShadow: RecordingDesignSystem.shadowMedium,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
            onTap: _isSwitchingCamera ? null : _toggleCamera,
            child: Container(
              padding: const EdgeInsets.all(RecordingDesignSystem.spacingS),
              child: _isSwitchingCamera
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.cameraswitch_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleCamera() async {
    final cameras = _cameraService.cameras;
    if (cameras == null || cameras.length < 2) {
      return;
    }

    setState(() {
      _isSwitchingCamera = true;
    });

    try {
      // Calculate next camera index
      final nextCameraIndex = (_currentCameraIndex + 1) % cameras.length;
      
      // Stop pain detection during camera switch
      final wasPainDetectionActive = _isPainDetectionEnabled;
      _stopPainDetection();
      
      // Switch camera
      final success = await _cameraService.switchCamera(nextCameraIndex);
      
      if (success && mounted) {
        setState(() {
          _currentCameraIndex = nextCameraIndex;
          _isCameraInitialized = true;
        });
        
        // Restart pain detection if it was active
        if (wasPainDetectionActive) {
          _startPainDetection();
        }
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to switch camera. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching camera: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingCamera = false;
        });
      }
    }
  }

  Widget _buildPainDetectionOverlay() {
    if (!PocketPTAnimations.shouldAnimate(context)) {
      // Fallback to non-animated version if animations are disabled
      // Positioned within camera widget bounds (top-right, accounting for camera toggle on left)
      return Positioned(
        top: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getPainColor(_currentPainLevel).withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPainIcon(_currentPainLevel),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                _currentPainLevel ?? 'Low',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_painConfidence > 0)
                Text(
                  '${(_painConfidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      top: 20,
      right: 20,
      child: FadeTransition(
        opacity: _painOverlayFadeAnimation,
        child: ScaleTransition(
          scale: _painScaleAnimation,
          child: AnimatedBuilder(
            animation: _painColorController,
            builder: (context, child) {
              final currentColor = _painColorAnimation.value ?? _getPainColor(_currentPainLevel);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPainIcon(_currentPainLevel),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPainLevel ?? 'Low',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_painConfidence > 0)
                      Text(
                        '${(_painConfidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModeratePainBanner() {
    Widget bannerContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'We detected some discomfort. Consider taking a rest if needed.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  IconData _getPainIcon(String? painLevel) {
    switch (painLevel) {
      case 'Low':
        return Icons.sentiment_satisfied;
      case 'Moderate':
        return Icons.sentiment_neutral;
      case 'Severe':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rehabPlans = UserRehabilitation.instance.rehabPlans;
    final rehabPlan = rehabPlans.isNotEmpty ? rehabPlans.first : null;
    final currentExercise = widget.exercise;
    final imagePath = currentExercise.imageUrl;
    
    // Find current exercise index by matching exercise ID
    int currentIndex = -1;
    if (rehabPlan != null) {
      for (int i = 0; i < rehabPlan.exerciseReferences.length; i++) {
        if (rehabPlan.exerciseReferences[i].exerciseId == currentExercise.exerciseId) {
          currentIndex = i;
          break;
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: RecordingDesignSystem.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: RecordingDesignSystem.primaryMedical,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(RecordingDesignSystem.spacingS),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              RecordingDesignSystem.iconBack,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          currentExercise.exerciseName,
          style: RecordingDesignSystem.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: RecordingDesignSystem.spacingM),

                // Camera Preview - Centered with proper constraints
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: RecordingDesignSystem.spacingM),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                        maxWidth: double.infinity,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
                        boxShadow: RecordingDesignSystem.shadowLarge,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: _buildCameraPreview(isDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: RecordingDesignSystem.spacingM),

                // Timer Display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: RecordingDesignSystem.spacingM),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RecordingDesignSystem.spacingL,
                      vertical: RecordingDesignSystem.spacingM,
                    ),
                    decoration: BoxDecoration(
                      gradient: RecordingDesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                      boxShadow: RecordingDesignSystem.shadowMedium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          RecordingDesignSystem.iconTimer,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: RecordingDesignSystem.spacingS),
                        StreamBuilder<Duration>(
                          stream: StopwatchService.instance.timeStream,
                          initialData: StopwatchService.instance.currentElapsed,
                          builder: (context, snapshot) {
                            final duration = snapshot.data!;
                            final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
                            final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
                            return Text(
                              '$minutes:$seconds',
                              style: RecordingDesignSystem.titleLarge.copyWith(
                                color: Colors.white,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: RecordingDesignSystem.spacingM),

                // Simplified Control Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: RecordingDesignSystem.spacingM),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    _buildSimplifiedButton(
                      icon: RecordingDesignSystem.iconBack,
                      label: 'Back',
                      gradient: RecordingDesignSystem.warningGradient,
                      onTap: () async {
                        // Stop pain detection before navigation
                        _stopPainDetection();
                        final rehabPlans = UserRehabilitation.instance.rehabPlans;
                        final rehabPlan = rehabPlans.isNotEmpty ? rehabPlans.first : null;

                        if (rehabPlan != null && rehabPlan.exerciseReferences.isNotEmpty) {
                          final prevIndex = currentIndex - 1;
                          if (prevIndex >= 0) {
                            // Record current exercise as partial if user goes back
                            try {
                              // Validate exercise data before saving
                              if (currentExercise.exerciseId.isEmpty || 
                                  currentExercise.exerciseName.isEmpty ||
                                  currentExercise.sets <= 0 ||
                                  currentExercise.repetitions <= 0) {
                                throw Exception('Invalid exercise data: missing or invalid fields');
                              }
                              
                              await ExerciseHistory.recordTodayAndSave(
                                exerciseId: currentExercise.exerciseId,
                                exerciseName: currentExercise.exerciseName,
                                sets: currentExercise.sets,
                                reps: currentExercise.repetitions,
                                durationSeconds: StopwatchService.instance.currentElapsed.inSeconds,
                                status: 'partial',
                                painScale: _painLevelToPainScale(_currentPainLevel),
                                painLevel: _currentPainLevel,
                              );
                            } catch (e) {
                              debugPrint('Failed to save partial exercise data: $e');
                              // Show error to user but continue navigation
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Warning: Failed to save exercise progress: ${e.toString()}'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }

                            final prevExerciseRef = rehabPlan.exerciseReferences[prevIndex];
                            final prevExercise = await _cacheService.getExerciseById(prevExerciseRef.exerciseId);
                            
                            if (prevExercise != null) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecordExercisePage(exercise: prevExercise),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('You are at the first exercise.')),
                            );
                          }
                        }
                      },
                    ),
                    _buildSimplifiedButton(
                      key: TutorialAnchors.recordPauseButton,
                      icon: RecordingDesignSystem.iconPause,
                      label: 'Pause',
                      gradient: RecordingDesignSystem.errorGradient,
                      onTap: () async {
                          // Record current exercise as partial when pausing
                          try {
                            // Validate exercise data before saving
                            if (currentExercise.exerciseId.isEmpty || 
                                currentExercise.exerciseName.isEmpty ||
                                currentExercise.sets <= 0 ||
                                currentExercise.repetitions <= 0) {
                              throw Exception('Invalid exercise data: missing or invalid fields');
                            }
                            
                          await ExerciseHistory.recordTodayAndSave(
                            exerciseId: currentExercise.exerciseId,
                            exerciseName: currentExercise.exerciseName,
                            sets: currentExercise.sets,
                            reps: currentExercise.repetitions,
                            durationSeconds: StopwatchService.instance.currentElapsed.inSeconds,
                            status: 'partial',
                            painScale: _painLevelToPainScale(_currentPainLevel),
                            painLevel: _currentPainLevel,
                          );
                          } catch (e) {
                            debugPrint('Failed to save partial exercise data: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Warning: Failed to save exercise progress: ${e.toString()}'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        
                        StopwatchService.instance.pause();
                        // Stop pain detection before navigation
                        _stopPainDetection();
                        Navigator.push(
                          context,
                          MedicalPageRoute(
                            child: const PreRecordPage(),
                            settings: const RouteSettings(name: '/pre-record'),
                          ),
                        );
                      },
                    ),
                    _buildSimplifiedButton(
                      key: TutorialAnchors.recordFinishButton,
                      icon: RecordingDesignSystem.iconForward,
                      label: (currentIndex + 1) < (rehabPlan?.exerciseReferences.length ?? 0) ? 'Proceed' : 'Finish',
                      gradient: RecordingDesignSystem.successGradient,
                      onTap: () async {
                        // Stop pain detection before navigation
                        _stopPainDetection();
                        final rehabPlans = UserRehabilitation.instance.rehabPlans;
                        final rehabPlan = rehabPlans.isNotEmpty ? rehabPlans.first : null;

                        if (rehabPlan != null && rehabPlan.exerciseReferences.isNotEmpty) {
                          final nextIndex = currentIndex + 1;

                          if (nextIndex < rehabPlan.exerciseReferences.length) {
                            // Record current exercise as completed when proceeding to next
                            try {
                              // Validate exercise data before saving
                              if (currentExercise.exerciseId.isEmpty || 
                                  currentExercise.exerciseName.isEmpty ||
                                  currentExercise.sets <= 0 ||
                                  currentExercise.repetitions <= 0) {
                                throw Exception('Invalid exercise data: missing or invalid fields');
                              }
                              
                            await ExerciseHistory.recordTodayAndSave(
                              exerciseId: currentExercise.exerciseId,
                              exerciseName: currentExercise.exerciseName,
                              sets: currentExercise.sets,
                              reps: currentExercise.repetitions,
                              durationSeconds: StopwatchService.instance.currentElapsed.inSeconds,
                              status: 'completed',
                              painScale: _painLevelToPainScale(_currentPainLevel),
                              painLevel: _currentPainLevel,
                            );
                            } catch (e) {
                              debugPrint('Failed to save completed exercise data: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Warning: Failed to save exercise completion: ${e.toString()}'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }

                            final nextExerciseRef = rehabPlan.exerciseReferences[nextIndex];
                            final nextExercise = await _cacheService.getExerciseById(nextExerciseRef.exerciseId);
                            
                            if (nextExercise != null) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecordExercisePage(exercise: nextExercise),
                                ),
                              );
                            }
                          } else {
                            StopwatchService.instance.pause();

                            // Update records - check if user has already exercised today
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final lastDate = UserProgress.lastExerciseDate;
                            final lastExerciseDay = lastDate != null ? DateTime(lastDate.year, lastDate.month, lastDate.day) : null;
                            
                            // Record all completed exercises for today
                            for (int i = 0; i <= currentIndex; i++) {
                              final exerciseRef = rehabPlan.exerciseReferences[i];
                              final exercise = await _cacheService.getExerciseById(exerciseRef.exerciseId);
                              if (exercise != null) {
                                try {
                                  // Validate exercise data before saving
                                  if (exercise.exerciseId.isEmpty || 
                                      exercise.exerciseName.isEmpty ||
                                      exerciseRef.sets <= 0 ||
                                      exerciseRef.repetitions <= 0) {
                                    throw Exception('Invalid exercise data: missing or invalid fields');
                                  }
                                  
                                  await ExerciseHistory.recordTodayAndSave(
                                    exerciseId: exercise.exerciseId,
                                    exerciseName: exercise.exerciseName,
                                    sets: exerciseRef.sets,
                                    reps: exerciseRef.repetitions,
                                    durationSeconds: StopwatchService.instance.currentElapsed.inSeconds,
                                    status: 'completed',
                                    painScale: _painLevelToPainScale(_currentPainLevel),
                                    painLevel: _currentPainLevel,
                                    now: now,
                                  );
                                } catch (e) {
                                  debugPrint('Failed to save completed exercise data: $e');
                                  // Continue with other exercises even if one fails
                                }
                              }
                            }
                            
                            // Only increment if this is the first exercise session of the day
                            if (lastExerciseDay == null || lastExerciseDay.isBefore(today)) {
                              // Check if this is a consecutive day for streak
                              if (lastDate != null) {
                                final daysDifference = today.difference(lastDate).inDays;
                                if (daysDifference == 1) {
                                  // Consecutive day - increment streak
                                  UserProgress.streak += 1;
                                } else if (daysDifference > 1) {
                                  // Gap in days - reset streak to 1
                                  UserProgress.streak = 1;
                                }
                              } else {
                                // First time exercising - start streak at 1
                                UserProgress.streak = 1;
                              }
                              
                              UserProgress.totalDays += 1;
                              UserProgress.totalExercises += currentIndex + 1;
                              UserProgress.totalSeconds += StopwatchService.instance.currentElapsed.inSeconds;
                              UserProgress.totalMinutes = (UserProgress.totalSeconds / 60).toInt();
                              
                              // Update last exercise date
                              UserProgress.lastExerciseDate = now;
                            }

                            StopwatchService.instance.reset();

                            // Get muscle group from assessment data
                            final muscleGroup = AssessmentData.specificMuscle.isNotEmpty 
                                ? AssessmentData.specificMuscle 
                                : 'General';
                            
                            // Get all completed exercises for cooldown
                            final completedExercises = <Exercise>[];
                            for (int i = 0; i <= currentIndex; i++) {
                              final exerciseRef = rehabPlan.exerciseReferences[i];
                              final exercise = await _cacheService.getExerciseById(exerciseRef.exerciseId);
                              if (exercise != null) {
                                completedExercises.add(exercise);
                              }
                            }

                            // Show cooldown option
                            _showCooldownOption(context, muscleGroup, completedExercises);
                          }
                        }
                      },
                    ),
                    ],
                  ),
                ),
                const SizedBox(height: RecordingDesignSystem.spacingM),
              ],
            ),
          ),

          // Bottom Sheet: Instructions
          DraggableScrollableSheet(
            initialChildSize: 0.07,
            minChildSize: 0.07,
            maxChildSize: 0.8,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: RecordingDesignSystem.getSurfaceColor(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_double_arrow_up,
                          color: RecordingDesignSystem.getTextSecondaryColor(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "^^ SWIPE UP FOR INSTRUCTIONS ^^",
                          style: RecordingDesignSystem.bodyMedium.copyWith(
                            color: RecordingDesignSystem.getTextSecondaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_double_arrow_up,
                          color: RecordingDesignSystem.getTextSecondaryColor(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInstructionCard('assets/images/exercise/$imagePath', currentExercise),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedButton({
    Key? key,
    required IconData icon, 
    required String label, 
    required LinearGradient gradient,
    required VoidCallback onTap
  }) {
    return Flexible(
      child: Container(
        key: key,
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
          boxShadow: RecordingDesignSystem.shadowMedium,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RecordingDesignSystem.spacingM,
                vertical: RecordingDesignSystem.spacingM,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: RecordingDesignSystem.spacingS),
                  Flexible(
                    child: Text(
                      label,
                      style: RecordingDesignSystem.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard(String imagePath, Exercise exercise) {
    return Container(
      decoration: BoxDecoration(
        color: RecordingDesignSystem.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
        border: Border.all(
          color: RecordingDesignSystem.getBorderColor(context),
          width: 1,
        ),
        boxShadow: RecordingDesignSystem.shadowLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(RecordingDesignSystem.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                height: 200,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: RecordingDesignSystem.getErrorColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                  ),
                  child: Icon(
                    Icons.broken_image,
                    color: RecordingDesignSystem.getErrorColor(context),
                    size: 100,
                  ),
                ),
              ),
            ),
            const SizedBox(height: RecordingDesignSystem.spacingM),
            Text(
              exercise.description,
              style: RecordingDesignSystem.bodyMedium.copyWith(
                color: RecordingDesignSystem.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: RecordingDesignSystem.spacingM),
            _buildInfoRow(Icons.fitness_center, 'Muscle Group: ${exercise.muscle}'),
            _buildInfoRow(Icons.local_hospital, 'Pain Level: ${exercise.painLevel}'),
            _buildInfoRow(Icons.flag, 'Goal: ${exercise.goal}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RecordingDesignSystem.spacingXS),
      child: Row(
        children: [
          Icon(
            icon,
            color: RecordingDesignSystem.getTextSecondaryColor(context),
            size: 18,
          ),
          const SizedBox(width: RecordingDesignSystem.spacingS),
          Expanded(
            child: Text(
              text,
              style: RecordingDesignSystem.bodyMedium.copyWith(
                color: RecordingDesignSystem.getTextSecondaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCooldownOption(BuildContext context, String muscleGroup, List<Exercise> completedExercises) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Great Work!',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8B2E2E),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You\'ve completed all exercises! We recommend a cooldown stretching routine to help your $muscleGroup muscles recover.',
                style: GoogleFonts.ptSans(
                  fontSize: 16,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B2E2E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.self_improvement, color: const Color(0xFF8B2E2E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cooldown helps reduce muscle soreness and promotes recovery',
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          color: const Color(0xFF8B2E2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedToSave(context);
              },
              child: Text(
                'Skip Cooldown',
                style: TextStyle(color: const Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startCooldown(muscleGroup, completedExercises);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2E2E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Cooldown'),
            ),
          ],
        );
      },
    );
  }

  void _startCooldown(String muscleGroup, List<Exercise> completedExercises) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CooldownStretchingPage(
              muscleGroup: muscleGroup,
              completedExercises: completedExercises,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = RecordingDesignSystem.animationCurve;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: RecordingDesignSystem.animationMedium,
      ),
    );
  }

  void _proceedToSave(BuildContext context) {
    // Get root navigator context before pushing new page to avoid context issues
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    
    Navigator.push(
      context,
      MedicalPageRoute(
        child: ConfirmSavePage(
          onSave: () {
            // Close the ConfirmSavePage first without popping the exercise page
            if (rootNavigator.canPop()) {
              rootNavigator.pop();
            }

            // Use post-frame callback to ensure navigation happens after widget tree is stable
            // This prevents "Looking up a deactivated widget's ancestor" errors
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                // Use the stored root navigator to navigate
                rootNavigator.pushAndRemoveUntil(
                  MedicalPageRoute(
                    child: HomePageWithDialog(),
                    settings: const RouteSettings(name: '/home'),
                  ),
                  (route) => false,
                );
              } catch (e) {
                debugPrint('Navigation error after save: $e');
                // Fallback: try to get a fresh root navigator context
                try {
                  final fallbackContext = rootNavigator.context;
                  if (fallbackContext.mounted) {
                    Navigator.pushAndRemoveUntil(
                      fallbackContext,
                      MedicalPageRoute(
                        child: HomePageWithDialog(),
                        settings: const RouteSettings(name: '/home'),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e2) {
                  debugPrint('Fallback navigation also failed: $e2');
                }
              }
            });
          },
          onCancel: () {
            if (rootNavigator.canPop()) {
              rootNavigator.pop();
            }
          },
        ),
        settings: const RouteSettings(name: '/confirm-save'),
      ),
    );
  }
}