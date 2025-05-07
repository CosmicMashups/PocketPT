import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import '../data/rehabilitation_plan.dart';
import 'record_exercise.dart';
import 'stopwatch_service.dart';

class PreRecordPage extends StatefulWidget {
  const PreRecordPage({super.key});

  @override
  State<PreRecordPage> createState() => _PreRecordPageState();
}

class _PreRecordPageState extends State<PreRecordPage> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  late List<CameraDescription> cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    final currentExercise = rehabPlan?.exercises.isNotEmpty == true ? rehabPlan!.exercises.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFF161719),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                children: [
                  Icon(Icons.arrow_back_ios, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Exercise: Preparation',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Camera Preview with Gradient
              _isCameraInitialized
                  ? Stack(
                      children: [
                        Center(
                          child: Container(
                            height: screenHeight * 0.4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              // overflow: Overflow.visible,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CameraPreview(_controller),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 24),

              // Exercise Name & Thumbnail
              Row(
                children: [
                  Expanded(
                    child: Text(
                      currentExercise?.exerciseName ?? 'No Exercise',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Exercise Info Cards
              Row(
                children: [
                  _infoCard(
                    title: 'Ex\nNo.',
                    icon: Icons.tag,
                    value: '1',
                    bgColor: const Color(0xFF282C2D),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _infoTile(
                          icon: Icons.fitness_center,
                          title: 'Repetitions',
                          subtitle: currentExercise != null
                              ? '${currentExercise.sets} sets of ${currentExercise.repetitions}'
                              : 'Not available',
                        ),
                        const SizedBox(height: 12),
                        _infoTile(
                          icon: Icons.accessibility_new,
                          title: 'Focus Area',
                          subtitle: currentExercise?.muscle ?? 'No muscle',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Start Recording Button
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  label: Text(
                    'Start Recording',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
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
                    backgroundColor: const Color(0xFF800020),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 6,
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
      width: 90,
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF282C2D),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC1574F), size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: GoogleFonts.ptSans(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}