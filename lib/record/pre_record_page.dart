import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/rehabilitation_plan.dart';
import '../assessment/assessment_data.dart';
import 'record_exercise.dart';
import 'warmup_stretching_page.dart';
import 'stopwatch_service.dart';
import 'camera_service.dart';
import 'exercise_cache_service.dart';
import '../widgets/data_loading_wrapper.dart';
import 'design_system.dart';
class PreRecordPage extends StatefulWidget {
  const PreRecordPage({super.key});

  @override
  State<PreRecordPage> createState() => _PreRecordPageState();
}

class _PreRecordPageState extends State<PreRecordPage> {
  final CameraService _cameraService = CameraService.instance;
  final ExerciseCacheService _cacheService = ExerciseCacheService.instance;
  bool _isCameraInitialized = false;
  bool _isInitializingCamera = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    // Initialize camera service
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera) return;
    
    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
    });

    try {
      final success = await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = success;
          _isInitializingCamera = false;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _cameraError = e.toString();
          _isCameraInitialized = false;
          _isInitializingCamera = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Don't dispose camera service here as it's shared across pages
    // Only dispose when exiting the entire recording workflow
    super.dispose();
  }

  Widget _buildCameraPreview(bool isDark) {
    if (_isCameraInitialized && _cameraService.isReady) {
      final cameraPreview = _cameraService.getEnhancedCameraPreview(context);
      if (cameraPreview != null) {
        return Semantics(
          label: 'Camera preview for exercise preparation',
          hint: 'Double tap to focus camera',
          child: cameraPreview,
        );
      }
    }

    if (_isInitializingCamera) {
      return _cameraService.getLoadingIndicator(context);
    }

    return _cameraService.getErrorState(
      context,
      _cameraError ?? 'Camera not available',
      _cameraError != null ? _initializeCamera : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rehabPlans = UserRehabilitation.instance.rehabPlans;
    final rehabPlan = rehabPlans.isNotEmpty ? rehabPlans.first : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RehabDataLoadingWrapper(
      child: Scaffold(
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
        centerTitle: true,
        title: Text(
          'Exercise Preparation',
          style: RecordingDesignSystem.headlineMedium.copyWith(
            color: RecordingDesignSystem.getTextPrimaryColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Camera Preview with proper 9:16 aspect ratio and responsive sizing
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate available width considering padding (16px on each side)
                        final availableWidth = constraints.maxWidth - 32; // 16px padding on each side
                        
                        // Calculate height based on 9:16 aspect ratio
                        final cameraHeight = availableWidth * (16 / 9);
                        
                        // Apply maximum height constraint (40% of screen height)
                        final maxHeight = MediaQuery.of(context).size.height * 0.4;
                        final finalHeight = cameraHeight > maxHeight ? maxHeight : cameraHeight;
                        
                        // Calculate final width to maintain aspect ratio if height was constrained
                        final finalWidth = finalHeight * (9 / 16);
                        
                        return Center(
                          child: Container(
                            width: finalWidth,
                            height: finalHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
                              boxShadow: RecordingDesignSystem.shadowLarge,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildCameraPreview(isDark),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Enhanced Exercise Name Card with decorative elements
                    FutureBuilder<Exercise?>(
                      future: rehabPlan?.exerciseReferences.isNotEmpty == true 
                          ? _cacheService.getExerciseById(rehabPlan!.exerciseReferences.first.exerciseId)
                          : Future.value(null),
                      builder: (context, snapshot) {
                        final currentExercise = snapshot.data;
                        return Container(
                          width: double.infinity,
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
                            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
                            border: Border.all(
                              color: RecordingDesignSystem.primaryMedical.withOpacity(0.2),
                              width: 2,
                            ),
                            boxShadow: RecordingDesignSystem.medicalShadow,
                          ),
                          child: Column(
                            children: [
                              // Decorative header with icon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(RecordingDesignSystem.spacingS),
                                    decoration: BoxDecoration(
                                      gradient: RecordingDesignSystem.primaryGradient,
                                      borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                                      boxShadow: RecordingDesignSystem.shadowMedium,
                                    ),
                                    child: Icon(
                                      RecordingDesignSystem.iconExercise,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: RecordingDesignSystem.spacingM),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: RecordingDesignSystem.spacingM,
                                      vertical: RecordingDesignSystem.spacingS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: RecordingDesignSystem.successColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusS),
                                      border: Border.all(
                                        color: RecordingDesignSystem.successColor.withOpacity(0.3),
                                        width: 1,
                                      ),
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
                                          'Ready',
                                          style: RecordingDesignSystem.labelMedium.copyWith(
                                            color: RecordingDesignSystem.successColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: RecordingDesignSystem.spacingM),
                              // Exercise name with enhanced styling
                              Text(
                                currentExercise?.exerciseName ?? 'No Exercise',
                                style: RecordingDesignSystem.headlineLarge.copyWith(
                                  color: RecordingDesignSystem.getTextPrimaryColor(context),
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: RecordingDesignSystem.spacingS),
                              // Exercise type indicator
                              if (currentExercise != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: RecordingDesignSystem.spacingM,
                                    vertical: RecordingDesignSystem.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: RecordingDesignSystem.accentBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusS),
                                  ),
                                  child: Text(
                                    'Exercise Type: ${currentExercise.goal}',
                                    style: RecordingDesignSystem.bodySmall.copyWith(
                                      color: RecordingDesignSystem.accentBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Enhanced Exercise Info Cards with decorative elements
                    Row(
                      children: [
                        _enhancedInfoCard(
                          title: 'Exercise',
                          icon: RecordingDesignSystem.iconExercise,
                          value: '1',
                          gradient: RecordingDesignSystem.primaryGradient,
                          accentColor: RecordingDesignSystem.primaryMedical,
                        ),
                        const SizedBox(width: RecordingDesignSystem.spacingM),
                        Expanded(
                          child: Column(
                            children: [
                              FutureBuilder<Exercise?>(
                                future: rehabPlan?.exerciseReferences.isNotEmpty == true 
                                    ? _cacheService.getExerciseById(rehabPlan!.exerciseReferences.first.exerciseId)
                                    : Future.value(null),
                                builder: (context, snapshot) {
                                  final currentExercise = snapshot.data;
                                  return Column(
                                    children: [
                                      _enhancedInfoTile(
                                        icon: RecordingDesignSystem.iconTimer,
                                        title: 'Repetitions',
                                        subtitle: currentExercise != null && rehabPlan != null
                                            ? '${rehabPlan.exerciseReferences.first.sets} sets of ${rehabPlan.exerciseReferences.first.repetitions}'
                                            : 'Not available',
                                        gradient: RecordingDesignSystem.successGradient,
                                        accentColor: RecordingDesignSystem.successColor,
                                      ),
                                      const SizedBox(height: RecordingDesignSystem.spacingM),
                                      _enhancedInfoTile(
                                        icon: RecordingDesignSystem.iconProgress,
                                        title: 'Focus Area',
                                        subtitle: currentExercise?.muscle ?? 'No muscle',
                                        gradient: RecordingDesignSystem.infoGradient,
                                        accentColor: RecordingDesignSystem.infoColor,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Enhanced Start Recording Button with decorative elements
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 64),
                      decoration: BoxDecoration(
                        gradient: RecordingDesignSystem.primaryGradient,
                        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
                        boxShadow: RecordingDesignSystem.medicalShadowLarge,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
                          onTap: () async {
                            if (rehabPlan?.exerciseReferences.isEmpty != false) return;
                            
                            final currentExercise = await _cacheService.getExerciseById(
                              rehabPlan!.exerciseReferences.first.exerciseId
                            );
                            if (currentExercise == null) return;
                            
                            // Get muscle group from assessment data
                            final muscleGroup = AssessmentData.specificMuscle.isNotEmpty 
                                ? AssessmentData.specificMuscle 
                                : 'General';
                            
                            // Show warm-up option dialog
                            _showWarmupOption(context, muscleGroup, currentExercise);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: RecordingDesignSystem.spacingXL,
                              vertical: RecordingDesignSystem.spacingL,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(RecordingDesignSystem.spacingS),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                                      ),
                                      child: Icon(
                                        RecordingDesignSystem.iconCamera,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: RecordingDesignSystem.spacingM),
                                    Flexible(
                                      child: Text(
                                        'Start Recording',
                                        style: RecordingDesignSystem.headlineMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: RecordingDesignSystem.spacingS),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: RecordingDesignSystem.spacingM,
                                    vertical: RecordingDesignSystem.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusS),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        RecordingDesignSystem.iconTimer,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      const SizedBox(width: RecordingDesignSystem.spacingXS),
                                      Text(
                                        'Tap to begin your exercise session',
                                        style: RecordingDesignSystem.bodySmall.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    ),
    );
  }

  Widget _enhancedInfoCard({
    required String title,
    required IconData icon,
    required String value,
    required LinearGradient gradient,
    required Color accentColor,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 100,
        maxWidth: 120,
        minHeight: 140,
        maxHeight: 160,
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
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: RecordingDesignSystem.shadowLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(RecordingDesignSystem.spacingM),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
              boxShadow: RecordingDesignSystem.medicalShadow,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingS),
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: RecordingDesignSystem.bodySmall.copyWith(
                color: RecordingDesignSystem.getTextSecondaryColor(context),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingXS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RecordingDesignSystem.spacingS,
              vertical: RecordingDesignSystem.spacingXS,
            ),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusS),
            ),
            child: Text(
              value,
              style: RecordingDesignSystem.titleLarge.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _enhancedInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required Color accentColor,
  }) {
    return Container(
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
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: RecordingDesignSystem.shadowLarge,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(RecordingDesignSystem.spacingM),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
              boxShadow: RecordingDesignSystem.medicalShadow,
            ),
            child: Icon(
              icon,
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
                        title,
                        style: RecordingDesignSystem.titleMedium.copyWith(
                          color: RecordingDesignSystem.getTextPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RecordingDesignSystem.spacingS,
                        vertical: RecordingDesignSystem.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusS),
                      ),
                      child: Icon(
                        RecordingDesignSystem.iconInfo,
                        color: accentColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RecordingDesignSystem.spacingXS),
                Text(
                  subtitle,
                  style: RecordingDesignSystem.bodyMedium.copyWith(
                    color: RecordingDesignSystem.getTextSecondaryColor(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWarmupOption(BuildContext context, String muscleGroup, Exercise firstExercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Ready to Start?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8B2E2E),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We recommend a warm-up stretching routine to prepare your $muscleGroup muscles before exercising.',
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
                    Icon(Icons.fitness_center, color: const Color(0xFF8B2E2E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warm-up helps prevent injury and improves performance',
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
                _startRecordingDirectly(firstExercise);
              },
              child: Text(
                'Skip Warm-up',
                style: TextStyle(color: const Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startWithWarmup(muscleGroup, firstExercise);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2E2E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Warm-up'),
            ),
          ],
        );
      },
    );
  }

  void _startWithWarmup(String muscleGroup, Exercise firstExercise) {
    StopwatchService.instance.start();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            WarmupStretchingPage(
              muscleGroup: muscleGroup,
              firstExercise: firstExercise,
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

  void _startRecordingDirectly(Exercise firstExercise) {
    StopwatchService.instance.start();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RecordExercisePage(exercise: firstExercise),
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