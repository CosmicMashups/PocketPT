import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../stretching/providers/stretching_provider.dart';
import '../stretching/widgets/combined_progress_instruction_widget.dart';
import '../data/rehabilitation_plan.dart';
import '../data/globals.dart';
import '../home_dialog.dart';
import 'confirm_save_page.dart';
import '../core/animations.dart';
import 'design_system.dart';

class CooldownStretchingPage extends ConsumerStatefulWidget {
  final String muscleGroup;
  final List<Exercise> completedExercises;
  
  const CooldownStretchingPage({
    super.key,
    required this.muscleGroup,
    required this.completedExercises,
  });

  @override
  ConsumerState<CooldownStretchingPage> createState() => _CooldownStretchingPageState();
}

class _CooldownStretchingPageState extends ConsumerState<CooldownStretchingPage> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _loadAttempted = false;
  String? _specificMuscle;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: RecordingDesignSystem.animationMedium,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: RecordingDesignSystem.animationCurve,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: RecordingDesignSystem.animationCurve,
    ));
    
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First, try to load specificMuscle from Hive (userAssess key)
      try {
        await UserAssess.loadFromHive();
        _specificMuscle = UserAssess.specificMuscle.isNotEmpty 
            ? UserAssess.specificMuscle 
            : null;
        
        // If Hive value is "General" or empty, load from Firebase
        if (_specificMuscle == null || _specificMuscle!.isEmpty || _specificMuscle!.toLowerCase() == 'general') {
          print('CooldownStretchingPage: Hive value is "${_specificMuscle ?? "empty"}", loading from Firebase');
          
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
                  print('CooldownStretchingPage: Loaded specificMuscle from Firebase: "$_specificMuscle"');
                } else {
                  print('CooldownStretchingPage: Firebase value is also "${firebaseMuscle}", keeping Hive value or using fallback');
                }
              }
            }
          } catch (e) {
            print('CooldownStretchingPage: Error loading specificMuscle from Firebase: $e');
          }
        } else {
          print('CooldownStretchingPage: Loaded specificMuscle from Hive: "$_specificMuscle"');
        }
      } catch (e) {
        print('CooldownStretchingPage: Error loading from Hive: $e');
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
                print('CooldownStretchingPage: Loaded specificMuscle from Firebase (fallback): "$_specificMuscle"');
              }
            }
          }
        } catch (firebaseError) {
          print('CooldownStretchingPage: Error loading from Firebase: $firebaseError');
        }
      }
      
      // Use specificMuscle from Hive/Firebase, fallback to UserAssess, then widget parameter
      final muscleGroupToUse = _specificMuscle?.isNotEmpty == true 
          ? _specificMuscle! 
          : (UserAssess.specificMuscle.isNotEmpty 
              ? UserAssess.specificMuscle 
              : widget.muscleGroup);
      
      print('CooldownStretchingPage: Final muscleGroupToUse: "$muscleGroupToUse"');
      
      // Get pain scale from assessment data
      final painScale = UserAssess.painScale;
      print('CooldownStretchingPage: Loading routines for $muscleGroupToUse with pain level $painScale');
      print('CooldownStretchingPage: [CSV LOAD] This will trigger loading of stretching_exercises.csv');
      
      try {
        await ref.read(stretchingProvider.notifier).loadRoutinesForMuscleWithPainLevel(
          muscleGroupToUse, painScale);
        
        // Check if routines were loaded successfully
        final stretchingState = ref.read(stretchingProvider);
        if (stretchingState.currentCooldownRoutine == null) {
          print('CooldownStretchingPage: No cooldown routine found with pain level, trying without pain filtering');
          print('CooldownStretchingPage: [CSV LOAD] Retrying without pain level filter - will use cached CSV if already loaded');
          await ref.read(stretchingProvider.notifier).loadRoutinesForMuscle(muscleGroupToUse);
          
          // Check again after fallback
          final updatedState = ref.read(stretchingProvider);
          if (updatedState.currentCooldownRoutine == null) {
            print('CooldownStretchingPage: Still no cooldown routine found, will show appropriate message');
          } else {
            // Initialize routine after loading (doesn't start timer until readiness confirmed)
            ref.read(stretchingProvider.notifier).startRoutine(updatedState.currentCooldownRoutine!);
            // Show readiness dialog
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showReadinessDialog(context, ref);
              });
            }
          }
        } else {
          // Initialize routine after loading (doesn't start timer until readiness confirmed)
          ref.read(stretchingProvider.notifier).startRoutine(stretchingState.currentCooldownRoutine!);
          // Show readiness dialog
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showReadinessDialog(context, ref);
            });
          }
        }
      } catch (e) {
        print('CooldownStretchingPage: Error loading routines: $e');
        print('CooldownStretchingPage: [CSV LOAD] Error occurred, attempting fallback - will use cached CSV if available');
        // Try fallback without pain level filtering
        try {
          await ref.read(stretchingProvider.notifier).loadRoutinesForMuscle(muscleGroupToUse);
          final fallbackState = ref.read(stretchingProvider);
          if (fallbackState.currentCooldownRoutine != null) {
            // Initialize routine after loading (doesn't start timer until readiness confirmed)
            ref.read(stretchingProvider.notifier).startRoutine(fallbackState.currentCooldownRoutine!);
            // Show readiness dialog
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showReadinessDialog(context, ref);
              });
            }
          }
        } catch (fallbackError) {
          print('CooldownStretchingPage: Fallback also failed: $fallbackError');
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    
    return Scaffold(
      backgroundColor: RecordingDesignSystem.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(RecordingDesignSystem.spacingS),
          decoration: BoxDecoration(
            gradient: RecordingDesignSystem.neutralGradient,
            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
            boxShadow: RecordingDesignSystem.shadowMedium,
            border: Border.all(
              color: RecordingDesignSystem.getBorderColor(context),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              RecordingDesignSystem.iconBack,
              color: RecordingDesignSystem.primaryMedical,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "Cooldown Stretching",
          style: RecordingDesignSystem.headlineMedium.copyWith(
            color: RecordingDesignSystem.getTextPrimaryColor(context),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final stretchingState = ref.watch(stretchingProvider);
          final stretchingNotifier = ref.read(stretchingProvider.notifier);
          final routine = stretchingState.currentCooldownRoutine;

          if (routine == null) {
            // Show loading until we've attempted to load
            if (!_loadAttempted) {
              return _buildLoadingState();
            }
            // After attempts completed and still null, show no routine state
            return _buildNoRoutineState();
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    children: [
                      // Enhanced Header Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: RecordingDesignSystem.spacingM,
                          vertical: RecordingDesignSystem.spacingS,
                        ),
                        child: _buildEnhancedHeaderSection(),
                      ),
                      
                      // Show Start button if routine loaded but not confirmed
                      if (!stretchingState.isReadyConfirmed && stretchingState.isRoutineActive)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: RecordingDesignSystem.spacingM,
                            vertical: RecordingDesignSystem.spacingS,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _showReadinessDialog(context, ref),
                            icon: Icon(
                              RecordingDesignSystem.iconPlay,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: Text(
                              'Start Cooldown',
                              style: RecordingDesignSystem.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RecordingDesignSystem.primaryMedical,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: RecordingDesignSystem.spacingL,
                                vertical: RecordingDesignSystem.spacingS,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                              ),
                            ),
                          ),
                        ),
                      
                      // Combined Progress and Exercise Instruction (only show when confirmed)
                      if (stretchingState.isReadyConfirmed)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: RecordingDesignSystem.spacingM),
                          child: stretchingNotifier.currentExercise != null
                              ? CombinedProgressInstructionWidget(
                                  currentExercise: stretchingState.currentExerciseIndex,
                                  totalExercises: stretchingState.currentCooldownRoutine?.exercises.length ?? 0,
                                  remainingTime: stretchingState.remainingTime,
                                  currentExerciseName: stretchingNotifier.currentExercise?.exerciseName ?? '',
                                  progressPercentage: stretchingNotifier.progressPercentage,
                                  exercise: stretchingNotifier.currentExercise!,
                                  isActive: stretchingState.isRoutineActive && stretchingState.isReadyConfirmed,
                                  onNext: () => stretchingNotifier.nextExercise(),
                                  onPrevious: () => stretchingNotifier.previousExercise(),
                                  onComplete: () => _completeCooldown(stretchingNotifier),
                                )
                              : _buildRoutineComplete(),
                        ),
                      
                      // Enhanced Control Buttons (only show when confirmed)
                      if (stretchingState.isReadyConfirmed)
                        _buildEnhancedControlButtons(stretchingState, stretchingNotifier),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(RecordingDesignSystem.spacingL),
            decoration: BoxDecoration(
              gradient: RecordingDesignSystem.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: RecordingDesignSystem.medicalShadow,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingL),
          Text(
            'Preparing your cooldown routine...',
            style: RecordingDesignSystem.bodyLarge.copyWith(
              color: RecordingDesignSystem.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingM),
          Text(
            'This may take a few moments',
            style: RecordingDesignSystem.bodyMedium.copyWith(
              color: RecordingDesignSystem.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRoutineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(RecordingDesignSystem.spacingL),
            decoration: BoxDecoration(
              gradient: RecordingDesignSystem.neutralGradient,
              shape: BoxShape.circle,
              boxShadow: RecordingDesignSystem.shadowMedium,
            ),
            child: Icon(
              RecordingDesignSystem.iconComplete,
              size: 60,
              color: RecordingDesignSystem.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingL),
          Text(
            'No Cooldown Routine Available',
            style: RecordingDesignSystem.headlineLarge.copyWith(
              color: RecordingDesignSystem.getTextPrimaryColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingM),
          Text(
            'No cooldown routines were found for ${_specificMuscle?.isNotEmpty == true ? _specificMuscle! : (UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle : widget.muscleGroup)}.\nYou can finish your session directly.',
            style: RecordingDesignSystem.bodyLarge.copyWith(
              color: RecordingDesignSystem.getTextSecondaryColor(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RecordingDesignSystem.spacingXL),
          _buildActionButton(
            icon: RecordingDesignSystem.iconComplete,
            label: 'Finish Session',
            onPressed: () => _finishSession(),
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeaderSection() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: RecordingDesignSystem.spacingM,
        vertical: RecordingDesignSystem.spacingS,
      ),
      padding: const EdgeInsets.all(RecordingDesignSystem.spacingM),
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
          color: RecordingDesignSystem.accentTeal.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: RecordingDesignSystem.medicalShadowLarge,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(RecordingDesignSystem.spacingS),
                decoration: BoxDecoration(
                  gradient: RecordingDesignSystem.infoGradient,
                  borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                  boxShadow: RecordingDesignSystem.medicalShadow,
                ),
                child: Icon(
                  RecordingDesignSystem.iconCooldown,
                  color: Colors.white,
                  size: 24,
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
                            "Recovery & Relaxation",
                            style: RecordingDesignSystem.headlineMedium.copyWith(
                              color: RecordingDesignSystem.getTextPrimaryColor(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: RecordingDesignSystem.spacingM,
                            vertical: RecordingDesignSystem.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: RecordingDesignSystem.accentTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusS),
                            border: Border.all(
                              color: RecordingDesignSystem.accentTeal.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                RecordingDesignSystem.iconTimer,
                                color: RecordingDesignSystem.accentTeal,
                                size: 16,
                              ),
                              const SizedBox(width: RecordingDesignSystem.spacingXS),
                              Text(
                                '5-10 min',
                                style: RecordingDesignSystem.bodySmall.copyWith(
                                  color: RecordingDesignSystem.accentTeal,
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
                      "Cooldown stretching for ${_specificMuscle?.isNotEmpty == true ? _specificMuscle! : (UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle : widget.muscleGroup)}",
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
                            RecordingDesignSystem.iconComplete,
                            color: RecordingDesignSystem.successColor,
                            size: 16,
                          ),
                          const SizedBox(width: RecordingDesignSystem.spacingXS),
                          Text(
                            'Recovery Aid',
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
          const SizedBox(height: RecordingDesignSystem.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RecordingDesignSystem.spacingM,
              vertical: RecordingDesignSystem.spacingS,
            ),
            decoration: BoxDecoration(
              gradient: RecordingDesignSystem.successGradient,
              borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
              boxShadow: RecordingDesignSystem.shadowSmall,
            ),
            child: Row(
              children: [
                Icon(
                  RecordingDesignSystem.iconSuccess,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: RecordingDesignSystem.spacingS),
                Expanded(
                  child: Text(
                    'Great work! Cooldown helps reduce muscle soreness and promotes recovery',
                    style: RecordingDesignSystem.bodySmall.copyWith(
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
      margin: const EdgeInsets.all(RecordingDesignSystem.spacingM),
      padding: const EdgeInsets.all(RecordingDesignSystem.spacingXL),
      decoration: BoxDecoration(
        gradient: RecordingDesignSystem.successGradient,
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusXL),
        boxShadow: RecordingDesignSystem.medicalShadowLarge,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(RecordingDesignSystem.spacingL),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              RecordingDesignSystem.iconComplete,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingL),
          Text(
            'Cooldown Complete!',
            style: RecordingDesignSystem.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingM),
          Text(
            'Your muscles are now relaxed and ready for recovery. Excellent work on completing your session!',
            style: RecordingDesignSystem.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedControlButtons(final StretchingState state, final StretchingNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RecordingDesignSystem.spacingM,
        vertical: RecordingDesignSystem.spacingS,
      ),
      decoration: BoxDecoration(
        color: RecordingDesignSystem.getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary control buttons
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (state.currentExerciseIndex > 0)
                  _buildControlButton(
                    icon: RecordingDesignSystem.iconBack,
                    label: 'Previous',
                    onPressed: () => notifier.previousExercise(),
                    gradient: RecordingDesignSystem.neutralGradient,
                    textColor: RecordingDesignSystem.getTextPrimaryColor(context),
                  ),
                
                if (state.isRoutineActive)
                  _buildControlButton(
                    icon: state.isPaused ? RecordingDesignSystem.iconPlay : RecordingDesignSystem.iconPause,
                    label: state.isPaused ? 'Resume' : 'Pause',
                    onPressed: state.isPaused 
                        ? () => notifier.resumeRoutine()
                        : () => notifier.pauseRoutine(),
                    gradient: RecordingDesignSystem.warningGradient,
                    textColor: Colors.white,
                  ),
                
                _buildControlButton(
                  icon: RecordingDesignSystem.iconForward,
                  label: 'Next',
                  onPressed: () => notifier.nextExercise(),
                  gradient: RecordingDesignSystem.primaryGradient,
                  textColor: Colors.white,
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: RecordingDesignSystem.iconHome,
                    label: 'Skip Cooldown',
                    onPressed: () => _skipCooldown(),
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: RecordingDesignSystem.iconComplete,
                    label: 'Finish Session',
                    onPressed: () => _finishSession(),
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required final IconData icon,
    required final String label,
    required final VoidCallback onPressed,
    required final LinearGradient gradient,
    required final Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
        boxShadow: RecordingDesignSystem.shadowMedium,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: RecordingDesignSystem.labelMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required final IconData icon,
    required final String label,
    required final VoidCallback onPressed,
    required final bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary ? RecordingDesignSystem.primaryGradient : RecordingDesignSystem.neutralGradient,
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
        boxShadow: isPrimary ? RecordingDesignSystem.medicalShadow : RecordingDesignSystem.shadowMedium,
        border: isPrimary ? null : Border.all(
          color: RecordingDesignSystem.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RecordingDesignSystem.spacingM,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : RecordingDesignSystem.getTextPrimaryColor(context),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: RecordingDesignSystem.labelMedium.copyWith(
                      color: isPrimary ? Colors.white : RecordingDesignSystem.getTextPrimaryColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _completeCooldown(final StretchingNotifier notifier) {
    notifier.completeRoutine();
    // Show completion confirmation dialog
    _showCooldownCompletionDialog();
  }

  void _showReadinessDialog(BuildContext context, WidgetRef ref) {
    final stretchingState = ref.read(stretchingProvider);
    final stretchingNotifier = ref.read(stretchingProvider.notifier);
    final currentExercise = stretchingNotifier.currentExercise;
    
    if (currentExercise == null || stretchingState.isReadyConfirmed) {
      return; // Don't show if no exercise or already confirmed
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              RecordingDesignSystem.iconCooldown,
              color: RecordingDesignSystem.primaryMedical,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ready to Start Cooldown?',
                style: RecordingDesignSystem.headlineMedium.copyWith(
                  color: RecordingDesignSystem.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please review the exercise instructions, steps, benefits, and precautions below. When you\'re ready and understand what to do, click "I\'m Ready" to start the timer.',
                style: RecordingDesignSystem.bodyMedium.copyWith(
                  color: RecordingDesignSystem.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 16),
              if (currentExercise.description.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: RecordingDesignSystem.labelLarge.copyWith(
                        color: RecordingDesignSystem.getTextPrimaryColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentExercise.description,
                      style: RecordingDesignSystem.bodyMedium.copyWith(
                        color: RecordingDesignSystem.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              if (currentExercise.stepByStepInstructions.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Steps',
                      style: RecordingDesignSystem.labelLarge.copyWith(
                        color: RecordingDesignSystem.getTextPrimaryColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...currentExercise.stepByStepInstructions.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: RecordingDesignSystem.primaryMedical,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: RecordingDesignSystem.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: RecordingDesignSystem.bodyMedium.copyWith(
                                  color: RecordingDesignSystem.getTextSecondaryColor(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                ),
              if (currentExercise.benefits.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RecordingDesignSystem.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            RecordingDesignSystem.iconCheck,
                            color: RecordingDesignSystem.successColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Benefits',
                            style: RecordingDesignSystem.labelMedium.copyWith(
                              color: RecordingDesignSystem.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...currentExercise.benefits.map((benefit) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: RecordingDesignSystem.successColor)),
                            Expanded(
                              child: Text(
                                benefit,
                                style: RecordingDesignSystem.bodySmall.copyWith(
                                  color: RecordingDesignSystem.successColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              if (currentExercise.precautions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RecordingDesignSystem.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            RecordingDesignSystem.iconWarning,
                            color: RecordingDesignSystem.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Precautions',
                            style: RecordingDesignSystem.labelMedium.copyWith(
                              color: RecordingDesignSystem.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...currentExercise.precautions.map((precaution) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: RecordingDesignSystem.errorColor)),
                            Expanded(
                              child: Text(
                                precaution,
                                style: RecordingDesignSystem.bodySmall.copyWith(
                                  color: RecordingDesignSystem.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Review Instructions',
              style: RecordingDesignSystem.labelMedium.copyWith(
                color: RecordingDesignSystem.getTextSecondaryColor(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(stretchingProvider.notifier).confirmReadiness();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RecordingDesignSystem.primaryMedical,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'I\'m Ready',
              style: RecordingDesignSystem.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCooldownCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              RecordingDesignSystem.iconComplete,
              color: RecordingDesignSystem.successColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cooldown Complete!',
                style: RecordingDesignSystem.headlineMedium.copyWith(
                  color: RecordingDesignSystem.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'You\'ve completed all cooldown exercises. Ready to finish and save your session?',
          style: RecordingDesignSystem.bodyMedium.copyWith(
            color: RecordingDesignSystem.getTextSecondaryColor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Review Cooldown',
              style: RecordingDesignSystem.labelMedium.copyWith(
                color: RecordingDesignSystem.getTextSecondaryColor(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RecordingDesignSystem.primaryMedical,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Finish Session',
              style: RecordingDesignSystem.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _skipCooldown() {
    _finishSession();
  }

  void _finishSession() {
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
