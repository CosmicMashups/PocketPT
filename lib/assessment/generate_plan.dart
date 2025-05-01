import 'package:flutter/material.dart';
import '../data/rehabilitation_plan.dart';
import '../main.dart';

class GeneratePlanPage extends StatefulWidget {
  const GeneratePlanPage({super.key});

  @override
  State<GeneratePlanPage> createState() => _GeneratePlanPageState();
}

class _GeneratePlanPageState extends State<GeneratePlanPage> {
  bool _isLoading = true;
  RehabilitationPlan? _rehabPlan;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final plan = await generateRehabilitationPlanFromCSV();
      if (plan == null) {
        setState(() {
          _isLoading = false;
          _error = "⚠️ Not enough matching exercises found.";
        });
      } else {
        UserRehabilitation.instance.rehabPlans = [plan];
        setState(() {
          _rehabPlan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "❌ An error occurred: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          'Your Personalized Plan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 3,
        backgroundColor: const Color(0xFF800020),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Generating your plan...", style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildPlanUI(),
    );
  }

  Widget _buildPlanUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🗓 Week ${_rehabPlan!.weekNumber}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E5A88),
            ),
          ),
          const SizedBox(height: 16),
          ..._rehabPlan!.exercises.map((e) => Card(
                color: Colors.white,
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_gymnastics, size: 28, color: Color(0xFF800020)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.exerciseName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(e.description),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.fitness_center, '${e.sets} sets of ${e.repetitions} reps'),
                      _buildDetailRow(Icons.tag, 'ID: ${e.exerciseId}'),
                      _buildDetailRow(Icons.accessibility_new, 'Muscle: ${e.muscle}'),
                      _buildDetailRow(Icons.favorite, 'Pain Level: ${e.painLevel}'),
                      _buildDetailRow(Icons.flag, 'Goal: ${e.goal}'),

                      // Optional image
                      // if (e.imageUrl.isNotEmpty)
                      //   Padding(
                      //     padding: const EdgeInsets.only(top: 16),
                      //     child: ClipRRect(
                      //       borderRadius: BorderRadius.circular(12),
                      //       child: Image.asset(
                      //         'assets/images/exercise/${e.imageUrl}',
                      //         height: 160,
                      //         fit: BoxFit.cover,
                      //         errorBuilder: (context, error, stackTrace) =>
                      //             const Text('❌ Could not load image.'),
                      //       ),
                      //     ),
                      //   ),

                      // Optional video URL text
                      if (e.videoUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.ondemand_video, size: 20, color: Colors.blue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Video Guide: ${e.videoUrl}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF800020),
                shadowColor: Colors.black45,
                elevation: 6,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text(
                'Back to Home',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF557A95)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}