import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'data/globals.dart';
import 'data/rehabilitation_plan.dart';


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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Row 1: Camera Preview
                _isCameraInitialized
                    ? SizedBox(
                        height: screenHeight * 0.4,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: CameraPreview(_controller),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),

                // Row 2: Text (rehabPlans.first)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currentExercise?.exerciseName ?? 'No Exercise',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900, // ExtraBold
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Row 3: Streak and Stats
                Row(
                  children: [
                    // Left Column (30%)
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          // backgroundColor: Colors(0xFF282C2D),
                        decoration: BoxDecoration(
                          color: const Color(0xFF282C2D),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Exercise\nNo.',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: const Color(0xFFF8F6F4),
                                      ),
                                    ),
                                  )
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1',
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF8F6F4),
                              ),
                            ),
                            const SizedBox(height: 4),                            
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Right Column (70%)
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          // Repetitions Card
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF282C2D),
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.fitness_center, size: 28, color: Color(0xFFC1574F)),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Repetitions',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: const Color(0xFFF8F6F4),
                                      ),
                                    ),
                                    Text(
                                      currentExercise != null ? '${currentExercise.sets} sets: ${currentExercise.repetitions} reps' : 'No set info',
                                      style: GoogleFonts.ptSans(
                                        fontSize: 14,
                                        color: const Color(0xFFF8F6F4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Time Spent Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF282C2D),
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 28, color: Color(0xFFC1574F)),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Focus Area',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: const Color(0xFFF8F6F4),
                                      ),
                                    ),
                                    Text(
                                      UserAssess.specificMuscle != '' ? UserAssess.specificMuscle : 'No muscle selected',
                                      // currentExercise != null ? '${currentExercise.sets} sets: ${currentExercise.repetitions} reps' : 'No set info',
                                      

                                      style: GoogleFonts.ptSans(
                                        fontSize: 14,
                                        color: const Color(0xFFF8F6F4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Row 4: ElevatedButton
                ElevatedButton(
                  onPressed: () {
                    // Start recording function here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800020),
                    padding: const EdgeInsets.symmetric(horizontal: 81, vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'START RECORDING',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
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
}