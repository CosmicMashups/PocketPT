import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import '../home_dialog.dart';
import '../data/rehabilitation_plan.dart';
import '../core/animations.dart';
import 'pre_record_page.dart';
import 'confirm_save_page.dart';
import 'stopwatch_service.dart';
import 'camera_service.dart';
import 'exercise_cache_service.dart';
import 'design_system.dart';
class RecordExercisePage extends StatefulWidget {
  final Exercise exercise;

  const RecordExercisePage({required this.exercise, super.key});

  @override
  State<RecordExercisePage> createState() => _RecordExercisePageState();
}

class _RecordExercisePageState extends State<RecordExercisePage> with TickerProviderStateMixin {
  final CameraService _cameraService = CameraService.instance;
  final ExerciseCacheService _cacheService = ExerciseCacheService.instance;
  bool _isCameraInitialized = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.medium,
    );
    _initializeCamera();
    StopwatchService.instance.start();
  }

  @override
  void dispose() {
    _animationController.dispose();
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


  Widget _buildCameraPreview(bool isDark) {
    if (_isCameraInitialized && _cameraService.isReady) {
      final cameraPreview = _cameraService.getEnhancedCameraPreview(context);
      if (cameraPreview != null) {
        return Semantics(
          label: 'Camera preview for exercise recording',
          hint: 'Double tap to focus camera',
          child: cameraPreview,
        );
      }
    }

    // Show loading state with enhanced design
    return _cameraService.getLoadingIndicator(context);
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

                // Camera Preview with responsive layout
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
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

                            Navigator.push(
                              context,
                              MedicalPageRoute(
                                child: ConfirmSavePage(
                                  onSave: () {
                                    // The progress has already been updated in the main section
                                    // Just navigate to home page
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
                                    Navigator.pop(context); // return to exercise screen
                                  },
                                ),
                                settings: const RouteSettings(name: '/confirm-save'),
                              ),
                            );
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
}