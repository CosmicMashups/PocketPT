import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../data/rehabilitation_plan.dart';
import '../main.dart';
import '../data/treatment.dart';
import 'generate_treatment.dart';
import '../data/globals.dart';
import '../data/data_persistence_service.dart';
import '../data/guest_mode_service.dart';
import '../widgets/loading_indicator.dart';
import 'assessment_data.dart';

class GeneratePlanPage extends StatefulWidget {
  const GeneratePlanPage({super.key});

  @override
  State<GeneratePlanPage> createState() => _GeneratePlanPageState();
}

class _GeneratePlanPageState extends State<GeneratePlanPage> {
  bool _isLoading = false;
  RehabilitationPlan? _rehabPlan;
  List<TreatmentReference>? _treatmentReferences;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('=== GeneratePlan: initState() START ===');
    print('GeneratePlan: Widget mounted = $mounted');
    print('GeneratePlan: Context hashCode = ${context.hashCode}');
    print('GeneratePlan: Current AssessmentData values:');
    AssessmentData.printData();
    print('GeneratePlan: Current UserAssess values:');
    print('GeneratePlan: UserAssess.rehabGoal = "${UserAssess.rehabGoal}"');
    print('GeneratePlan: UserAssess.generalMuscle = "${UserAssess.generalMuscle}"');
    print('GeneratePlan: UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
    print('GeneratePlan: UserAssess.painScale = ${UserAssess.painScale}');
    print('GeneratePlan: UserAssess.painLevel = "${UserAssess.painLevel}"');
    print('GeneratePlan: UserAssess.painType = "${UserAssess.painType}"');
    print('GeneratePlan: UserAssess.painDuration = "${UserAssess.painDuration}"');
    print('GeneratePlan: UserAssess.isInjured = ${UserAssess.isInjured}');
    print('GeneratePlan: UserAssess.isAssessed = ${UserAssess.isAssessed}');
    
    // Automatically start plan generation when the page loads
    print('GeneratePlan: Starting automatic plan generation');
    _loadPlan();
    
    print('GeneratePlan: initState() COMPLETED ===');
  }

