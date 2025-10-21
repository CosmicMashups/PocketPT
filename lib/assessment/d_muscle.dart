// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import 'assessment_data.dart';
import 'd_history.dart';
import 'e_summary.dart';

class AssessMuscle extends StatefulWidget {
  const AssessMuscle({super.key});

  @override
  State<AssessMuscle> createState() => _AssessMuscleState();
}

class _AssessMuscleState extends State<AssessMuscle> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const successColor = Color(0xFF10B981);

  // List of 15 predefined muscles
  static const List<String> availableMuscles = [
    'Abdominals',
    'Ankle',
    'Biceps',
    'Calf',
    'Cervical Muscle',
    'Chest',
    'Deltoids',
    'Diaphragm',
    'Gluteals',
    'Hamstrings',
    'Lower Back',
    'Multifidus',
    'Obliques',
    'Quadriceps',
    'Triceps',
  ];

  // Muscle icons mapping
  static const Map<String, IconData> muscleIcons = {
    'Abdominals': Icons.fitness_center,
    'Ankle': Icons.directions_walk,
    'Biceps': Icons.fitness_center,
    'Calf': Icons.directions_walk,
    'Cervical Muscle': Icons.accessibility_new,
    'Chest': Icons.fitness_center,
    'Deltoids': Icons.fitness_center,
    'Diaphragm': Icons.air,
    'Gluteals': Icons.fitness_center,
    'Hamstrings': Icons.directions_walk,
    'Lower Back': Icons.accessibility_new,
    'Multifidus': Icons.accessibility_new,
    'Obliques': Icons.fitness_center,
    'Quadriceps': Icons.directions_walk,
    'Triceps': Icons.fitness_center,
  };

  List<String> selectedMuscles = [];
  Map<String, bool> muscleStillPainful = {}; // muscle name -> still experiencing pain (true/false)

  @override
  void initState() {
    super.initState();
    print('AssessMuscle: initState() called');
    print('AssessMuscle: Current AssessmentData.injuredMuscles = "${AssessmentData.injuredMuscles}"');
    print('AssessMuscle: Current UserAssess.injuredMuscles = "${UserAssess.injuredMuscles}"');
    
    // Initialize from existing data
    selectedMuscles = List.from(UserAssess.injuredMuscles);
    // Use the new muscleStillPainful field, or convert from existing data if not available
    muscleStillPainful = Map.from(UserAssess.muscleStillPainful);
    if (muscleStillPainful.isEmpty) {
      // Convert existing pain level data to simple yes/no - if pain level > 0, consider it painful
      for (String muscle in selectedMuscles) {
        final painLevel = UserAssess.musclePainLevels[muscle] ?? 0;
        muscleStillPainful[muscle] = painLevel > 0;
      }
    }
    
    print('AssessMuscle: selectedMuscles initialized to: $selectedMuscles');
    print('AssessMuscle: muscleStillPainful initialized to: $muscleStillPainful');
    print('AssessMuscle: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('AssessMuscle: build() called');
    print('AssessMuscle: Current selectedMuscles = $selectedMuscles');
    print('AssessMuscle: Current muscleStillPainful = $muscleStillPainful');
    
    try {
      return _buildPageContent(context);
    } catch (e) {
      print('AssessMuscle: ERROR in build() - $e');
      return Container(
        color: backgroundColor,
        child: Center(
          child: Text(
            'Error loading page: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildPageContent(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: Column(
        children: [
          // Custom AppBar
          Container(
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: mainColor,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const AssessHistory(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        return SlideTransition(position: offsetAnimation, child: child);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Muscle Assessment",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, color: Colors.transparent),
                ),
              ],
            ),
          ),
          // Body Content
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Section
                    _buildProgressSection(5, 6, "Muscle Assessment"),
                    
                    const SizedBox(height: 24),

                    // Question Section
                    _buildQuestionSection(
                      "Muscle Injury Assessment",
                      "Select the muscles that have been injured and rate their current pain levels. This information helps us create a safer rehabilitation plan.",
                      Icons.medical_information,
                    ),

                    const SizedBox(height: 24),

                    // Muscle Selection
                    _buildMuscleSelection(),

                    const SizedBox(height: 24),

                    // Pain Question for Selected Muscles
                    if (selectedMuscles.isNotEmpty) _buildPainQuestionAssessment(),

                    const SizedBox(height: 32),

                    // Continue Button
                    Container(
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
                            color: mainColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          _saveDataAndNavigate();
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
                            Text(
                              "Continue Assessment",
                              style: GoogleFonts.ptSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(int currentStep, int totalSteps, String stepName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.track_changes,
              color: mainColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assessment Progress",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Step $currentStep of $totalSteps - $stepName",
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    color: detailColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(String title, String description, IconData icon) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: mainColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: detailColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleSelection() {
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
          Text(
            "Select Injured Muscles:",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableMuscles.map((muscle) {
              final isSelected = selectedMuscles.contains(muscle);
              return _buildMuscleChip(muscle, isSelected);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleChip(String muscle, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedMuscles.remove(muscle);
            muscleStillPainful.remove(muscle);
          } else {
            selectedMuscles.add(muscle);
            muscleStillPainful[muscle] = true; // Default to "yes" (still experiencing pain)
          }
        });
        _updateDataModels();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? mainColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? mainColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: mainColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              muscleIcons[muscle] ?? Icons.fitness_center,
              color: isSelected ? mainColor : detailColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              muscle,
              style: GoogleFonts.ptSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? mainColor : detailColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: mainColor,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPainQuestionAssessment() {
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
          Text(
            "Are you still experiencing noticeable pain in these muscles?",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select 'No' for muscles that no longer cause pain, 'Yes' for muscles that still cause noticeable pain.",
            style: GoogleFonts.ptSans(
              fontSize: 14,
              color: detailColor,
            ),
          ),
          const SizedBox(height: 16),
          ...selectedMuscles.map((muscle) => _buildMusclePainQuestion(muscle)),
        ],
      ),
    );
  }

  Widget _buildMusclePainQuestion(String muscle) {
    final isStillPainful = muscleStillPainful[muscle] ?? true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isStillPainful ? mainColor.withOpacity(0.1) : successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isStillPainful ? mainColor.withOpacity(0.3) : successColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                muscleIcons[muscle] ?? Icons.fitness_center,
                color: isStillPainful ? mainColor : successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                muscle,
                style: GoogleFonts.ptSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isStillPainful ? mainColor : successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      muscleStillPainful[muscle] = false;
                    });
                    _updateDataModels();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: !isStillPainful ? successColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !isStillPainful ? successColor : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: !isStillPainful ? Colors.white : detailColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "No",
                          style: GoogleFonts.ptSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !isStillPainful ? Colors.white : detailColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      muscleStillPainful[muscle] = true;
                    });
                    _updateDataModels();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isStillPainful ? mainColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isStillPainful ? mainColor : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning,
                          color: isStillPainful ? Colors.white : detailColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Yes",
                          style: GoogleFonts.ptSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isStillPainful ? Colors.white : detailColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _updateDataModels() {
    print('AssessMuscle: Updating data models');
    print('AssessMuscle: selectedMuscles = $selectedMuscles');
    print('AssessMuscle: muscleStillPainful = $muscleStillPainful');
    
    // Update UserAssess - only include muscles that are still painful
    UserAssess.injuredMuscles = selectedMuscles.where((muscle) => muscleStillPainful[muscle] == true).toList();
    UserAssess.muscleStillPainful = Map.from(muscleStillPainful);
    
    // Convert to old format for compatibility with existing systems
    UserAssess.musclePainLevels.clear();
    UserAssess.musclePainCategories.clear();
    for (String muscle in UserAssess.injuredMuscles) {
      UserAssess.musclePainLevels[muscle] = 5; // Set to moderate pain level for filtering
      UserAssess.musclePainCategories[muscle] = "Moderate"; // Set to moderate for filtering
    }
    
    // Update AssessmentData
    AssessmentData.injuredMuscles = List.from(UserAssess.injuredMuscles);
    AssessmentData.musclePainLevels = Map.from(UserAssess.musclePainLevels);
    AssessmentData.musclePainCategories = Map.from(UserAssess.musclePainCategories);
    AssessmentData.muscleStillPainful = Map.from(UserAssess.muscleStillPainful);
    
    print('AssessMuscle: Updated UserAssess.musclePainCategories = ${UserAssess.musclePainCategories}');
    print('AssessMuscle: Updated AssessmentData.musclePainCategories = ${AssessmentData.musclePainCategories}');
  }

  void _saveDataAndNavigate() {
    print('AssessMuscle: Saving data and navigating to summary');
    _updateDataModels();
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AssessSummary(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}
