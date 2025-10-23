import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stretching/providers/stretching_provider.dart';
import '../stretching/widgets/exercise_instruction_widget.dart';
import '../stretching/widgets/routine_progress_widget.dart';
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
      // Get pain scale from assessment data
      final painScale = UserAssess.painScale;
      print('CooldownStretchingPage: Loading routines for ${widget.muscleGroup} with pain level $painScale');
      
      try {
        await ref.read(stretchingProvider.notifier).loadRoutinesForMuscleWithPainLevel(
          widget.muscleGroup, painScale);
        
        // If no routines were loaded, try without pain level filtering
        final stretchingState = ref.read(stretchingProvider);
        if (stretchingState.currentCooldownRoutine == null) {
          print('CooldownStretchingPage: No cooldown routine found with pain level, trying without pain filtering');
          await ref.read(stretchingProvider.notifier).loadRoutinesForMuscle(widget.muscleGroup);
        }
      } catch (e) {
        print('CooldownStretchingPage: Error loading routines: $e');
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
            return _buildLoadingState();
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Column(
                  children: [
                    // Enhanced Header Section
                    _buildEnhancedHeaderSection(),
                    
                    const SizedBox(height: RecordingDesignSystem.spacingL),
                    
                    // Progress Section with enhanced design
                    _buildEnhancedProgressSection(stretchingState, stretchingNotifier),
                    
                    const SizedBox(height: RecordingDesignSystem.spacingL),
                    
                    // Exercise Instruction with enhanced styling
                    Expanded(
                      child: stretchingNotifier.currentExercise != null
                          ? _buildEnhancedExerciseInstruction(stretchingState, stretchingNotifier)
                          : _buildRoutineComplete(),
                    ),
                    
                    // Enhanced Control Buttons
                    _buildEnhancedControlButtons(stretchingState, stretchingNotifier),
                  ],
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

  Widget _buildEnhancedHeaderSection() {
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
                  gradient: RecordingDesignSystem.accentGradient,
                  borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
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
                    Text(
                      "Recovery & Relaxation",
                      style: RecordingDesignSystem.headlineMedium.copyWith(
                        color: RecordingDesignSystem.getTextPrimaryColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: RecordingDesignSystem.spacingXS),
                    Text(
                      "Cooldown stretching for ${widget.muscleGroup}",
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
                  RecordingDesignSystem.iconSuccess,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: RecordingDesignSystem.spacingS),
                Expanded(
                  child: Text(
                    'Great work! Cooldown helps reduce muscle soreness and promotes recovery',
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

  Widget _buildEnhancedProgressSection(final StretchingState state, final StretchingNotifier notifier) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: RecordingDesignSystem.spacingM),
      padding: const EdgeInsets.all(RecordingDesignSystem.spacingL),
      decoration: BoxDecoration(
        color: RecordingDesignSystem.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusXL),
        border: Border.all(
          color: RecordingDesignSystem.getBorderColor(context),
          width: 1,
        ),
        boxShadow: RecordingDesignSystem.shadowLarge,
      ),
      child: RoutineProgressWidget(
        currentExercise: state.currentExerciseIndex,
        totalExercises: state.currentCooldownRoutine?.exercises.length ?? 0,
        remainingTime: state.remainingTime,
        currentExerciseName: notifier.currentExercise?.exerciseName ?? '',
        progressPercentage: notifier.progressPercentage,
      ),
    );
  }

  Widget _buildEnhancedExerciseInstruction(final StretchingState state, final StretchingNotifier notifier) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: RecordingDesignSystem.spacingM),
      decoration: BoxDecoration(
        color: RecordingDesignSystem.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusXL),
        border: Border.all(
          color: RecordingDesignSystem.getBorderColor(context),
          width: 1,
        ),
        boxShadow: RecordingDesignSystem.shadowLarge,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusXL),
        child: ExerciseInstructionWidget(
          exercise: notifier.currentExercise!,
          isActive: state.isRoutineActive,
          remainingTime: state.remainingTime,
          onNext: () => notifier.nextExercise(),
          onPrevious: () => notifier.previousExercise(),
          onComplete: () => _completeCooldown(notifier),
        ),
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
      padding: const EdgeInsets.all(RecordingDesignSystem.spacingL),
      decoration: BoxDecoration(
        color: RecordingDesignSystem.getSurfaceColor(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(RecordingDesignSystem.radiusXL),
          topRight: Radius.circular(RecordingDesignSystem.radiusXL),
        ),
        border: Border.all(
          color: RecordingDesignSystem.getBorderColor(context),
          width: 1,
        ),
        boxShadow: RecordingDesignSystem.shadowLarge,
      ),
      child: Column(
        children: [
          // Primary control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
          
          const SizedBox(height: RecordingDesignSystem.spacingL),
          
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
              const SizedBox(width: RecordingDesignSystem.spacingM),
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
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
        boxShadow: RecordingDesignSystem.shadowMedium,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RecordingDesignSystem.spacingM,
              vertical: RecordingDesignSystem.spacingM,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: RecordingDesignSystem.spacingS),
                Text(
                  label,
                  style: RecordingDesignSystem.labelMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
        boxShadow: isPrimary ? RecordingDesignSystem.medicalShadow : RecordingDesignSystem.shadowMedium,
        border: isPrimary ? null : Border.all(
          color: RecordingDesignSystem.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RecordingDesignSystem.spacingL,
              vertical: RecordingDesignSystem.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : RecordingDesignSystem.getTextPrimaryColor(context),
                  size: 20,
                ),
                const SizedBox(width: RecordingDesignSystem.spacingS),
                Text(
                  label,
                  style: RecordingDesignSystem.labelLarge.copyWith(
                    color: isPrimary ? Colors.white : RecordingDesignSystem.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w600,
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
