import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:pocketpt/data/globals.dart';
import 'package:pocketpt/home_dialog.dart';
import '../data/rehabilitation_plan.dart';
import 'pre_record_page.dart';
import 'stopwatch_service.dart';

class RecordExercisePage extends StatefulWidget {
  final Exercise exercise;

  const RecordExercisePage({required this.exercise, super.key});

  @override
  State<RecordExercisePage> createState() => _RecordExercisePageState();
}

class _RecordExercisePageState extends State<RecordExercisePage> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  late List<CameraDescription> cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    StopwatchService.instance.start();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.high);
      await _controller.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final rehabPlans = UserRehabilitation.instance.rehabPlans;
    final rehabPlan = rehabPlans.isNotEmpty ? rehabPlans.first : null;
    final exercises = rehabPlan?.exercises ?? [];
    final currentIndex = exercises.indexOf(widget.exercise);
    final currentExercise = widget.exercise;
    final imagePath = currentExercise.imageUrl;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1012),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF800020), Color(0xFF400010)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentExercise.exerciseName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Camera Preview
                _isCameraInitialized
                    ? SizedBox(
                        height: screenHeight * 0.55,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: CameraPreview(_controller),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 10),

                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1D1F),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF800020).withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
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
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCustomButton(
                      icon: Icons.arrow_back,
                      label: 'Back',
                      onTap: () {
                        final rehabPlans = UserRehabilitation.instance.rehabPlans;
                        final rehabPlan = rehabPlans.isNotEmpty ? rehabPlans.first : null;

                        if (rehabPlan != null && rehabPlan.exercises.isNotEmpty) {
                          final prevIndex = currentIndex - 1;
                          if (prevIndex >= 0) {
                            final prevExercise = rehabPlan.exercises[prevIndex];

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecordExercisePage(exercise: prevExercise),
                              ),
                            );
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
                      onTap: () {
                        StopwatchService.instance.pause();
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, _, __) => PreRecordPage(),
                            transitionsBuilder: (context, animation, __, child) {
                              final offsetAnimation = Tween(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation);
                              return SlideTransition(position: offsetAnimation, child: child);
                            },
                          ),
                        );
                      },
                    ),
                    _buildCustomButton(
                      icon: Icons.arrow_forward,
                      label: (currentIndex + 1) < exercises.length ? 'Proceed' : 'Finish',
                      onTap: () {
                        final rehabPlans = UserRehabilitation.instance.rehabPlans;
                        final rehabPlan = rehabPlans.isNotEmpty ? rehabPlans.first : null;

                        if (rehabPlan != null && rehabPlan.exercises.isNotEmpty) {
                          final nextIndex = currentIndex + 1;

                          if (nextIndex < rehabPlan.exercises.length) {
                            final nextExercise = rehabPlan.exercises[nextIndex];

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecordExercisePage(exercise: nextExercise),
                              ),
                            );
                          } else {
                            StopwatchService.instance.pause();

                            // Update records
                            UserProgress.streak += 1;
                            UserProgress.totalDays += 1;
                            UserProgress.totalExercises += currentIndex + 1;
                            UserProgress.totalSeconds += StopwatchService.instance.currentElapsed.inSeconds;
                            UserProgress.totalMinutes = (UserProgress.totalSeconds / 60).toInt();

                            StopwatchService.instance.reset();

                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) {
                                  return HomePageWithDialog();
                                },
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  var offsetAnimation = animation.drive(tween);

                                  return SlideTransition(position: offsetAnimation, child: child);
                                },
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
              decoration: const BoxDecoration(
                color: Color(0xFF1A1C1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF800020),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF800020),
      ),
      child: IconButton(
        icon: Icon(icon, size: 30, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildInstructionCard(String imagePath, Exercise exercise) {
    return Card(
      color: const Color(0xFF222426),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                height: 200,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.red, size: 100),
              ),
            ),
            const SizedBox(height: 16),
            Text(exercise.description,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}