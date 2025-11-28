import 'dart:math';
import 'package:flutter/material.dart';
import '../data/rehabilitation_plan.dart';
import '../data/treatment.dart';
import '../assessment/generate_treatment.dart';
import '../data/globals.dart';
import '../core/medical_design_system.dart';
import '../data/custom_exercise_service.dart';
import 'exercise_list.dart' as exList;
import 'exercise_detail.dart';

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

  // Medical design system colors
  static const mainColor = MedicalDesignSystem.primaryBrand;
  static const subColor = MedicalDesignSystem.brandAccent;
  static const detailColor = MedicalDesignSystem.textSecondary;

  // Standardized muscle list for custom exercises
  static const List<String> standardizedMuscles = [
    'Deltoids',
    'Biceps',
    'Triceps',
    'Upper Back',
    'Lower Back',
    'Abdominals',
    'Obliques',
    'Multifidus',
    'Quadriceps',
    'Hamstrings',
    'Calf',
    'Gluteals',
  ];

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
    
    // Check if there are treatments even when no plan exists (treatments-only case)
    final hasTreatments = UserRehabilitation.instance.treatmentReferences != null &&
        UserRehabilitation.instance.treatmentReferences!.isNotEmpty;

    if (rehabPlan == null && !hasTreatments) {
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
              expandedHeight: 140.0,
              floating: false,
              pinned: true,
              backgroundColor: MedicalDesignSystem.primaryBrand,
              elevation: 8,
              shadowColor: MedicalDesignSystem.primaryBrand.withOpacity(0.3),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Plan Manager',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: MedicalDesignSystem.medicalGradientBackground,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MedicalDesignSystem.primaryBrand,
                          MedicalDesignSystem.primaryLight,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Icon(
                            MedicalIcons.medicalServices,
                            color: Colors.white,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: const Icon(MedicalIcons.contactSupport, size: 26, color: Colors.white),
                    onPressed: _showHelpDialog,
                    tooltip: 'Medical Support',
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

  Widget _buildPlanContent(RehabilitationPlan? rehabPlan, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Only show plan stats if plan exists
          if (rehabPlan != null) ...[
            _buildPlanStats(rehabPlan, isDark),
            const SizedBox(height: 20),
          ],

              // Exercise List (only if plan exists)
          if (rehabPlan != null) ...[
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
          ] else ...[
            // Show message when no exercises but treatments exist
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No exercises in your plan. Focus on the recommended treatments below.',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

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
    return MedicalDesignSystem.medicalCardWithHeader(
      title: 'Rehabilitation Progress Overview',
      icon: MedicalIcons.trendingUp,
      iconColor: MedicalDesignSystem.primaryBrand,
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMedicalStatItem(
                MedicalIcons.fitnessCenter, 
                'Exercises', 
                plan.exerciseReferences.length.toString(),
                MedicalDesignSystem.primaryBrand,
              ),
              _buildMedicalStatItem(
                MedicalIcons.calendarToday, 
                'Week', 
                plan.weekNumber.toString(),
                MedicalDesignSystem.accentTeal,
              ),
              _buildMedicalStatItem(
                MedicalIcons.timer, 
                'Total Reps', 
                '${plan.exerciseReferences.fold(0, (sum, e) => sum + e.sets * e.repetitions)}',
                MedicalDesignSystem.successGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          MedicalDesignSystem.medicalDisclaimerBanner(
            text: 'Consult your healthcare provider before starting any new exercise program.',
            isWarning: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: MedicalDesignSystem.headerStyle.copyWith(
            fontSize: 24,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: MedicalDesignSystem.labelStyle.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: MedicalDesignSystem.medicalCardAccentDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // Navigate to exercise detail page
          if (_exercises != null) {
            try {
              final exercise = _exercises!.firstWhere(
                (ex) => ex.id == exerciseRef.exerciseId,
                orElse: () => exList.Exercise(
                  id: exerciseRef.exerciseId,
                  name: _getExerciseName(exerciseRef.exerciseId),
                  description: '',
                  muscle: '',
                  painLevel: '',
                  goal: '',
                  rep: exerciseRef.repetitions,
                  set: exerciseRef.sets,
                  imageUrl: '',
                  videoUrl: '',
                  otherMuscles: '',
                ),
              );
              
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailPage(
                    exercise: exercise,
                    isSelecting: false, // Don't show Select button
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Error navigating to exercise detail: $e');
            }
          }
        },
        splashColor: MedicalDesignSystem.primaryBrand.withOpacity(0.1),
        highlightColor: MedicalDesignSystem.primaryBrand.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medical Exercise Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medical Exercise Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MedicalDesignSystem.primaryBrand.withOpacity(0.2),
                          MedicalDesignSystem.primaryLight.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: MedicalDesignSystem.primaryBrand.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        MedicalIcons.fitnessCenter,
                        size: 36,
                        color: MedicalDesignSystem.primaryBrand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Exercise Medical Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getExerciseName(exerciseRef.exerciseId),
                          style: MedicalDesignSystem.subheaderStyle.copyWith(
                            color: MedicalDesignSystem.primaryBrand,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            MedicalDesignSystem.medicalStatusBadge(
                              text: '${exerciseRef.repetitions} reps',
                              status: MedicalStatus.info,
                            ),
                            const SizedBox(width: 8),
                            MedicalDesignSystem.medicalStatusBadge(
                              text: '${exerciseRef.sets} sets',
                              status: MedicalStatus.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Medical Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Medical Replace Button
                  ElevatedButton.icon(
                    style: MedicalDesignSystem.secondaryMedicalButton,
                    onPressed: () => _replaceExercise(index),
                    icon: const Icon(MedicalIcons.emergency, size: 18),
                    label: const Text('Replace'),
                  ),
                  const SizedBox(width: 12),
                  
                  // Medical Delete Button
                  ElevatedButton.icon(
                    style: MedicalDesignSystem.warningMedicalButton,
                    onPressed: () => _confirmDeleteExercise(index),
                    icon: const Icon(MedicalIcons.report, size: 18),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ],
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
    final currentExerciseRef = UserRehabilitation.instance.rehabPlans.first.exerciseReferences[index];
    final currentExerciseName = _getExerciseName(currentExerciseRef.exerciseId);

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Replace Exercise'),
          content: Text('Are you sure you want to replace "$currentExerciseName"?'),
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
      // Get current exercise details to use for replacement criteria
      exList.Exercise? currentExerciseDetails;
      if (_exercises != null) {
        try {
          currentExerciseDetails = _exercises!.firstWhere(
            (ex) => ex.id == currentExerciseRef.exerciseId,
          );
        } catch (e) {
          // Exercise not found in loaded exercises, use defaults
          currentExerciseDetails = null;
        }
      }

      final newExercise = await generateRandomExercise(
        muscle: currentExerciseDetails?.muscle ?? (UserRehabilitation.instance.selectedMuscle.isNotEmpty ? UserRehabilitation.instance.selectedMuscle : 'general'),
        painLevel: currentExerciseDetails?.painLevel ?? (UserRehabilitation.instance.selectedPainLevel.isNotEmpty ? UserRehabilitation.instance.selectedPainLevel : 'moderate'),
        painDuration: UserRehabilitation.instance.selectedPainDuration,
        goal: currentExerciseDetails?.goal ?? 'rehabilitation',
      );

      if (newExercise != null) {
        setState(() {
          final replacementExercise = ExerciseReference(
            exerciseId: newExercise.exerciseId,
            repetitions: currentExerciseRef.repetitions, // Keep original reps/sets
            sets: currentExerciseRef.sets,
          );
          UserRehabilitation.instance.rehabPlans.first.exerciseReferences[index] = replacementExercise;
        });
        await UserRehabilitation.instance.savePlansToHive();

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
                foregroundColor: Colors.white,
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
        // Add Exercise Button with Options
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showExerciseOptionDialog(context),
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
                  "Add Exercise",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showExerciseOptionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Add Exercise',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
            
            // Option 1: Select from Existing
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.library_add, color: mainColor),
              ),
              title: const Text(
                "Select from Existing Exercises",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text("Choose from pre-loaded exercises"),
              onTap: () {
                Navigator.pop(context);
                _addExerciseFromList();
              },
            ),
            
            const SizedBox(height: 8),
            
            // Option 2: Create Custom
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: subColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.create, color: subColor),
              ),
              title: const Text(
                "Create Custom Exercise",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text("Design your own exercise"),
              onTap: () {
                Navigator.pop(context);
                _showCustomExerciseDialog(context);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCustomExerciseDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    String selectedMuscle = standardizedMuscles.first;
    String? selectedOtherMuscle;
    String selectedPainLevel = 'Low';
    String selectedGoal = 'Alleviate Pain';
    int repetitions = 10;
    int sets = 3;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.create, color: subColor),
              const SizedBox(width: 8),
              const Text('Custom Exercise'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Name *',
                      hintText: 'Enter exercise name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Exercise name is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Describe how to perform the exercise',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Muscle Group
                  DropdownButtonFormField<String>(
                    value: selectedMuscle,
                    decoration: const InputDecoration(
                      labelText: 'Muscle Group *',
                      border: OutlineInputBorder(),
                    ),
                    items: standardizedMuscles.map((muscle) => DropdownMenuItem(
                      value: muscle,
                      child: Text(muscle),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMuscle = value!;
                        // Clear other muscle if it matches the new primary muscle
                        if (selectedOtherMuscle == value) {
                          selectedOtherMuscle = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pain Level
                  DropdownButtonFormField<String>(
                    value: selectedPainLevel,
                    decoration: const InputDecoration(
                      labelText: 'Pain Level *',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['Low', 'Moderate', 'Severe'].map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPainLevel = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Functional Goal
                  DropdownButtonFormField<String>(
                    value: selectedGoal,
                    decoration: const InputDecoration(
                      labelText: 'Functional Goal *',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['Alleviate Pain', 'Strengthen', 'Improve', 'Maintain'].map((goal) => DropdownMenuItem(
                      value: goal,
                      child: Text(goal),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedGoal = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Repetitions and Sets
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: repetitions.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Repetitions *',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            repetitions = int.tryParse(value) ?? 10;
                          },
                          validator: (value) {
                            final reps = int.tryParse(value ?? '');
                            if (reps == null || reps < 1) {
                              return 'Must be at least 1';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: sets.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sets *',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            sets = int.tryParse(value) ?? 3;
                          },
                          validator: (value) {
                            final setCount = int.tryParse(value ?? '');
                            if (setCount == null || setCount < 1) {
                              return 'Must be at least 1';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Other Muscles
                  DropdownButtonFormField<String>(
                    value: selectedOtherMuscle,
                    decoration: const InputDecoration(
                      labelText: 'Other Muscles (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: standardizedMuscles
                        .where((muscle) => muscle != selectedMuscle)
                        .map((muscle) => DropdownMenuItem(
                              value: muscle,
                              child: Text(muscle),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedOtherMuscle = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    isLoading = true;
                  });

                  try {
                    final customExercise = exList.Exercise(
                      id: 'CUSTOM_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      muscle: selectedMuscle,
                      painLevel: selectedPainLevel,
                      goal: selectedGoal,
                      rep: repetitions,
                      set: sets,
                      imageUrl: '.jpg',
                      videoUrl: '.mp4',
                      otherMuscles: selectedOtherMuscle ?? '',
                    );

                    await CustomExerciseService.saveExercise(customExercise);
                    
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Custom exercise "${customExercise.name}" created successfully!'),
                          backgroundColor: subColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      
                      // Refresh the exercise list
                      _loadExercises();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error creating exercise: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: subColor,
                foregroundColor: Colors.white,
              ),
              child: isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Create Exercise'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "💊 Treatments",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: mainColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: TextButton.icon(
                      onPressed: _isLoadingTreatments ? null : _showAddOptionalTreatmentsDialog,
                      icon: Icon(Icons.add_circle_outline, size: 18, color: subColor),
                      label: Text(
                        'Add Optional',
                        style: TextStyle(
                          color: subColor, 
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
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
                        : Icon(Icons.refresh_rounded, size: 18, color: subColor),
                      label: Text(
                        _isLoadingTreatments ? 'Loading...' : '',
                        style: TextStyle(
                          color: _isLoadingTreatments ? subColor.withOpacity(0.6) : subColor, 
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Separate mandatory (T001-T003) from optional treatments
        if (_treatments != null && _treatments!.isNotEmpty) ...[
          // Mandatory treatments section
          if (_hasMandatoryTreatments()) ...[
            Row(
              children: [
                Text(
                  "Core Treatments",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MedicalDesignSystem.primaryBrand,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Core Treatments (T001, T002, T003) are the only treatments automatically included in your plan. These foundational treatments provide essential care and must be completed in order. You can manually add additional optional treatments if needed.',
                  preferBelow: false,
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: MedicalDesignSystem.primaryBrand.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._treatments!.where((t) => ['T001', 'T002', 'T003'].contains(t.treatmentId)).map((treatment) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTreatmentCard(treatment, isMandatory: true),
              )
            ),
            const SizedBox(height: 16),
          ],
          // Optional treatments section
          if (_hasOptionalTreatments()) ...[
            Text(
              "Additional Treatments",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: detailColor,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            ..._treatments!.where((t) => !['T001', 'T002', 'T003'].contains(t.treatmentId)).map((treatment) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTreatmentCard(treatment, isMandatory: false),
              )
            ),
          ],
        ],
      ],
    );
  }

  bool _hasMandatoryTreatments() {
    if (_treatments == null || _treatments!.isEmpty) return false;
    return _treatments!.any((t) => ['T001', 'T002', 'T003'].contains(t.treatmentId));
  }

  bool _hasOptionalTreatments() {
    if (_treatments == null || _treatments!.isEmpty) return false;
    return _treatments!.any((t) => !['T001', 'T002', 'T003'].contains(t.treatmentId));
  }

  Widget _buildTreatmentCard(Treatment treatment, {bool isMandatory = false}) {
    return InkWell(
      onTap: () {
        _showTreatmentDetail(treatment);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: MedicalDesignSystem.medicalCardAccentDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and optional badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MedicalDesignSystem.primaryBrand.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(MedicalIcons.medicalServices, color: MedicalDesignSystem.primaryBrand, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      treatment.treatmentName,
                      style: MedicalDesignSystem.subheaderStyle.copyWith(
                        color: MedicalDesignSystem.primaryBrand,
                      ),
                    ),
                  ),
                  if (isMandatory)
                    Tooltip(
                      message: 'This is a Core Treatment. Core Treatments (T001, T002, T003) are the only treatments automatically included in your plan and cannot be removed or reordered. They provide essential foundational care.',
                      preferBelow: false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MedicalDesignSystem.primaryBrand.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: MedicalDesignSystem.primaryBrand.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Core',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: MedicalDesignSystem.primaryBrand,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    treatment.description,
                    style: MedicalDesignSystem.bodyStyle,
                  ),
                  // Display treatment instructions if available
                  if (treatment.treatmentInstruction.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MedicalDesignSystem.primaryBrand.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MedicalDesignSystem.primaryBrand.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(MedicalIcons.info, size: 16, color: MedicalDesignSystem.primaryBrand),
                              const SizedBox(width: 8),
                              Text(
                                'Instructions',
                                style: MedicalDesignSystem.subheaderStyle.copyWith(
                                  fontSize: 13,
                                  color: MedicalDesignSystem.primaryBrand,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            treatment.treatmentInstruction,
                            style: MedicalDesignSystem.bodyStyle.copyWith(
                              fontSize: 13,
                              color: MedicalDesignSystem.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  MedicalDesignSystem.medicalStatusBadge(
                    text: 'Pain Level: ${treatment.painLevel}',
                    status: MedicalStatus.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTreatmentDetail(Treatment treatment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(MedicalIcons.medicalServices, color: MedicalDesignSystem.primaryBrand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                treatment.treatmentName,
                style: MedicalDesignSystem.headerStyle,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Description',
                style: MedicalDesignSystem.subheaderStyle,
              ),
              const SizedBox(height: 8),
              Text(
                treatment.description,
                style: MedicalDesignSystem.bodyStyle,
              ),
              // Display treatment instructions if available
              if (treatment.treatmentInstruction.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Instructions',
                  style: MedicalDesignSystem.subheaderStyle,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MedicalDesignSystem.primaryBrand.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MedicalDesignSystem.primaryBrand.withOpacity(0.2)),
                  ),
                  child: Text(
                    treatment.treatmentInstruction,
                    style: MedicalDesignSystem.bodyStyle.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Details',
                style: MedicalDesignSystem.subheaderStyle,
              ),
              const SizedBox(height: 8),
              MedicalDesignSystem.medicalStatusBadge(
                text: 'Pain Level: ${treatment.painLevel}',
                status: MedicalStatus.warning,
              ),
              const SizedBox(height: 8),
              MedicalDesignSystem.medicalStatusBadge(
                text: 'Pain Duration: ${treatment.painDuration}',
                status: MedicalStatus.info,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: MedicalDesignSystem.primaryMedicalButton,
            child: const Text('Close'),
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
    return MedicalDesignSystem.medicalCardWithHeader(
      title: 'Medical Progress Notes',
      icon: MedicalIcons.report,
      iconColor: MedicalDesignSystem.primaryBrand,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _notesController,
            maxLines: 4,
            onChanged: (value) => _saveNotes(),
            style: MedicalDesignSystem.bodyStyle,
            decoration: InputDecoration(
              hintText: 'Document your rehabilitation progress, pain levels, and any concerns...',
              hintStyle: MedicalDesignSystem.medicalDisclaimerStyle,
              filled: true,
              fillColor: MedicalDesignSystem.backgroundClean,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: MedicalDesignSystem.primaryBrand.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: MedicalDesignSystem.primaryBrand,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          MedicalDesignSystem.medicalDisclaimerBanner(
            text: 'These notes are for your personal use. Share relevant information with your healthcare provider.',
            isWarning: false,
          ),
        ],
      ),
    );
  }

  void _showAddOptionalTreatmentsDialog() async {
    try {
      // Load all treatments to show in selection dialog
      final allTreatments = await ExerciseDataService.loadAllTreatments();
      
      // Filter to show only optional treatments (T004+) that aren't already in the plan
      final currentTreatmentIds = _treatments?.map((t) => t.treatmentId).toSet() ?? <String>{};
      final mandatoryTreatmentIds = {'T001', 'T002', 'T003'};
      
      final availableOptionalTreatments = allTreatments.where((treatment) {
        return !mandatoryTreatmentIds.contains(treatment.treatmentId) &&
               !currentTreatmentIds.contains(treatment.treatmentId);
      }).toList();
      
      if (availableOptionalTreatments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No additional optional treatments available to add.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      
      // Show selection dialog
      final selectedTreatments = await showDialog<List<Treatment>>(
        context: context,
        builder: (context) => _AddOptionalTreatmentsDialog(
          availableTreatments: availableOptionalTreatments,
        ),
      );
      
      if (selectedTreatments != null && selectedTreatments.isNotEmpty) {
        // Append selected treatments after existing optional treatments
        // Ensure mandatory treatments are present first
        List<TreatmentReference> updatedTreatments = [];
        
        // Start with existing treatments (which should have mandatory treatments)
        if (UserRehabilitation.instance.treatmentReferences != null && 
            UserRehabilitation.instance.treatmentReferences!.isNotEmpty) {
          updatedTreatments = List.from(UserRehabilitation.instance.treatmentReferences!);
        } else {
          // If no treatments exist, inject mandatory treatments first
          const mandatoryIds = ['T001', 'T002', 'T003'];
          updatedTreatments = mandatoryIds.map((id) => TreatmentReference(treatmentId: id)).toList();
        }
        
        // Add selected optional treatments (avoid duplicates)
        final existingIds = updatedTreatments.map((t) => t.treatmentId).toSet();
        for (final treatment in selectedTreatments) {
          if (!existingIds.contains(treatment.treatmentId)) {
            updatedTreatments.add(TreatmentReference(treatmentId: treatment.treatmentId));
            existingIds.add(treatment.treatmentId);
          }
        }
        
        // Update state
        setState(() {
          UserRehabilitation.instance.treatmentReferences = updatedTreatments;
          // Reload full treatment data for display
          _loadTreatments();
        });
        
        // Persist to Hive and Firebase
        await UserRehabilitation.instance.savePlansToHive();
        await UserRehabilitation.instance.savePlansToFirebase();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${selectedTreatments.length} optional treatment(s) to your plan'),
            backgroundColor: subColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing add optional treatments dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading treatments: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(MedicalIcons.contactSupport, color: MedicalDesignSystem.primaryBrand),
            const SizedBox(width: 8),
            const Text('Medical Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plan Management:\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• Add prescribed exercises to your rehabilitation plan\n'
                '• Replace exercises with healthcare provider-approved alternatives\n'
                '• Remove exercises that are no longer appropriate\n'
                '• Review recommended medical treatments\n'
                '• Document your progress and pain levels\n\n'
                'Complete a medical assessment to generate your personalized rehabilitation plan.',
              ),
              const SizedBox(height: 16),
              MedicalDesignSystem.medicalDisclaimerBanner(
                text: 'Always consult your healthcare provider before making changes to your exercise plan.',
                isWarning: true,
              ),
              const SizedBox(height: 12),
              MedicalDesignSystem.medicalDisclaimerBanner(
                text: 'Follow proper form and consult healthcare provider if experiencing pain during exercises.',
                isWarning: false,
              ),
              const SizedBox(height: 12),
              MedicalDesignSystem.medicalDisclaimerBanner(
                text: 'Treatment recommendations are for informational purposes only. Consult your healthcare provider before starting any treatment.',
                isWarning: true,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: MedicalDesignSystem.primaryMedicalButton,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood'),
          ),
        ],
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
      // Load all available exercises to find a suitable replacement
      final allExercises = await ExerciseDataService.loadAllExercises();
      
      if (allExercises.isEmpty) {
        debugPrint('No exercises available for replacement');
        return null;
      }

      // Filter exercises by muscle group and pain level if possible
      List<Exercise> suitableExercises = allExercises.where((exercise) {
        return exercise.muscle.toLowerCase().contains(muscle.toLowerCase()) ||
               muscle.toLowerCase().contains(exercise.muscle.toLowerCase()) ||
               exercise.painLevel.toLowerCase() == painLevel.toLowerCase();
      }).toList();

      // If no specific matches, use all exercises
      if (suitableExercises.isEmpty) {
        suitableExercises = allExercises;
      }

      // Select a random exercise from suitable candidates
      final selectedExercise = suitableExercises[_random.nextInt(suitableExercises.length)];
      
      return selectedExercise;
    } catch (e) {
      debugPrint('Error generating random exercise: $e');
      return null;
    }
  }
}

/// Dialog for selecting optional treatments to add to the plan
class _AddOptionalTreatmentsDialog extends StatefulWidget {
  final List<Treatment> availableTreatments;

  const _AddOptionalTreatmentsDialog({
    required this.availableTreatments,
  });

  @override
  State<_AddOptionalTreatmentsDialog> createState() => _AddOptionalTreatmentsDialogState();
}

class _AddOptionalTreatmentsDialogState extends State<_AddOptionalTreatmentsDialog> {
  final Set<String> _selectedTreatmentIds = <String>{};
  String _searchQuery = '';

  List<Treatment> get _filteredTreatments {
    if (_searchQuery.isEmpty) {
      return widget.availableTreatments;
    }
    final query = _searchQuery.toLowerCase();
    return widget.availableTreatments.where((treatment) {
      return treatment.treatmentName.toLowerCase().contains(query) ||
             treatment.description.toLowerCase().contains(query) ||
             treatment.musclesInvolved.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(MedicalIcons.medicalServices, color: MedicalDesignSystem.primaryBrand),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Add Optional Treatments'),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search treatments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Treatment list
            Flexible(
              child: _filteredTreatments.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _searchQuery.isEmpty 
                              ? 'No optional treatments available'
                              : 'No treatments match your search',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredTreatments.length,
                      itemBuilder: (context, index) {
                        final treatment = _filteredTreatments[index];
                        final isSelected = _selectedTreatmentIds.contains(treatment.treatmentId);
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedTreatmentIds.add(treatment.treatmentId);
                              } else {
                                _selectedTreatmentIds.remove(treatment.treatmentId);
                              }
                            });
                          },
                          title: Text(
                            treatment.treatmentName,
                            style: MedicalDesignSystem.subheaderStyle.copyWith(fontSize: 14),
                          ),
                          subtitle: Text(
                            treatment.description.length > 80
                                ? '${treatment.description.substring(0, 80)}...'
                                : treatment.description,
                            style: MedicalDesignSystem.bodyStyle.copyWith(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondary: Icon(
                            MedicalIcons.medicalServices,
                            color: isSelected 
                                ? MedicalDesignSystem.primaryBrand 
                                : Colors.grey.shade400,
                          ),
                          activeColor: MedicalDesignSystem.primaryBrand,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedTreatmentIds.isEmpty
              ? null
              : () {
                  final selectedTreatments = widget.availableTreatments
                      .where((t) => _selectedTreatmentIds.contains(t.treatmentId))
                      .toList();
                  Navigator.of(context).pop(selectedTreatments);
                },
          style: MedicalDesignSystem.primaryMedicalButton,
          child: Text(
            'Add (${_selectedTreatmentIds.length})',
          ),
        ),
      ],
    );
  }
}