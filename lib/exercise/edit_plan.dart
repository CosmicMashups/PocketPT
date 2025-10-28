import 'dart:math';
import 'package:flutter/material.dart';
import '../data/rehabilitation_plan.dart';
import '../data/treatment.dart';
import '../assessment/generate_treatment.dart';
import '../data/globals.dart';
import '../core/medical_design_system.dart';
import '../data/custom_exercise_service.dart';
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

  // Medical design system colors
  static const mainColor = MedicalDesignSystem.primaryBrand;
  static const subColor = MedicalDesignSystem.brandAccent;
  static const detailColor = MedicalDesignSystem.textSecondary;

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
        onTap: () {
          // Add exercise detail view
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
    final imageController = TextEditingController(text: 'exercise.jpg');
    final videoController = TextEditingController();
    final otherMusclesController = TextEditingController();
    
    String selectedMuscle = 'Deltoids';
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
              const Text('Create Custom Exercise'),
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
                    items: const [
                      'Deltoids', 'Biceps', 'Triceps', 'Chest', 'Back',
                      'Abdominals', 'Obliques', 'Quadriceps', 'Hamstrings',
                      'Gluteals', 'Calf', 'Ankle', 'Cervical Muscle',
                      'Lower Back', 'Multifidus'
                    ].map((muscle) => DropdownMenuItem(
                      value: muscle,
                      child: Text(muscle),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMuscle = value!;
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

                  // Image Filename
                  TextFormField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Image Filename',
                      hintText: 'exercise.jpg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Video URL
                  TextFormField(
                    controller: videoController,
                    decoration: const InputDecoration(
                      labelText: 'Video URL',
                      hintText: 'https://example.com/video.mp4',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Other Muscles
                  TextFormField(
                    controller: otherMusclesController,
                    decoration: const InputDecoration(
                      labelText: 'Other Muscles',
                      hintText: 'Comma-separated list of other muscles involved',
                      border: OutlineInputBorder(),
                    ),
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
                      imageUrl: imageController.text.trim().isEmpty ? 'exercise.jpg' : imageController.text.trim(),
                      videoUrl: videoController.text.trim(),
                      otherMuscles: otherMusclesController.text.trim(),
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
            Text(
              "💊 Treatments",
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
                _isLoadingTreatments ? 'Loading...' : '',
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
    return MedicalDesignSystem.medicalCardWithHeader(
      title: treatment.treatmentName,
      icon: MedicalIcons.medicalServices,
      iconColor: MedicalDesignSystem.primaryBrand,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            treatment.description,
            style: MedicalDesignSystem.bodyStyle,
          ),
          const SizedBox(height: 16),
          MedicalDesignSystem.medicalStatusBadge(
            text: 'Pain Level: ${treatment.painLevel}',
            status: MedicalStatus.warning,
          ),
          const SizedBox(height: 16),
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
        content: Column(
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