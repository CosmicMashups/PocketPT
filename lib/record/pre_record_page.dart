import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import '../data/rehabilitation_plan.dart';
import 'record_exercise.dart';
import 'stopwatch_service.dart';
import '../widgets/data_loading_wrapper.dart';
import '../widgets/loading_indicator.dart';
class PreRecordPage extends StatefulWidget {
  const PreRecordPage({super.key});

  @override
  State<PreRecordPage> createState() => _PreRecordPageState();
}

class _PreRecordPageState extends State<PreRecordPage> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isInitializingCamera = false;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    // Delay camera initialization to improve page load time
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _initializeCamera();
      }
    });
  }

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera || _isCameraInitialized) return;
    
    setState(() {
      _isInitializingCamera = true;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.medium); // Use medium instead of high
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Camera Preview with subtle frame

              // Camera Preview with Gradient
              _isCameraInitialized && _controller != null
                  ? Container(
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
                        child: SizedBox(
                          height: screenHeight * 0.38,
                          width: double.infinity,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    )
                  : _isInitializingCamera
                      ? const Center(
                          child: LoadingIndicator(
                            message: 'Initializing camera...',
                            size: 40,
                          ),
                        )
                      : Container(
                          height: screenHeight * 0.38,
                          decoration: BoxDecoration(
                            color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                          ),
                          child: Center(
                            child: Text(
                              'Camera not available',
                              style: GoogleFonts.ptSans(color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                            ),
                          ),
                        ),
              const SizedBox(height: 24),

              // Exercise Name & Thumbnail
              FutureBuilder<Exercise?>(
                future: rehabPlan?.exerciseReferences.isNotEmpty == true 
                    ? ExerciseDataService.getExerciseById(rehabPlan!.exerciseReferences.first.exerciseId)
                    : Future.value(null),
                builder: (context, snapshot) {
                  final currentExercise = snapshot.data;
                  return Row(
                    children: [
                      Expanded(
                        child: Flexible(
                          child: Text(
                            currentExercise?.exerciseName ?? 'No Exercise',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: const Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
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
                              ? ExerciseDataService.getExerciseById(rehabPlan!.exerciseReferences.first.exerciseId)
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

              // Start Recording Button
              Center(
                child: Container(
                  width: double.infinity,
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
                    label: Text(
                      'Start Recording',
                      style: GoogleFonts.ptSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () async {
                    if (rehabPlan?.exerciseReferences.isEmpty != false) return;
                    
                    final currentExercise = await ExerciseDataService.getExerciseById(
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
              ),
            ],
          ),
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