import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../stretching/providers/stretching_provider.dart';
import '../stretching/widgets/exercise_instruction_widget.dart';
import '../stretching/widgets/routine_progress_widget.dart';
import '../data/rehabilitation_plan.dart';
import '../data/globals.dart';
import 'record_exercise.dart';
import 'design_system.dart';

class WarmupStretchingPage extends ConsumerStatefulWidget {
  final String muscleGroup;
  final Exercise firstExercise;
  
  const WarmupStretchingPage({
    Key? key,
    required this.muscleGroup,
    required this.firstExercise,
  }) : super(key: key);

  @override
  ConsumerState<WarmupStretchingPage> createState() => _WarmupStretchingPageState();
}

class _WarmupStretchingPageState extends ConsumerState<WarmupStretchingPage> {
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get pain scale from assessment data
      final painScale = UserAssess.painScale;
      ref.read(stretchingProvider.notifier).loadRoutinesForMuscleWithPainLevel(
        widget.muscleGroup, painScale);
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: RecordingDesignSystem.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: mainColor,
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
          "Warm-up Stretching",
          style: RecordingDesignSystem.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final stretchingState = ref.watch(stretchingProvider);
          final stretchingNotifier = ref.read(stretchingProvider.notifier);
          final routine = stretchingState.currentWarmupRoutine;

          if (routine == null) {
            return _buildLoadingState();
          }

          return SafeArea(
            child: Column(
              children: [
                // Header Section
                _buildHeaderSection(),
                
                const SizedBox(height: 24),
                
                // Progress Section
                RoutineProgressWidget(
                  currentExercise: stretchingState.currentExerciseIndex,
                  totalExercises: routine.exercises.length,
                  remainingTime: stretchingState.remainingTime,
                  currentExerciseName: stretchingNotifier.currentExercise?.exerciseName ?? '',
                  progressPercentage: stretchingNotifier.progressPercentage,
                ),
                
                const SizedBox(height: 24),
                
                // Exercise Instruction
                Expanded(
                  child: stretchingNotifier.currentExercise != null
                      ? ExerciseInstructionWidget(
                          exercise: stretchingNotifier.currentExercise!,
                          isActive: stretchingState.isRoutineActive,
                          remainingTime: stretchingState.remainingTime,
                          onNext: () => stretchingNotifier.nextExercise(),
                          onPrevious: () => stretchingNotifier.previousExercise(),
                          onComplete: () => _completeWarmup(stretchingNotifier),
                        )
                      : _buildRoutineComplete(),
                ),
                
                // Control Buttons
                _buildControlButtons(stretchingState, stretchingNotifier),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading warm-up routine...'),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(RecordingDesignSystem.spacingM),
      padding: const EdgeInsets.all(RecordingDesignSystem.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RecordingDesignSystem.getSurfaceColor(context),
            RecordingDesignSystem.getSurfaceColor(context).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusXL),
        border: Border.all(
          color: RecordingDesignSystem.getBorderColor(context),
          width: 1,
        ),
        boxShadow: RecordingDesignSystem.medicalShadowLarge,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(RecordingDesignSystem.spacingM),
                decoration: BoxDecoration(
                  gradient: RecordingDesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
                  boxShadow: RecordingDesignSystem.medicalShadow,
                ),
                child: Icon(
                  RecordingDesignSystem.iconWarmup,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: RecordingDesignSystem.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Prepare Your Muscles",
                      style: RecordingDesignSystem.headlineMedium.copyWith(
                        color: RecordingDesignSystem.getTextPrimaryColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: RecordingDesignSystem.spacingXS),
                    Text(
                      "Warm-up stretching for ${widget.muscleGroup}",
                      style: RecordingDesignSystem.bodyMedium.copyWith(
                        color: RecordingDesignSystem.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RecordingDesignSystem.spacingM),
          Container(
            padding: const EdgeInsets.all(RecordingDesignSystem.spacingM),
            decoration: BoxDecoration(
              gradient: RecordingDesignSystem.successGradient,
              borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
              boxShadow: RecordingDesignSystem.shadowSmall,
            ),
            child: Row(
              children: [
                Icon(
                  RecordingDesignSystem.iconInfo,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: RecordingDesignSystem.spacingS),
                Expanded(
                  child: Text(
                    'Warm-up helps prevent injury and improves exercise performance',
                    style: RecordingDesignSystem.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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

  Widget _buildRoutineComplete() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Warm-up Complete!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your muscles are now prepared for exercise. Ready to start recording?',
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: detailColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(StretchingState state, StretchingNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (state.currentExerciseIndex > 0)
                ElevatedButton.icon(
                  onPressed: () => notifier.previousExercise(),
                  icon: const Icon(Icons.skip_previous),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: detailColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              
              if (state.isRoutineActive)
                ElevatedButton.icon(
                  onPressed: state.isPaused 
                      ? () => notifier.resumeRoutine()
                      : () => notifier.pauseRoutine(),
                  icon: Icon(state.isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(state.isPaused ? 'Resume' : 'Pause'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: subColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              
              ElevatedButton.icon(
                onPressed: () => notifier.nextExercise(),
                icon: const Icon(Icons.skip_next),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Skip and Start Exercise buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _skipWarmup(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: detailColor),
                    foregroundColor: detailColor,
                  ),
                  child: const Text('Skip Warm-up'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startExercise(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Exercise'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _completeWarmup(StretchingNotifier notifier) {
    notifier.completeRoutine();
  }

  void _skipWarmup() {
    _startExercise();
  }

  void _startExercise() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RecordExercisePage(exercise: widget.firstExercise),
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
}
