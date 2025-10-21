import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/rehabilitation_plan.dart';
import 'record_exercise.dart';
import 'stopwatch_service.dart';
import 'camera_service.dart';
import 'exercise_cache_service.dart';
import '../widgets/data_loading_wrapper.dart';
import '../widgets/loading_indicator.dart';
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
      final cameraPreview = _cameraService.getCameraPreview();
      if (cameraPreview != null) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: _cameraService.controller!.value.aspectRatio,
              child: cameraPreview,
            ),
          ),
        );
      }
    }

    if (_isInitializingCamera) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: LoadingIndicator(
            message: 'Initializing camera...',
            size: 40,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 16),
            Text(
              _cameraError ?? 'Camera not available',
              style: GoogleFonts.ptSans(
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (_cameraError != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2E2E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            currentExercise?.exerciseName ?? 'No Exercise',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: const Color(0xFF1F2937),
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

                    // Start Recording Button with responsive layout
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 56),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B2E2E), Color(0xFFC24A4A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B2E2E).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.videocam, color: Colors.white),
                        label: Flexible(
                          child: Text(
                            'Start Recording',
                            style: GoogleFonts.ptSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        onPressed: () async {
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
                                const curve = Curves.easeInOut;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                return SlideTransition(position: animation.drive(tween), child: child);
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 110,
      height: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B2E2E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tag, color: Color(0xFF8B2E2E), size: 22),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.ptSans(color: const Color(0xFF6B7280), fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(color: const Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFC24A4A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fitness_center, color: Color(0xFFC24A4A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(color: const Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.ptSans(color: const Color(0xFF6B7280), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}