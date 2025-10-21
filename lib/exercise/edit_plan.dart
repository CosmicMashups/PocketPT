import 'dart:math';
import 'package:flutter/material.dart';
import '../data/rehabilitation_plan.dart';
import '../data/treatment.dart';
import '../assessment/generate_treatment.dart';
import '../data/globals.dart';
import 'exercise_list.dart' as exList;

class EditPlanPage extends StatefulWidget {
  const EditPlanPage({super.key});

  @override
  State<EditPlanPage> createState() => _EditPlanPageState();
}

class _EditPlanPageState extends State<EditPlanPage> {
  late final TextEditingController _notesController;
  final Random _random = Random();
  List<Treatment>? _treatments;
  bool _isLoadingTreatments = false;
  List<exList.Exercise>? _exercises;

  // Updated color constants based on the provided theme
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC1574F);
  static const detailColor = Color(0xFF6A5D7B);

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: UserProgress.notes ?? '');
    _loadTreatments();
    _loadExercises();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await ExerciseDataService.loadAllExercises();
      // Convert Exercise from rehabilitation_plan.dart to Exercise from exercise_list.dart
      final convertedExercises = exercises.map((ex) => exList.Exercise(
        id: ex.exerciseId,
        name: ex.exerciseName,
        description: ex.description,
        muscle: ex.muscle,
        painLevel: ex.painLevel,
        goal: ex.goal,
        rep: ex.repetitions,
        set: ex.sets,
        imageUrl: ex.imageUrl,
        videoUrl: ex.videoUrl,
        otherMuscles: ex.otherMuscles,
      )).toList();
      
      setState(() {
        _exercises = convertedExercises;
      });
    } catch (e) {
      debugPrint('Error loading exercises: $e');
    }
  }

  String _getExerciseName(String exerciseId) {
    if (_exercises == null) return exerciseId;
    
    final exercise = _exercises!.firstWhere(
      (ex) => ex.id == exerciseId,
      orElse: () => exList.Exercise(
        id: exerciseId,
        name: exerciseId, // Fallback to ID if not found
        description: '',
        muscle: '',
        painLevel: '',
        goal: '',
        rep: 0,
        set: 0,
        imageUrl: '',
        videoUrl: '',
        otherMuscles: '',
      ),
    );
    
    return exercise.name;
  }

  Future<void> _loadTreatments() async {
    try {
      // Check if treatments are already loaded
      if (UserRehabilitation.instance.treatmentReferences != null) {
        final treatmentIds = UserRehabilitation.instance.treatmentReferences!
            .map((ref) => ref.treatmentId)
            .toList();
        final treatments = await ExerciseDataService.getTreatmentsByIds(treatmentIds);
        setState(() {
          _treatments = treatments;
        });
        return;
      }

      setState(() {
        _isLoadingTreatments = true;
      });

      final treatmentReferences = await generateTreatmentPlan(
        specificMuscle: UserRehabilitation.instance.selectedMuscle,
        painLevel: UserRehabilitation.instance.selectedPainLevel,
        painDuration: UserRehabilitation.instance.selectedPainDuration,
      );
      
      if (mounted && treatmentReferences != null) {
        // Get full treatment data from references
        final treatmentIds = treatmentReferences.map((ref) => ref.treatmentId).toList();
        final treatments = await ExerciseDataService.getTreatmentsByIds(treatmentIds);
        
        setState(() {
          _treatments = treatments;
          _isLoadingTreatments = false;
        });
        
        UserRehabilitation.instance.treatmentReferences = treatmentReferences;
        await UserRehabilitation.instance.savePlansToHive();
      } else if (mounted) {
        setState(() {
          _isLoadingTreatments = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading treatments: $e');
      if (mounted) {
        setState(() {
          _isLoadingTreatments = false;
        });
      }
    }
  }

  Future<void> _refreshTreatments() async {
    try {
      setState(() {
        _isLoadingTreatments = true;
      });
      
      // Clear existing treatments to force reload
      UserRehabilitation.instance.treatmentReferences = null;
      
      final treatmentReferences = await generateTreatmentPlan(
        specificMuscle: UserRehabilitation.instance.selectedMuscle,
        painLevel: UserRehabilitation.instance.selectedPainLevel,
        painDuration: UserRehabilitation.instance.selectedPainDuration,
      );
      
      if (mounted && treatmentReferences != null) {
        // Get full treatment data from references
        final treatmentIds = treatmentReferences.map((ref) => ref.treatmentId).toList();
        final treatments = await ExerciseDataService.getTreatmentsByIds(treatmentIds);
        
        setState(() {
          _treatments = treatments;
          _isLoadingTreatments = false;
        });
        
        UserRehabilitation.instance.treatmentReferences = treatmentReferences;
        await UserRehabilitation.instance.savePlansToHive();
      } else if (mounted) {
        setState(() {
          _isLoadingTreatments = false;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing treatments: $e');
      if (mounted) {
        setState(() {
          _isLoadingTreatments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rehabPlan = UserRehabilitation.instance.rehabPlans.isNotEmpty
        ? UserRehabilitation.instance.rehabPlans.first
        : null;

    if (rehabPlan == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF121212), Color(0xFF1C1C1C)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF5F5F5)],
                  ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                backgroundColor: mainColor,
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.3),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Exercise Manager',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8B2E2E), Color(0xFFA03A3A)],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildNoPlanState(isDark),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF121212), Color(0xFF1C1C1C)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF5F5F5)],
                ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: mainColor,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.3),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Plan Manager',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8B2E2E), Color(0xFFA03A3A)],
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: const Icon(Icons.help_outline, size: 26, color: Colors.white),
                    onPressed: _showHelpDialog,
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _buildPlanContent(rehabPlan, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPlanState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 120,
              color: isDark ? Colors.white54 : Colors.grey.shade400,
              ),
              const SizedBox(height: 20),
              Text(
                "No rehabilitation plan available",
                style: TextStyle(
                color: isDark ? Colors.white70 : detailColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Create a new plan to get started",
                style: TextStyle(
                color: isDark ? Colors.white60 : detailColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildPlanContent(RehabilitationPlan rehabPlan, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          _buildPlanStats(rehabPlan, isDark),
          const SizedBox(height: 20),

              // Exercise List
          Text(
            'Exercises',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: mainColor,
              letterSpacing: 0.3,
            ),
                    ),
              const SizedBox(height: 12),
          rehabPlan.exerciseReferences.isEmpty
              ? _buildEmptyState(isDark)
              : _buildExerciseList(rehabPlan, isDark),
          const SizedBox(height: 16),
              _buildAddExerciseButtons(),
          const SizedBox(height: 28),

              // Treatments Section
              if (_isLoadingTreatments)
                _buildTreatmentLoadingState()
              else if (_treatments != null && _treatments!.isNotEmpty)
                _buildTreatmentSection()
              else if (_treatments != null && _treatments!.isEmpty)
                _buildNoTreatmentsMessage(),
          const SizedBox(height: 28),

              // Notes Section
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: mainColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
              _buildNotesSection(),
          const SizedBox(height: 24),
            ],
      ),
    );
  }

  Widget _buildExerciseList(RehabilitationPlan rehabPlan, bool isDark) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: rehabPlan.exerciseReferences.length,
      itemBuilder: (context, index) {
        return AnimatedOpacity(
          opacity: 1.0,
          duration: Duration(milliseconds: 300 + (index * 100)),
          child: _buildExerciseCard(rehabPlan.exerciseReferences[index], index, isDark),
        );
      },
    );
  }


  Widget _buildPlanStats(RehabilitationPlan plan, bool isDark) {
    return Card(
      elevation: isDark ? 6 : 8,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      color: isDark 
          ? Theme.of(context).colorScheme.surface.withOpacity(0.9)
          : Colors.white.withOpacity(0.95),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              mainColor.withOpacity(0.1),
              subColor.withOpacity(0.05),
            ],
          ),
      ),
      child: Padding(
          padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
              _buildStatItem(Icons.fitness_center_rounded, 'Exercises', plan.exerciseReferences.length.toString(), isDark),
              _buildStatItem(Icons.calendar_today_rounded, 'Week', plan.weekNumber.toString(), isDark),
            _buildStatItem(
                Icons.timer_rounded,
              'Duration',
              '${plan.exerciseReferences.fold(0, (sum, e) => sum + e.sets * e.repetitions)} reps',
                isDark,
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 24, color: mainColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: mainColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : detailColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
            Icons.fitness_center_outlined,
                size: 64,
                color: mainColor,
              ),
          ),
          const SizedBox(height: 20),
          Text(
            "No exercises in this plan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : detailColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your first exercise to get started",
            style: TextStyle(
              fontSize: 14,
                color: isDark ? Colors.white60 : detailColor.withOpacity(0.7),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseReference exerciseRef, int index, bool isDark) {
    return Card(
      elevation: isDark ? 6 : 8,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      clipBehavior: Clip.antiAlias,
      color: isDark 
          ? Theme.of(context).colorScheme.surface.withOpacity(0.9)
          : Colors.white.withOpacity(0.95),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Add exercise detail view
        },
        splashColor: mainColor.withOpacity(0.1),
        highlightColor: mainColor.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                mainColor.withOpacity(0.05),
                subColor.withOpacity(0.02),
              ],
            ),
          ),
        child: Padding(
            padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with basic info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            mainColor.withOpacity(0.2),
                            subColor.withOpacity(0.1),
                          ],
                        ),
                    ),
                    child: Center(
                      child: Icon(
                          Icons.fitness_center_rounded,
                        size: 36,
                          color: mainColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Exercise Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            _getExerciseName(exerciseRef.exerciseId),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            color: mainColor,
                              letterSpacing: 0.3,
                          ),
                        ),
                          const SizedBox(height: 8),
                        Row(
                          children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: subColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.repeat_rounded, size: 16, color: subColor),
                            const SizedBox(width: 4),
                            Text(
                              '${exerciseRef.repetitions} reps',
                                      style: TextStyle(
                                        color: subColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: detailColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.format_list_numbered_rounded, size: 16, color: detailColor),
                            const SizedBox(width: 4),
                            Text(
                              '${exerciseRef.sets} sets',
                                      style: TextStyle(
                                        color: detailColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
                const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Replace Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: subColor,
                        side: BorderSide(color: subColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                          vertical: 12,
                      ),
                    ),
                    onPressed: () => _replaceExercise(index),
                      icon: const Icon(Icons.autorenew_rounded, size: 18),
                    label: const Text('Replace'),
                  ),
                  const SizedBox(width: 12),
                  
                  // Delete Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                          vertical: 12,
                      ),
                    ),
                    onPressed: () => _confirmDeleteExercise(index),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveNotes() {
    setState(() {
      UserProgress.notes = _notesController.text;
    });
  }

  Future<void> _replaceExercise(int index) async {
    final currentExercise = UserRehabilitation.instance.rehabPlans.first.exerciseReferences[index];

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Replace Exercise'),
          content: Text('Are you sure you want to replace "${_getExerciseName(currentExercise.exerciseId)}"?'),
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
        muscle: 'general', // Default muscle
        painLevel: 'moderate', // Default pain level
        painDuration: UserRehabilitation.instance.selectedPainDuration,
        goal: 'rehabilitation', // Default goal
      );

      if (newExercise != null) {
        setState(() {
          final replacementExercise = ExerciseReference(
            exerciseId: newExercise.exerciseId,
            repetitions: newExercise.repetitions,
            sets: newExercise.sets,
          );
          UserRehabilitation.instance.rehabPlans.first.exerciseReferences[index] = replacementExercise;
        });
        await UserRehabilitation.instance.savePlansToHive();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Replaced with ${_getExerciseName(newExercise.exerciseId)}'),
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

  void _addExerciseFromList() async {
    final newExercise = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const exList.ExercisesPage(selectingForAddition: true),
      ),
    );

    if (newExercise != null && newExercise is exList.Exercise) {
      final convertedExercise = ExerciseReference(
        exerciseId: newExercise.id,
        repetitions: newExercise.rep,
        sets: newExercise.set,
      );

      setState(() {
        UserRehabilitation.instance.rehabPlans.first.exerciseReferences.add(convertedExercise);
      });
      await UserRehabilitation.instance.savePlansToHive();
    }
  }

  void _addSimpleExercise() {
    // Simple exercise selection - in a real implementation, this would show a list
    final availableExercises = ['exercise1', 'exercise2', 'exercise3']; // Placeholder exercises
    if (availableExercises.isNotEmpty) {
      final randomExercise = availableExercises[_random.nextInt(availableExercises.length)];
      final exerciseRef = ExerciseReference(
        exerciseId: randomExercise,
        repetitions: 10,
        sets: 3,
      );
      
      setState(() {
        UserRehabilitation.instance.rehabPlans.first.exerciseReferences.add(exerciseRef);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added exercise: $randomExercise'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDeleteExercise(int index) async {
    final exercise = UserRehabilitation.instance.rehabPlans.first.exerciseReferences[index];

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Exercise'),
          content: Text('Are you sure you want to delete "${_getExerciseName(exercise.exerciseId)}" from your plan?'),
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
        UserRehabilitation.instance.rehabPlans.first.exerciseReferences.removeAt(index);
      });
      await UserRehabilitation.instance.savePlansToHive();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Deleted "${_getExerciseName(exercise.exerciseId)}"'),
          backgroundColor: mainColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildAddExerciseButtons() {
    return Column(
      children: [
        // Advanced Add Exercise Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addExerciseFromList,
            style: ElevatedButton.styleFrom(
              backgroundColor: subColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: subColor.withOpacity(0.3),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
                  "Add New Exercise (Advanced)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Simple Add Exercise Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addSimpleExercise,
            style: OutlinedButton.styleFrom(
              foregroundColor: mainColor,
              side: BorderSide(color: mainColor, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: const Text(
                  "Add Simple Exercise",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "💊 Recommended Treatments",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: mainColor,
                letterSpacing: 0.3,
              ),
            ),
            TextButton.icon(
              onPressed: _isLoadingTreatments ? null : _refreshTreatments,
              icon: _isLoadingTreatments 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(subColor),
                    ),
                  )
                : Icon(Icons.refresh_rounded, size: 18, color: subColor),
              label: Text(
                _isLoadingTreatments ? 'Loading...' : 'Refresh',
                style: TextStyle(
                  color: _isLoadingTreatments ? subColor.withOpacity(0.6) : subColor, 
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _treatments!.length,
          itemBuilder: (context, index) => AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 300 + (index * 100)),
            child: _buildTreatmentCard(_treatments![index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentCard(Treatment treatment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 6 : 8,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      clipBehavior: Clip.antiAlias,
      color: isDark 
          ? Theme.of(context).colorScheme.surface.withOpacity(0.9)
          : Colors.white.withOpacity(0.95),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              subColor.withOpacity(0.05),
              detailColor.withOpacity(0.02),
            ],
          ),
        ),
      child: Padding(
          padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: subColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medical_services_rounded,
                  size: 24,
                  color: subColor,
                    ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    treatment.treatmentName,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      color: mainColor,
                        letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
              const SizedBox(height: 16),
            Text(
              treatment.description,
              style: TextStyle(
                fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
              children: [
                  _buildTreatmentTag(
                    Icons.accessibility_new_rounded,
                  treatment.musclesInvolved,
                    detailColor,
                  ),
                  _buildTreatmentTag(
                    Icons.health_and_safety_rounded,
                  treatment.painLevel,
                    detailColor,
                  ),
                  _buildTreatmentTag(
                    Icons.timer_rounded,
                    treatment.painDuration,
                    detailColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
            text,
                  style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildNoTreatmentsMessage() {
    return Card(
      elevation: 0,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No specific treatments recommended for your current condition. Focus on the exercise plan and consult with a healthcare professional if needed.',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentLoadingState() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(subColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading recommended treatments...',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 6 : 8,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      color: isDark 
          ? Theme.of(context).colorScheme.surface.withOpacity(0.9)
          : Colors.white.withOpacity(0.95),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              mainColor.withOpacity(0.05),
              subColor.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
      controller: _notesController,
      maxLines: 4,
      onChanged: (value) => _saveNotes(), // Auto-save on change
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey.shade800,
              height: 1.4,
            ),
      decoration: InputDecoration(
        hintText: 'Write your progress notes here...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade500,
                fontSize: 14,
              ),
              filled: false,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const Text(
          'This page allows you to manage your exercise plans:\n\n'
          '• Add new exercises to your plans (Advanced or Simple)\n'
          '• Replace exercises with similar alternatives\n'
          '• Remove exercises you no longer need\n'
          '• View recommended treatments\n'
          '• Add notes about your progress\n\n'
          'Complete an assessment to generate your initial exercise plans.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<ExerciseReference?> generateRandomExercise({
    required String muscle,
    required String painLevel,
    required String painDuration,
    required String goal,
  }) async {
    try {
      // Create a simple random exercise for replacement
      final exerciseId = 'exercise_${_random.nextInt(100)}_${muscle}_${goal}';
      return ExerciseReference(
        exerciseId: exerciseId,
        repetitions: 10 + _random.nextInt(10), // 10-19 reps
        sets: 2 + _random.nextInt(3), // 2-4 sets
      );
    } catch (e) {
      debugPrint('Error generating random exercise: $e');
      return null;
    }
  }
}