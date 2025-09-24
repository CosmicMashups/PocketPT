import 'dart:math';
import 'package:flutter/material.dart';
import '../data/rehabilitation_plan.dart';
import '../data/treatment.dart';
import '../assessment/generate_treatment.dart';
// import '../data/treatment.dart';
import 'exercise_list.dart' as exList;
// import '../assessment/generate_treatment.dart';
import '../data/globals.dart';

class ExerciseManagerPage extends StatefulWidget {
  const ExerciseManagerPage({super.key});

  @override
  State<ExerciseManagerPage> createState() => _ExerciseManagerPageState();
}

class _ExerciseManagerPageState extends State<ExerciseManagerPage> {
  final TextEditingController _notesController = TextEditingController();
  final Random _random = Random();
  List<TreatmentReference>? _treatmentReferences;
  bool _isLoadingTreatments = false;
  List<ExerciseReference> _exerciseReferences = [];
  bool _isLoadingExercises = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = UserProgress.notes ?? '';
    _loadExerciseReferences();
    _loadTreatments();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh exercise references when the page is resumed
    _loadExerciseReferences();
  }

  Future<void> _loadExerciseReferences() async {
    try {
      setState(() {
        _isLoadingExercises = true;
      });

      // Load exercise references from the rehabilitation plan
      if (UserRehabilitation.instance.rehabPlans.isNotEmpty) {
        final plan = UserRehabilitation.instance.rehabPlans.first;
        setState(() {
          _exerciseReferences = List.from(plan.exerciseReferences);
          _isLoadingExercises = false;
        });
      } else {
        setState(() {
          _exerciseReferences = [];
          _isLoadingExercises = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading exercise references: $e');
      setState(() {
        _exerciseReferences = [];
        _isLoadingExercises = false;
      });
    }
  }

  Future<void> _loadTreatments() async {
    try {
      // Check if treatment references are already loaded
      if (UserRehabilitation.instance.treatmentReferences != null) {
        setState(() {
          _treatmentReferences = UserRehabilitation.instance.treatmentReferences;
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
      
      if (mounted) {
        setState(() {
          _treatmentReferences = treatmentReferences;
          UserRehabilitation.instance.treatmentReferences = treatmentReferences;
          _isLoadingTreatments = false;
        });
        await UserRehabilitation.instance.savePlansToHive();
      }
    } catch (e) {
      debugPrint('Error loading treatment references: $e');
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
      
      // Clear existing treatment references to force reload
      UserRehabilitation.instance.treatmentReferences = null;
      
      final treatmentReferences = await generateTreatmentPlan(
        specificMuscle: UserRehabilitation.instance.selectedMuscle,
        painLevel: UserRehabilitation.instance.selectedPainLevel,
        painDuration: UserRehabilitation.instance.selectedPainDuration,
      );
      
      if (mounted) {
        setState(() {
          _treatmentReferences = treatmentReferences;
          UserRehabilitation.instance.treatmentReferences = treatmentReferences;
          _isLoadingTreatments = false;
        });
        await UserRehabilitation.instance.savePlansToHive();
      }
    } catch (e) {
      debugPrint('Error refreshing treatment references: $e');
      if (mounted) {
        setState(() {
          _isLoadingTreatments = false;
        });
      }
    }
  }
  
  // Professional healthcare color scheme
  static const backgroundColor = Color(0xFFF8FAFC);
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);
  static const accentColor = Color(0xFFF0F9FF);
  static const successColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);

  void _saveNotes() {
    setState(() {
      UserProgress.notes = _notesController.text;
    });
  }

  Future<void> _updateRehabilitationPlan() async {
    try {
      // Create a new plan with updated exercise references
      final weekNumber = UserRehabilitation.instance.rehabPlans.isNotEmpty 
          ? UserRehabilitation.instance.rehabPlans.first.weekNumber 
          : 1;
      
      UserRehabilitation.instance.rehabPlans = [
        RehabilitationPlan(
          weekNumber: weekNumber,
          exerciseReferences: List.from(_exerciseReferences),
          daily: UserRehabilitation.instance.rehabPlans.isNotEmpty 
              ? UserRehabilitation.instance.rehabPlans.first.daily 
              : [],
        )
      ];
      
      // Save to Hive
      await UserRehabilitation.instance.savePlansToHive();
    } catch (e) {
      debugPrint('Error updating rehabilitation plan: $e');
    }
  }

  Future<void> _replaceExercise(int index) async {
    final currentExerciseRef = _exerciseReferences[index];
    
    // Get full exercise data to show in confirmation dialog
    final currentExercise = await ExerciseDataService.getExerciseById(currentExerciseRef.exerciseId);
    if (currentExercise == null) return;

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
          final replacementExerciseRef = ExerciseReference(
            exerciseId: newExercise.exerciseId,
            sets: currentExerciseRef.sets,
            repetitions: currentExerciseRef.repetitions,
          );
          _exerciseReferences[index] = replacementExerciseRef;
        });
        await _updateRehabilitationPlan();

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
      final convertedExerciseRef = ExerciseReference(
        exerciseId: newExercise.id,
        sets: newExercise.set,
        repetitions: newExercise.rep,
      );

      setState(() {
        _exerciseReferences.add(convertedExerciseRef);
      });
      await _updateRehabilitationPlan();
    }
  }

  Future<void> _confirmDeleteExercise(int index) async {
    final exerciseRef = _exerciseReferences[index];
    
    // Get full exercise data to show in confirmation dialog
    final exercise = await ExerciseDataService.getExerciseById(exerciseRef.exerciseId);
    if (exercise == null) return;

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
        _exerciseReferences.removeAt(index);
      });
      await _updateRehabilitationPlan();

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
    if (_isLoadingExercises) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar("Exercise Manager"),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_exerciseReferences.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar("Exercise Manager"),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 120,
                color: Colors.grey[400],
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
      appBar: _buildAppBar('Exercise Plan Manager'),
      body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlanStats(),
            const SizedBox(height: 24),

            // Exercise Management Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: mainColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exercise Prescriptions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: mainColor,
                              ),
                            ),
                            Text(
                              'Manage prescribed exercises and parameters',
                              style: TextStyle(
                                fontSize: 14,
                                color: detailColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
              _exerciseReferences.isEmpty
                  ? _buildEmptyState()
                  : _buildExerciseList(),
                  const SizedBox(height: 16),
              _buildAddExerciseButton(),
                ],
              ),
            ),
              const SizedBox(height: 24),

              // Treatments Section
              if (_isLoadingTreatments)
                _buildTreatmentLoadingState()
              else if (_treatmentReferences != null && _treatmentReferences!.isNotEmpty)
                _buildTreatmentSection()
              else if (_treatmentReferences != null && _treatmentReferences!.isEmpty)
                _buildNoTreatmentsMessage(),
              const SizedBox(height: 24),

              // Notes Section
              _buildNotesSection(),
              const SizedBox(height: 20),
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
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      automaticallyImplyLeading: false,
      centerTitle: true,
      backgroundColor: mainColor,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              mainColor,
              subColor,
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanStats() {
    final weekNumber = UserRehabilitation.instance.rehabPlans.isNotEmpty 
        ? UserRehabilitation.instance.rehabPlans.first.weekNumber 
        : 1;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
        padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: mainColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    Text(
                      'Treatment Plan Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: mainColor,
                      ),
                    ),
                    Text(
                      'Week $weekNumber of rehabilitation program',
                      style: TextStyle(
                        fontSize: 14,
                        color: detailColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.fitness_center, 
                  'Exercises', 
                  _exerciseReferences.length.toString(),
                  'Prescribed',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  Icons.calendar_today, 
                  'Week', 
                  weekNumber.toString(),
                  'Current',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
              Icons.timer,
                  'Total Reps',
                  '${_exerciseReferences.fold(0, (sum, e) => sum + e.sets * e.repetitions)}',
                  'Per Session',
                ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mainColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
      children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: mainColor),
          ),
          const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            color: mainColor,
          ),
        ),
          const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
              fontWeight: FontWeight.w600,
              color: mainColor,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
            color: detailColor,
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return FutureBuilder<List<Exercise>>(
      future: ExerciseDataService.getExercisesByIds(
        _exerciseReferences.map((ref) => ref.exerciseId).toList(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error loading exercises: ${snapshot.error}');
        }
        final exercises = snapshot.data ?? [];
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            return _buildExerciseCard(exercises[index], index);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 120,
            color: Colors.grey[400],
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
    final exerciseRef = _exerciseReferences[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
      color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Add exercise detail view
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with exercise info
              Row(
                children: [
                  // Exercise Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: mainColor.withOpacity(0.1),
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
                              size: 28,
                              color: mainColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Exercise Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: mainColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: subColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              exercise.muscle,
                              style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subColor,
                            ),
                              ),
                            ),
                          ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Exercise Parameters
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: mainColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildParameterItem(
                        Icons.repeat,
                        'Repetitions',
                        '${exerciseRef.repetitions}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: mainColor.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildParameterItem(
                        Icons.format_list_numbered,
                        'Sets',
                        '${exerciseRef.sets}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: mainColor.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildParameterItem(
                        Icons.timer,
                        'Total',
                        '${exerciseRef.sets * exerciseRef.repetitions}',
                    ),
                  ),
                ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                exercise.description,
                style: TextStyle(
                  fontSize: 14,
                  color: detailColor,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: warningColor,
                        side: BorderSide(color: warningColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                      ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _replaceExercise(index),
                      icon: const Icon(Icons.autorenew, size: 18),
                    label: const Text('Replace'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: errorColor,
                        foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                      ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _confirmDeleteExercise(index),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: mainColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: mainColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: detailColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: successColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                      "Recommended Treatments",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: mainColor,
              ),
            ),
                    Text(
                      "Clinical treatment recommendations",
                      style: TextStyle(
                        fontSize: 14,
                        color: detailColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: subColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
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
                    : Icon(Icons.refresh, size: 16, color: subColor),
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
                minimumSize: Size.zero,
                  ),
              ),
            ),
          ],
        ),
          const SizedBox(height: 20),
        // Load treatments from CSV and display them
        FutureBuilder<List<Treatment>>(
          future: ExerciseDataService.getTreatmentsByIds(
            _treatmentReferences!.map((ref) => ref.treatmentId).toList(),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error loading treatments: ${snapshot.error}');
            }
            final treatments = snapshot.data ?? [];
            return ListView.builder(
              shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              itemCount: treatments.length,
              itemBuilder: (context, index) => _buildTreatmentCard(treatments[index]),
            );
          },
        ),
      ],
      ),
    );
  }

  Widget _buildTreatmentCard(Treatment treatment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: successColor.withOpacity(0.2),
          width: 1,
        ),
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medical_services,
                  size: 20,
                  color: successColor,
                ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    treatment.treatmentName,
                    style: TextStyle(
                      fontSize: 16,
                    fontWeight: FontWeight.w700,
                      color: mainColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              treatment.description,
              style: TextStyle(
                fontSize: 14,
              color: detailColor,
              height: 1.4,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Treatment details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: successColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
            Row(
              children: [
                    Expanded(
                      child: _buildTreatmentDetailItem(
                        Icons.accessibility_new,
                        'Muscles',
                  treatment.musclesInvolved,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: successColor.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildTreatmentDetailItem(
                        Icons.health_and_safety,
                        'Pain Level',
                        treatment.painLevel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTreatmentDetailItem(
                        Icons.timer,
                        'Duration',
                        treatment.painDuration,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Clinical Grade',
                  style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: successColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: successColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                label,
                  style: TextStyle(
                  fontSize: 10,
                    color: detailColor,
                  fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                value,
                  style: TextStyle(
                    fontSize: 12,
                  color: mainColor,
                  fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.note_alt,
                  color: warningColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Clinical Notes",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: mainColor,
                      ),
                    ),
                    Text(
                      "Document patient progress and observations",
                      style: TextStyle(
                        fontSize: 14,
                        color: detailColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
      controller: _notesController,
      maxLines: 4,
            onChanged: (value) => _saveNotes(),
      decoration: InputDecoration(
              hintText: 'Enter clinical notes, patient observations, or progress updates...',
        filled: true,
              fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: mainColor.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: mainColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              fontSize: 14,
              color: mainColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExerciseButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mainColor,
            subColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _addExercise,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Add New Exercise",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
      final allExercises = await ExerciseDataService.loadAllExercises();
      
      final matchingExercises = allExercises.where((exercise) =>
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