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
  
  // Severe pain dialog cooldown
  DateTime? _lastSeverePainDialogTime;
  static const Duration _severePainDialogCooldown = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _animationController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.medium,
    );
    _initializeCamera();
    _initializePainDetection();
    StopwatchService.instance.start();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _painDetectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final success = await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = success;
        });
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

  Future<void> _initializePainDetection() async {
    try {
      await _painService.initialize();
      if (mounted) {
        setState(() {
          _isPainDetectionEnabled = true;
        });
        _startPainDetection();
      }
    } catch (e) {
      debugPrint('Error initializing pain detection: $e');
      if (mounted) {
        setState(() {
          _isPainDetectionEnabled = false;
        });
      }
    }
  }

  void _startPainDetection() {
    if (!_isPainDetectionEnabled || !_isCameraInitialized) return;
    
    _painDetectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!mounted || !_cameraService.isReady) return;
      
      try {
        // For now, we'll use a simulated camera image since we need to implement
        // proper camera image capture for pain detection
        // This will be replaced with actual camera image processing
        final result = await _painService.detectFacialPain(
          image: null, // Will be implemented with proper camera image capture
          camera: _cameraService.controller!.description,
        );
        
        if (mounted && result['error'] == null) {
          _handlePainDetectionResult(result);
        }
      } catch (e) {
        debugPrint('Pain detection error: $e');
      }
    });
  }

  void _handlePainDetectionResult(Map<String, dynamic> result) {
    final painLevel = result['painLevel'];
    final confidence = result['confidence'];
    
    if (confidence > 0.7) {
      setState(() {
        _currentPainLevel = painLevel;
        _painConfidence = confidence;
      });
      
      _triggerPainIntervention(painLevel);
    }
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

  void _showModeratePainBanner() {
    if (_showPainBanner) return; // Prevent multiple banners
    
    setState(() {
      _showPainBanner = true;
    });
    
    // Auto-dismiss after 10 seconds
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showPainBanner = false;
        });
      }
    });
  }

  void _dismissPainBanner() {
    setState(() {
      _showPainBanner = false;
    });
  }

  void _showSeverePainDialog() {
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
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Severe Pain Detected'),
          ],
        ),
        content: Text(
          'We\'ve detected severe pain during your exercise. '
          'For your safety, we recommend taking a rest. '
          'Are you able to continue safely?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pauseExerciseForRest();
            },
            child: Text('Take a Rest'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _continueExercise();
            },
            child: Text('Continue Exercise'),
          ),
        ],
      ),
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
            // Pain detection overlay
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

  Widget _buildPainDetectionOverlay() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getPainColor(_currentPainLevel).withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
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
            SizedBox(height: 4),
            Text(
              _currentPainLevel ?? 'Low',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_painConfidence > 0)
              Text(
                '${(_painConfidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeratePainBanner() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'We detected some discomfort. Consider taking a rest if needed.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: _dismissPainBanner,
              child: Text(
                'Dismiss',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
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
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
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
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Exercise Recording',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title under AppBar
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currentExercise.exerciseName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Camera Preview with 9:16 aspect ratio
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width * (16 / 9),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: _buildCameraPreview(isDark),
                ),
                const SizedBox(height: 10),

                // Enhanced Timer Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RecordingDesignSystem.spacingL,
                    vertical: RecordingDesignSystem.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color: RecordingDesignSystem.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
                    border: Border.all(
                      color: RecordingDesignSystem.primaryMedical.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: RecordingDesignSystem.medicalShadow,
                  ),
                  child: StreamBuilder<Duration>(
                    stream: StopwatchService.instance.timeStream,
                    initialData: StopwatchService.instance.currentElapsed,
                    builder: (context, snapshot) {
                      final duration = snapshot.data!;
                      final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
                      final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
                      return Text(
                        '$minutes:$seconds',
                        style: RecordingDesignSystem.displayMedium.copyWith(
                          color: RecordingDesignSystem.primaryMedical,
                          letterSpacing: 1.2,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons with responsive layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCustomButton(
                      icon: Icons.arrow_back,
                      label: 'Back',
                      onTap: () async {
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
                    _buildCircleButton(
                      icon: Icons.pause,
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
                        Navigator.push(
                          context,
                          MedicalPageRoute(
                            child: const PreRecordPage(),
                            settings: const RouteSettings(name: '/pre-record'),
                          ),
                        );
                      },
                    ),
                    _buildCustomButton(
                      icon: Icons.arrow_forward,
                      label: (currentIndex + 1) < (rehabPlan?.exerciseReferences.length ?? 0) ? 'Proceed' : 'Finish',
                      onTap: () async {
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
                color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.keyboard_double_arrow_up, color: Colors.white70),
                        SizedBox(width: 8),
                        Text("SWIPE UP FOR INSTRUCTIONS", style: TextStyle(color: Colors.white70)),
                        SizedBox(width: 8),
                        Icon(Icons.keyboard_double_arrow_up, color: Colors.white70),
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

  Widget _buildCustomButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [RecordingDesignSystem.primaryMedical, RecordingDesignSystem.secondaryMedical],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
          boxShadow: RecordingDesignSystem.medicalShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: RecordingDesignSystem.spacingM,
                vertical: RecordingDesignSystem.spacingM,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                      textAlign: TextAlign.center,
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

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [RecordingDesignSystem.successColor, const Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: RecordingDesignSystem.successColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, size: 28, color: Colors.white),
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
    Navigator.push(
      context,
      MedicalPageRoute(
        child: ConfirmSavePage(
          onSave: () {
            Navigator.pushAndRemoveUntil(
              context,
              MedicalPageRoute(
                child: HomePageWithDialog(),
                settings: const RouteSettings(name: '/home'),
              ),
              (route) => false,
            );
          },
          onCancel: () {
            Navigator.pop(context);
          },
        ),
        settings: const RouteSettings(name: '/confirm-save'),
      ),
    );
  }
}