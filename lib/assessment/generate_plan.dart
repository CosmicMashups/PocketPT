import 'package:flutter/material.dart';
import '../data/rehabilitation_plan.dart';
import '../main.dart';
import '../data/treatment.dart';
import 'generate_treatment.dart';
import '../data/globals.dart';

class GeneratePlanPage extends StatefulWidget {
  const GeneratePlanPage({super.key});

  @override
  State<GeneratePlanPage> createState() => _GeneratePlanPageState();
}

class _GeneratePlanPageState extends State<GeneratePlanPage> {
  bool _isLoading = true;
  RehabilitationPlan? _rehabPlan;
  List<Treatment>? _treatments;
  String? _error;
  // bool _showExerciseWarning = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      // Set the treatment parameters based on user assessment
      UserRehabilitation.instance.selectedMuscle = UserAssess.specificMuscle;
      UserRehabilitation.instance.selectedPainLevel = UserAssess.painLevel;
      UserRehabilitation.instance.selectedPainDuration = UserAssess.painDuration;

      final selectedPainLevel = UserRehabilitation.instance.selectedPainLevel;
      final selectedPainDuration = UserRehabilitation.instance.selectedPainDuration;

      RehabilitationPlan? plan;

      // Only generate plan if condition is not met
      if (selectedPainLevel != "Severe" || selectedPainDuration != "Less than 48 hours ago") {
        plan = await generateRehabilitationPlanFromCSV();
      }
      
      final treatments = await generateTreatmentPlan(
        specificMuscle: UserRehabilitation.instance.selectedMuscle,
        painLevel: UserRehabilitation.instance.selectedPainLevel,
        painDuration: UserRehabilitation.instance.selectedPainDuration,
      );
      
      // Determine whether to show warning
      final shouldShowExerciseWarning = selectedPainLevel == "Severe" || selectedPainDuration == "Less than 48 hours ago";

      if (shouldShowExerciseWarning) {
        setState(() {
          _treatments = treatments;
          _rehabPlan = null;
          _isLoading = false;
        });
      } else if (plan == null && (treatments == null || treatments.isEmpty)) {
        setState(() {
          _error = "⚠️ Not enough matching exercises or treatments found.";
          _rehabPlan = null;
          _treatments = null;
          _isLoading = false;
        });
      } else {
        UserRehabilitation.instance.rehabPlans = plan != null ? [plan] : [];
        setState(() {
          _rehabPlan = plan;
          _treatments = treatments;
          _error = null;
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
            '🗓 Week ${_rehabPlan?.weekNumber ?? 1}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E5A88),
            ),
          ),
          const SizedBox(height: 16),
          
          // Treatments Section
          if (_treatments != null && _treatments!.isNotEmpty) ...[
            const Text(
              '💊 Recommended Treatments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E5A88),
              ),
            ),
            const SizedBox(height: 10),
            ..._treatments!.map((t) => _buildTreatmentCard(t)),
            const SizedBox(height: 20),
          ],
          
          // Exercises Section
          if (_rehabPlan != null && _rehabPlan!.exercises.isNotEmpty) ...[
            const Text(
              '🏋️‍♂️ Recommended Exercises',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E5A88),
              ),
            ),
            const SizedBox(height: 10),
            ..._rehabPlan!.exercises.map((e) => _buildExerciseCard(e)),
          ],
          
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

  Widget _buildTreatmentCard(Treatment treatment) {
    return Card(
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
                const Icon(Icons.medical_services, size: 28, color: Color(0xFF800020)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    treatment.treatmentName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(treatment.description),
            const Divider(height: 24),
            _buildDetailRow(Icons.assignment, 'ID: ${treatment.treatmentId}'),
            _buildDetailRow(Icons.accessibility_new, 'Muscles: ${treatment.musclesInvolved}'),
            _buildDetailRow(Icons.health_and_safety, 'Pain Level: ${treatment.painLevel}'),
            _buildDetailRow(Icons.timer, 'Pain Duration: ${treatment.painDuration}'),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Card(
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
                    exercise.exerciseName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(exercise.description),
            const Divider(height: 24),
            _buildDetailRow(Icons.fitness_center, '${exercise.sets} sets of ${exercise.repetitions} reps'),
            _buildDetailRow(Icons.tag, 'ID: ${exercise.exerciseId}'),
            _buildDetailRow(Icons.accessibility_new, 'Muscle: ${exercise.muscle}'),
            _buildDetailRow(Icons.favorite, 'Pain Level: ${exercise.painLevel}'),
            _buildDetailRow(Icons.flag, 'Goal: ${exercise.goal}'),
            if (exercise.videoUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.ondemand_video, size: 20, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Video Guide: ${exercise.videoUrl}',
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