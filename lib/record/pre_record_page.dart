import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/rehabilitation_plan.dart';
import 'record_exercise.dart';
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
          'Exercise Preparation',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF1F2937),
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
                    // Camera Preview with responsive layout
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: _buildCameraPreview(isDark),
                    ),
                    const SizedBox(height: 24),

                    // Exercise Name with proper text wrapping
                    FutureBuilder<Exercise?>(
                      future: rehabPlan?.exerciseReferences.isNotEmpty == true 
                          ? _cacheService.getExerciseById(rehabPlan!.exerciseReferences.first.exerciseId)
                          : Future.value(null),
                      builder: (context, snapshot) {
                        final currentExercise = snapshot.data;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: RecordingDesignSystem.spacingM,
                            vertical: RecordingDesignSystem.spacingM,
                          ),
                          decoration: BoxDecoration(
                            color: RecordingDesignSystem.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                            border: Border.all(
                              color: RecordingDesignSystem.getBorderColor(context),
                              width: 1,
                            ),
                            boxShadow: RecordingDesignSystem.shadowSmall,
                          ),
                          child: Text(
                            currentExercise?.exerciseName ?? 'No Exercise',
                            style: RecordingDesignSystem.headlineLarge.copyWith(
                              color: RecordingDesignSystem.getTextPrimaryColor(context),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Exercise Info Cards
                    Row(
                      children: [
                        _infoCard(
                          title: 'Exercise',
                          icon: Icons.tag,
                          value: '1',
                          bgColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                        ),
                        const SizedBox(width: 16),
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
                                      _infoTile(
                                        icon: Icons.fitness_center,
                                        title: 'Repetitions',
                                        subtitle: currentExercise != null && rehabPlan != null
                                            ? '${rehabPlan.exerciseReferences.first.sets} sets of ${rehabPlan.exerciseReferences.first.repetitions}'
                                            : 'Not available',
                                      ),
                                      const SizedBox(height: 12),
                                      _infoTile(
                                        icon: Icons.accessibility_new,
                                        title: 'Focus Area',
                                        subtitle: currentExercise?.muscle ?? 'No muscle',
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

                    // Enhanced Start Recording Button
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 56),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            RecordingDesignSystem.primaryMedical,
                            RecordingDesignSystem.secondaryMedical,
                          ],
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
                          onTap: () async {
                            if (rehabPlan?.exerciseReferences.isEmpty != false) return;
                            
                            final currentExercise = await _cacheService.getExerciseById(
                              rehabPlan!.exerciseReferences.first.exerciseId
                            );
                            if (currentExercise == null) return;
                            
                            StopwatchService.instance.start();
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    RecordExercisePage(exercise: currentExercise),
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
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: RecordingDesignSystem.spacingXL,
                              vertical: RecordingDesignSystem.spacingM,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam, color: Colors.white, size: 24),
                                const SizedBox(width: RecordingDesignSystem.spacingS),
                                Flexible(
                                  child: Text(
                                    'Start Recording',
                                    style: RecordingDesignSystem.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
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

  Widget _infoCard({
    required String title,
    required IconData icon,
    required String value,
    Color bgColor = Colors.grey,
  }) {
    return Container(
      width: 110,
      height: 130,
      padding: const EdgeInsets.all(RecordingDesignSystem.spacingM),
      decoration: BoxDecoration(
        color: RecordingDesignSystem.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
        border: Border.all(
          color: RecordingDesignSystem.getBorderColor(context),
          width: 1,
        ),
        boxShadow: RecordingDesignSystem.shadowMedium,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(RecordingDesignSystem.spacingS),
            decoration: BoxDecoration(
              color: RecordingDesignSystem.primaryMedical.withOpacity(0.08),
              borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
            ),
            child: Icon(
              icon,
              color: RecordingDesignSystem.primaryMedical,
              size: 22,
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingS),
          Text(
            title,
            textAlign: TextAlign.center,
            style: RecordingDesignSystem.bodySmall.copyWith(
              color: RecordingDesignSystem.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: RecordingDesignSystem.spacingXS),
          Text(
            value,
            style: RecordingDesignSystem.headlineLarge.copyWith(
              color: RecordingDesignSystem.getTextPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(RecordingDesignSystem.spacingM),
      decoration: BoxDecoration(
        color: RecordingDesignSystem.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusL),
        border: Border.all(
          color: RecordingDesignSystem.getBorderColor(context),
          width: 1,
        ),
        boxShadow: RecordingDesignSystem.shadowMedium,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(RecordingDesignSystem.spacingS),
            decoration: BoxDecoration(
              color: RecordingDesignSystem.secondaryMedical.withOpacity(0.1),
              borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusS),
            ),
            child: Icon(
              icon,
              color: RecordingDesignSystem.secondaryMedical,
              size: 22,
            ),
          ),
          const SizedBox(width: RecordingDesignSystem.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: RecordingDesignSystem.titleMedium.copyWith(
                    color: RecordingDesignSystem.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: RecordingDesignSystem.spacingXS),
                Text(
                  subtitle,
                  style: RecordingDesignSystem.bodyMedium.copyWith(
                    color: RecordingDesignSystem.getTextSecondaryColor(context),
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