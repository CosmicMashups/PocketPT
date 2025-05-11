import 'dart:math';
import 'package:flutter/material.dart';
import '../data/rehabilitation_plan.dart';
import '../data/treatment.dart';
import 'exercise_list.dart' as exList;
import '../assessment/generate_treatment.dart';
import '../data/globals.dart';

class ExerciseManagerPage extends StatefulWidget {
  const ExerciseManagerPage({super.key});

  @override
  State<ExerciseManagerPage> createState() => _ExerciseManagerPageState();
}

class _ExerciseManagerPageState extends State<ExerciseManagerPage> {
  final TextEditingController _notesController = TextEditingController();
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _notesController.text = UserProgress.notes ?? '';
  }
  
  // Updated color constants based on the provided theme
  static const backgroundColor = Color(0xFFF8F6F4);
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC1574F);
  static const detailColor = Color(0xFF6A5D7B);
  static const accentColor = Color(0xFFE8D8C4);

  void _saveNotes() {
    setState(() {
      UserProgress.notes = _notesController.text;
    });
  }

  Future<void> _replaceExercise(int index) async {
    final currentExercise = UserRehabilitation.instance.rehabPlans.first.exercises[index];

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Replace Exercise'),
          content: Text('Are you sure you want to replace "${currentExercise.exerciseName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: subColor,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );

    // If user cancels
    if (confirm != true) return;

    // Proceed with replacement
    try {
      final newExercise = await generateRandomExercise(
        muscle: currentExercise.muscle,
        painLevel: currentExercise.painLevel,
        painDuration: UserRehabilitation.instance.selectedPainDuration,
        goal: currentExercise.goal,
      );

      if (newExercise != null) {
        setState(() {
          final replacementExercise = Exercise(
            exerciseId: newExercise.exerciseId,
            exerciseName: newExercise.exerciseName,
            description: newExercise.description,
            muscle: newExercise.muscle,
            painLevel: newExercise.painLevel,
            goal: newExercise.goal,
            videoUrl: newExercise.videoUrl,
            imageUrl: newExercise.imageUrl,
            sets: currentExercise.sets,
            repetitions: currentExercise.repetitions,
          );
          UserRehabilitation.instance.rehabPlans.first.exercises[index] = replacementExercise;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Replaced with ${newExercise.exerciseName}'),
            backgroundColor: subColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ No suitable replacement found'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _addExercise() async {
    final newExercise = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const exList.ExercisesPage(selectingForAddition: true),
      ),
    );

    if (newExercise != null && newExercise is exList.Exercise) {
      final convertedExercise = Exercise(
        exerciseId: newExercise.id,
        exerciseName: newExercise.name,
        description: newExercise.description,
        muscle: newExercise.muscle,
        painLevel: newExercise.painLevel,
        goal: newExercise.goal,
        videoUrl: newExercise.videoUrl,
        imageUrl: newExercise.imageUrl,
        sets: newExercise.set,
        repetitions: newExercise.rep,
      );

      setState(() {
        UserRehabilitation.instance.rehabPlans.first.exercises.add(convertedExercise);
      });
    }
  }

  Future<void> _confirmDeleteExercise(int index) async {
    final exercise = UserRehabilitation.instance.rehabPlans.first.exercises[index];

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Exercise'),
          content: Text('Are you sure you want to delete "${exercise.exerciseName}" from your plan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        UserRehabilitation.instance.rehabPlans.first.exercises.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Deleted "${exercise.exerciseName}"'),
          backgroundColor: mainColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rehabPlan = UserRehabilitation.instance.rehabPlans.isNotEmpty
        ? UserRehabilitation.instance.rehabPlans.first
        : null;

    if (rehabPlan == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar("Exercise Manager"),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/empty_state.png', // Add your own asset
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 20),
              Text(
                "No rehabilitation plan available",
                style: TextStyle(
                  color: detailColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Create a new plan to get started",
                style: TextStyle(
                  color: detailColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar('Plan Manager'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with stats
            _buildPlanStats(rehabPlan),
            const SizedBox(height: 16),
            
            // Exercise List
            Expanded(
              child: rehabPlan.exercises.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: rehabPlan.exercises.length,
                      itemBuilder: (context, index) {
                        return _buildExerciseCard(rehabPlan.exercises[index], index);
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Notes Section
            _buildNotesSection(),

            const SizedBox(height: 20),

            // Add Exercise Button
            _buildAddExerciseButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      automaticallyImplyLeading: false,
      centerTitle: true,
      backgroundColor: mainColor,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      // actions: [
      //   Padding(
      //     padding: const EdgeInsets.only(right: 12),
      //     child: IconButton(
      //       icon: const Icon(Icons.info_outline, size: 26),
      //       onPressed: () {
      //         // Add info action
      //       },
      //     ),
      //   ),
      // ],
    );
  }

  Widget _buildPlanStats(RehabilitationPlan plan) {
    return Card(
      elevation: 0,
      color: accentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: mainColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.fitness_center, 'Exercises', plan.exercises.length.toString()),
            _buildStatItem(Icons.calendar_today, 'Week', plan.weekNumber.toString()),
            _buildStatItem(
              Icons.timer,
              'Duration',
              '${plan.exercises.fold(0, (sum, e) => sum + e.sets * e.repetitions)} reps',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: mainColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: mainColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: detailColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no_exercises.png', // Add your own asset
            width: 180,
            height: 180,
          ),
          const SizedBox(height: 20),
          Text(
            "No exercises in this plan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: detailColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your first exercise to get started",
            style: TextStyle(
              fontSize: 14,
              color: detailColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Add exercise detail view
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with image and basic info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: detailColor.withOpacity(0.1),
                      image: exercise.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(exercise.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: exercise.imageUrl.isEmpty
                        ? Center(
                            child: Icon(
                              Icons.fitness_center,
                              size: 36,
                              color: detailColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Exercise Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mainColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.repeat, size: 16, color: subColor),
                            const SizedBox(width: 4),
                            Text(
                              '${exercise.repetitions} reps',
                              style: TextStyle(color: subColor),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.format_list_numbered, size: 16, color: subColor),
                            const SizedBox(width: 4),
                            Text(
                              '${exercise.sets} sets',
                              style: TextStyle(color: subColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.medical_services, size: 16, color: detailColor),
                            const SizedBox(width: 4),
                            Text(
                              exercise.muscle,
                              style: TextStyle(
                                color: detailColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                exercise.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Replace Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: subColor,
                      side: BorderSide(color: subColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _replaceExercise(index),
                    icon: const Icon(Icons.autorenew, size: 20),
                    label: const Text('Replace'),
                  ),
                  const SizedBox(width: 12),
                  
                  // Delete Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _confirmDeleteExercise(index),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notes",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: mainColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          onChanged: (value) => _saveNotes(), // Auto-save on change
          decoration: InputDecoration(
            hintText: 'Write your progress notes here...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: subColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddExerciseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _addExercise,
        style: ElevatedButton.styleFrom(
          backgroundColor: subColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: subColor.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              "Add New Exercise",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Exercise?> generateRandomExercise({
    required String muscle,
    required String painLevel,
    required String painDuration,
    required String goal,
  }) async {
    try {
      final plan = await generateRehabilitationPlanFromCSV();
      if (plan == null) return null;

      final matchingExercises = plan.exercises.where((exercise) =>
          exercise.muscle == muscle &&
          exercise.painLevel == painLevel &&
          exercise.goal == goal);

      if (matchingExercises.isEmpty) return null;

      return matchingExercises.elementAt(_random.nextInt(matchingExercises.length));
    } catch (e) {
      debugPrint('Error generating random exercise: $e');
      return null;
    }
  }
}