  Future<void> _loadPlan() async {
    print('=== GeneratePlan: _loadPlan() START ===');
    print('GeneratePlan: Widget mounted = $mounted');
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Set the treatment parameters based on user assessment
      print('GeneratePlan: Setting UserRehabilitation parameters from UserAssess');
      print('GeneratePlan: UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
      print('GeneratePlan: UserAssess.painLevel = "${UserAssess.painLevel}"');
      print('GeneratePlan: UserAssess.painDuration = "${UserAssess.painDuration}"');
      
      UserRehabilitation.instance.selectedMuscle = UserAssess.specificMuscle;
      UserRehabilitation.instance.selectedPainLevel = UserAssess.painLevel;
      UserRehabilitation.instance.selectedPainDuration = UserAssess.painDuration;

      final selectedPainLevel = UserRehabilitation.instance.selectedPainLevel;
      final selectedPainDuration = UserRehabilitation.instance.selectedPainDuration;
      
      print('GeneratePlan: Selected pain level = "$selectedPainLevel"');
      print('GeneratePlan: Selected pain duration = "$selectedPainDuration"');

      RehabilitationPlan? plan;

      // Only generate plan if condition is not met
      if (selectedPainLevel != "Severe" || selectedPainDuration != "Less than 48 hours ago") {
        print('GeneratePlan: Generating rehabilitation plan from CSV');
        plan = await generateRehabilitationPlanFromCSV();
        print('GeneratePlan: Plan generated: ${plan != null ? "Success" : "Failed"}');
      } else {
        print('GeneratePlan: Skipping plan generation due to severe pain/recent injury');
      }
      
      print('GeneratePlan: Generating treatment plan');
      final treatmentReferences = await generateTreatmentPlan(
        specificMuscle: UserRehabilitation.instance.selectedMuscle,
        painLevel: UserRehabilitation.instance.selectedPainLevel,
        painDuration: UserRehabilitation.instance.selectedPainDuration,
      );
      print('GeneratePlan: Treatment references generated: ${treatmentReferences?.length ?? 0} treatments');
      
      // Determine whether to show warning
      final shouldShowExerciseWarning = selectedPainLevel == "Severe" || selectedPainDuration == "Less than 48 hours ago";
      print('GeneratePlan: Should show exercise warning = $shouldShowExerciseWarning');

      if (shouldShowExerciseWarning) {
        print('GeneratePlan: Showing exercise warning state');
        setState(() {
          _treatmentReferences = treatmentReferences;
          _rehabPlan = null;
          _isLoading = false;
        });
        UserRehabilitation.instance.treatmentReferences = treatmentReferences;
        // Persist current treatment recommendations (IDs) for consistency across sessions
        await UserRehabilitation.instance.savePlansToHive();
        await UserRehabilitation.instance.savePlansToFirebase();
      } else if (plan == null && (treatmentReferences == null || treatmentReferences.isEmpty)) {
        print('GeneratePlan: Showing error state - no matching exercises/treatments');
        setState(() {
          _error = "⚠️ Not enough matching exercises or treatments found.";
          _rehabPlan = null;
          _treatmentReferences = null;
          _isLoading = false;
        });
        // Keep plans only in memory for now (no persistence here)
      } else {
        print('GeneratePlan: Showing successful plan state');
        UserRehabilitation.instance.rehabPlans = plan != null ? [plan] : [];
        setState(() {
          _rehabPlan = plan;
          _treatmentReferences = treatmentReferences;
          _error = null;
          _isLoading = false;
        });
        UserRehabilitation.instance.treatmentReferences = treatmentReferences;
        // Persist plan exercises (IDs) and treatments (IDs) to both Hive and Firebase
        await UserRehabilitation.instance.savePlansToHive();
        await UserRehabilitation.instance.savePlansToFirebase();
      }
      
      print('GeneratePlan: _loadPlan() COMPLETED successfully');
    } catch (e, stackTrace) {
      print('GeneratePlan: ERROR in _loadPlan() - $e');
      print('GeneratePlan: Stack trace: $stackTrace');
      setState(() {
        _error = "❌ An error occurred: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('=== GeneratePlan: build() START ===');
    print('GeneratePlan: Widget mounted = $mounted');
    print('GeneratePlan: Context hashCode = ${context.hashCode}');
    print('GeneratePlan: _isLoading = $_isLoading');
    print('GeneratePlan: _error = $_error');
    print('GeneratePlan: _rehabPlan = ${_rehabPlan != null ? 'Present' : 'Null'}');
    print('GeneratePlan: _treatmentReferences = ${_treatmentReferences?.length ?? 0} treatments');
    
    try {
      final scaffold = Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8B2E2E)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Your Treatment Plan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : _buildPlanUI(),
      ),
    );
    
    print('GeneratePlan: Scaffold built successfully');
    print('GeneratePlan: build() COMPLETED ===');
    return scaffold;
    } catch (e, stackTrace) {
      print('GeneratePlan: ERROR in build() - $e');
      print('GeneratePlan: Stack trace: $stackTrace');
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: Text('Error building page: $e', style: const TextStyle(color: Colors.red)),
          ),
        ),
      );
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: LoadingIndicator(
        message: 'Generating Your Treatment Plan',
        size: 60,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Unable to Generate Plan",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B2E2E), Color(0xFFC24A4A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B2E2E).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  print('=== GeneratePlan: Try Again button TAPPED ===');
                  print('GeneratePlan: Widget mounted = $mounted');
                  print('GeneratePlan: Context hashCode = ${context.hashCode}');
                  
                  if (!mounted) {
                    print('GeneratePlan: Widget unmounted, skipping reload');
                    return;
                  }
                  
                  print('GeneratePlan: About to reload plan');
                  _loadPlan();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Try Again",
                      style: GoogleFonts.ptSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B2E2E), Color(0xFFC24A4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B2E2E).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Personalized Treatment Plan',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Week ${_rehabPlan?.weekNumber ?? 1} • ${UserAssess.specificMuscle}',
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Treatments Section
                if (_treatmentReferences != null && _treatmentReferences!.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B2E2E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.medical_services,
                                color: Color(0xFF8B2E2E),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Recommended Treatments',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                            return Column(
                              children: treatments.map((t) => _buildTreatmentCard(t)).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                // Exercises Section
                if (_rehabPlan != null && _rehabPlan!.exerciseReferences.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Color(0xFF10B981),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Recommended Exercises',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Exercise>>(
                          future: _rehabPlan!.getExercises(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text('Error loading exercises: ${snapshot.error}');
                            }
                            final exercises = snapshot.data ?? [];
                            return Column(
                              children: exercises.map((e) => _buildExerciseCard(e)).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                // Bottom Action Button
                Container(
                  margin: const EdgeInsets.only(top: 32, bottom: 32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B2E2E), Color(0xFFC24A4A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B2E2E).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      print('=== GeneratePlan: Complete Assessment button TAPPED ===');
                      print('GeneratePlan: Widget mounted = $mounted');
                      print('GeneratePlan: Context hashCode = ${context.hashCode}');
                      
                      if (!mounted) {
                        print('GeneratePlan: Widget unmounted, skipping completion');
                        return;
                      }
                      
                      try {
                        print('GeneratePlan: Setting assessment completion state');
                        // Ensure assessment completion state is set and persisted
                        UserDetails.hasCompletedAssessment = true;
                        await UserDetails.markAssessmentCompleted();
                        // Mark assessment flow as completed locally as well
                        UserAssess.isAssessed = true;
                        await UserAssess.saveToHive();
                        print('GeneratePlan: Assessment completion state set');
                        
                        print('GeneratePlan: Persisting rehab plans/treatments');
                        // Persist rehab plans/treatments immediately
                        await UserRehabilitation.instance.savePlansToHive();
                        await UserRehabilitation.instance.savePlansToFirebase();
                        print('GeneratePlan: Rehab plans persisted');
                        
                        print('GeneratePlan: Setting active program');
                        // Ensure an active program is recorded
                        if (ActiveProgram.startDate == null) {
                          ActiveProgram.startDate = DateTime.now();
                          await ActiveProgram.saveToHive();
                        }
                        await saveAllDataToHive();
                        print('GeneratePlan: Active program set');
                        
                        print('GeneratePlan: Handling data persistence');
                        // Handle guest mode data saving
                        if (UserDetails.isGuest) {
                          final guestModeService = GuestModeService.instance;
                          await guestModeService.forceSaveAllData();
                        } else {
                          await DataPersistenceService.instance.forceSave(reason: 'Assessment completed');
                        }
                        print('GeneratePlan: Data persistence completed');
                        
                        print('GeneratePlan: Saving completion flag to Hive');
                        // Save flag eagerly to Hive to ensure AuthWrapper sees it on cold start
                        try {
                          final box = Hive.box('rehabBox');
                          await box.put('hasCompletedAssessment', true);
                        } catch (_) {}
                        print('GeneratePlan: Completion flag saved');

                        if (!mounted) {
                          print('GeneratePlan: Widget unmounted before navigation');
                          return;
                        }

                        print('GeneratePlan: Navigating to AuthWrapper');
                        // Navigate to wrapper (routes to Home or Assess depending on flags)
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const AuthWrapper()),
                          (Route<dynamic> route) => false,
                        );
                        print('GeneratePlan: Navigation completed');
                      } catch (e, stackTrace) {
                        print('GeneratePlan: ERROR in completion handler - $e');
                        print('GeneratePlan: Stack trace: $stackTrace');
                        
                        if (!mounted) return;
                        
                        // Provide more specific error messages
                        String errorMessage = 'Assessment completed locally. Some data may not sync.';
                        if (e.toString().contains('permission-denied')) {
                          errorMessage = 'Assessment completed locally. Data will sync when connection improves.';
                        } else if (e.toString().contains('network')) {
                          errorMessage = 'Network error. Assessment saved locally.';
                        } else if (e.toString().contains('timeout')) {
                          errorMessage = 'Request timed out. Assessment saved locally.';
                        } else if (e.toString().contains('authentication') || e.toString().contains('auth')) {
                          errorMessage = 'Assessment completed locally. Data will sync when connection improves.';
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'Continue',
                              textColor: Colors.white,
                              onPressed: () {
                                // Navigate anyway since local data is saved
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                                  (Route<dynamic> route) => false,
                                );
                              },
                            ),
                          ),
                        );
                        
                        // Auto-navigate after a delay if user doesn't interact
                        Future.delayed(const Duration(seconds: 5), () {
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const AuthWrapper()),
                              (Route<dynamic> route) => false,
                            );
                          }
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.home, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Complete Assessment & Go Home',
                          style: GoogleFonts.ptSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 24,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise.sets} sets • ${exercise.repetitions} reps',
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              exercise.description,
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.accessibility_new, 'Target Muscle', exercise.muscle),
                  _buildDetailRow(Icons.favorite, 'Pain Level', exercise.painLevel),
                  _buildDetailRow(Icons.flag, 'Goal', exercise.goal),
                  if (exercise.videoUrl.isNotEmpty)
                    _buildDetailRow(Icons.ondemand_video, 'Video Guide', exercise.videoUrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentCard(Treatment treatment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B2E2E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    size: 24,
                    color: Color(0xFF8B2E2E),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    treatment.treatmentName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              treatment.description,
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.accessibility_new, 'Target Muscles', treatment.musclesInvolved),
                  _buildDetailRow(Icons.health_and_safety, 'Pain Level', treatment.painLevel),
                  _buildDetailRow(Icons.timer, 'Pain Duration', treatment.painDuration),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.ptSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.ptSans(
                fontSize: 13,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}