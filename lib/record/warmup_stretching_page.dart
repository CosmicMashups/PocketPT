import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _loadAttempted = false;
  String? _specificMuscle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First, try to load specificMuscle from Hive (userAssess key)
      try {
        await UserAssess.loadFromHive();
        _specificMuscle = UserAssess.specificMuscle.isNotEmpty 
            ? UserAssess.specificMuscle 
            : null;
        
        // If Hive value is "General" or empty, load from Firebase
        if (_specificMuscle == null || _specificMuscle!.isEmpty || _specificMuscle!.toLowerCase() == 'general') {
          print('WarmupStretchingPage: Hive value is "${_specificMuscle ?? "empty"}", loading from Firebase');
          
          // Load from Firebase if Hive doesn't have valid data
          try {
            final User? currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              final DocumentSnapshot doc = await FirebaseFirestore.instance
                  .collection('assessment')
                  .doc(currentUser.uid)
                  .get();
              
              if (doc.exists) {
                final data = doc.data() as Map<String, dynamic>;
                final firebaseMuscle = data['specificMuscle'] as String? ?? '';
                
                // Only use Firebase value if it's not empty and not "General"
                if (firebaseMuscle.isNotEmpty && firebaseMuscle.toLowerCase() != 'general') {
                  _specificMuscle = firebaseMuscle;
                  UserAssess.specificMuscle = _specificMuscle!;
                  await UserAssess.saveToHive();
                  print('WarmupStretchingPage: Loaded specificMuscle from Firebase: "$_specificMuscle"');
                } else {
                  print('WarmupStretchingPage: Firebase value is also "${firebaseMuscle}", keeping Hive value or using fallback');
                }
              }
            }
          } catch (e) {
            print('WarmupStretchingPage: Error loading specificMuscle from Firebase: $e');
          }
        } else {
          print('WarmupStretchingPage: Loaded specificMuscle from Hive: "$_specificMuscle"');
        }
      } catch (e) {
        print('WarmupStretchingPage: Error loading from Hive: $e');
        // Try Firebase as fallback
        try {
          final User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final DocumentSnapshot doc = await FirebaseFirestore.instance
                .collection('assessment')
                .doc(currentUser.uid)
                .get();
            
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              final firebaseMuscle = data['specificMuscle'] as String? ?? '';
              
              // Only use Firebase value if it's not empty and not "General"
              if (firebaseMuscle.isNotEmpty && firebaseMuscle.toLowerCase() != 'general') {
                _specificMuscle = firebaseMuscle;
                UserAssess.specificMuscle = _specificMuscle!;
                await UserAssess.saveToHive();
                print('WarmupStretchingPage: Loaded specificMuscle from Firebase (fallback): "$_specificMuscle"');
              }
            }
          }
        } catch (firebaseError) {
          print('WarmupStretchingPage: Error loading from Firebase: $firebaseError');
        }
      }
      
      // Use specificMuscle from Hive/Firebase, fallback to UserAssess, then widget parameter
      final muscleGroupToUse = _specificMuscle?.isNotEmpty == true 
          ? _specificMuscle! 
          : (UserAssess.specificMuscle.isNotEmpty 
              ? UserAssess.specificMuscle 
              : widget.muscleGroup);
      
      print('WarmupStretchingPage: Final muscleGroupToUse: "$muscleGroupToUse"');
      
      // Get pain scale from assessment data
      final painScale = UserAssess.painScale;
      print('WarmupStretchingPage: Loading routines for $muscleGroupToUse with pain level $painScale');
      
      try {
        await ref.read(stretchingProvider.notifier).loadRoutinesForMuscleWithPainLevel(
          muscleGroupToUse, painScale);
        
        // Check if routines were loaded successfully
        final stretchingState = ref.read(stretchingProvider);
        if (stretchingState.currentWarmupRoutine == null) {
          print('WarmupStretchingPage: No warmup routine found with pain level, trying without pain filtering');
          await ref.read(stretchingProvider.notifier).loadRoutinesForMuscle(muscleGroupToUse);
          
          // Check again after fallback
          final updatedState = ref.read(stretchingProvider);
          if (updatedState.currentWarmupRoutine == null) {
            print('WarmupStretchingPage: Still no warmup routine found, will show appropriate message');
          }
        }
      } catch (e) {
        print('WarmupStretchingPage: Error loading routines: $e');
        // Try fallback without pain level filtering
        try {
          await ref.read(stretchingProvider.notifier).loadRoutinesForMuscle(muscleGroupToUse);
        } catch (fallbackError) {
          print('WarmupStretchingPage: Fallback also failed: $fallbackError');
        }
      } finally {
        if (mounted) {
          setState(() {
            _loadAttempted = true;
          });
        } else {
          _loadAttempted = true;
        }
      }
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
            // Show loading until we've attempted to load
            if (!_loadAttempted) {
              return _buildLoadingState();
            }
            // After attempts completed and still null, show no routine state
            return _buildNoRoutineState();
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

  Widget _buildNoRoutineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: mainColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Warm-up Routine Available',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No warm-up routines were found for ${_specificMuscle?.isNotEmpty == true ? _specificMuscle! : (UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle : widget.muscleGroup)}.\nYou can proceed directly to your exercise.',
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: detailColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _startExercise(),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Start Exercise'),
          ),
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
          color: RecordingDesignSystem.warningColor.withOpacity(0.3),
          width: 2,
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
                  gradient: RecordingDesignSystem.warningGradient,
                  borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
                  boxShadow: RecordingDesignSystem.medicalShadow,
                ),
                child: Icon(
                  RecordingDesignSystem.iconWarmup,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: RecordingDesignSystem.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Prepare Your Muscles",
                            style: RecordingDesignSystem.headlineMedium.copyWith(
                              color: RecordingDesignSystem.getTextPrimaryColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: RecordingDesignSystem.spacingM,
                            vertical: RecordingDesignSystem.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: RecordingDesignSystem.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusS),
                            border: Border.all(
                              color: RecordingDesignSystem.warningColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                RecordingDesignSystem.iconTimer,
                                color: RecordingDesignSystem.warningColor,
                                size: 16,
                              ),
                              const SizedBox(width: RecordingDesignSystem.spacingXS),
                              Text(
                                '5-10 min',
                                style: RecordingDesignSystem.bodySmall.copyWith(
                                  color: RecordingDesignSystem.warningColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RecordingDesignSystem.spacingXS),
                    Text(
                      "Warm-up stretching for ${_specificMuscle?.isNotEmpty == true ? _specificMuscle! : (UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle : widget.muscleGroup)}",
                      style: RecordingDesignSystem.bodyMedium.copyWith(
                        color: RecordingDesignSystem.getTextSecondaryColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: RecordingDesignSystem.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RecordingDesignSystem.spacingM,
                        vertical: RecordingDesignSystem.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: RecordingDesignSystem.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            RecordingDesignSystem.iconCheck,
                            color: RecordingDesignSystem.successColor,
                            size: 16,
                          ),
                          const SizedBox(width: RecordingDesignSystem.spacingXS),
                          Text(
                            'Injury Prevention',
                            style: RecordingDesignSystem.bodySmall.copyWith(
                              color: RecordingDesignSystem.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
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
