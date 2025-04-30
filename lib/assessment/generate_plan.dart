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
        // Update UserRehabilitation with new plan
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
      appBar: AppBar(
        title: const Text(
          'Your Personalized Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Color(0xFF800020),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF557A95),
            ),
          ),
          const SizedBox(height: 16),
          ..._rehabPlan!.exercises.map((e) => Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.exerciseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.fitness_center, size: 18, color: Color(0xFF557A95)),
                          const SizedBox(width: 6),
                          Text('${e.sets} sets of ${e.repetitions} reps'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.tag, size: 18, color: Color(0xFF557A95)),
                          const SizedBox(width: 6),
                          Text('ID: ${e.exerciseId}'),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text(
                'Back to Home',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}