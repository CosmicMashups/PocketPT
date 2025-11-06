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

  // Muscle image paths mapping
  static const Map<String, String> muscleImages = {
    'Abdominals': 'assets/images/muscle/abdominals.png',
    'Ankle': 'assets/images/muscle/ankle.png',
    'Biceps': 'assets/images/muscle/biceps.png',
    'Calf': 'assets/images/muscle/ankle.png',
    'Cervical Muscle': 'assets/images/muscle/neck_muscles.png',
    'Chest': 'assets/images/muscle/chest.png',
    'Deltoids': 'assets/images/muscle/deltoids.png',
    'Diaphragm': 'assets/images/muscle/chest.png',
    'Gluteals': 'assets/images/muscle/glutes.png',
    'Hamstrings': 'assets/images/muscle/hamstrings.png',
    'Lower Back': 'assets/images/muscle/lower_back.png',
    'Multifidus': 'assets/images/muscle/lower_back.png',
    'Obliques': 'assets/images/muscle/obliques.png',
    'Quadriceps': 'assets/images/muscle/quadriceps.png',
    'Triceps': 'assets/images/muscle/triceps.png',
  };

  // Muscle descriptions mapping
  static const Map<String, String> muscleDescriptions = {
    'Abdominals': 'Muscles in the front of the abdomen that support trunk movement and maintain posture.',
    'Ankle': 'Joints and muscles in the ankle region that support foot movement and stability.',
    'Biceps': 'Front upper arm muscles responsible for elbow flexion and forearm rotation.',
    'Calf': 'Lower leg muscles (gastrocnemius and soleus) that control foot movement and walking.',
    'Cervical Muscle': 'Neck muscles that support head movement and cervical spine stability.',
    'Chest': 'Pectoral muscles that control arm movement across the body and shoulder stability.',
    'Deltoids': 'Shoulder muscles that control arm abduction, flexion, and rotation.',
    'Diaphragm': 'Primary breathing muscle separating chest and abdomen, essential for respiration.',
    'Gluteals': 'Buttock muscles (gluteus maximus, medius, minimus) that control hip movement and stability.',
    'Hamstrings': 'Back thigh muscles that control knee flexion and hip extension.',
    'Lower Back': 'Muscles supporting spinal stability and helping with trunk extension.',
    'Multifidus': 'Deep spinal muscles that stabilize vertebrae during movement.',
    'Obliques': 'Side abdominal muscles that assist in trunk rotation and lateral flexion.',
    'Quadriceps': 'Front thigh muscles that control knee extension and hip flexion.',
    'Triceps': 'Back upper arm muscles responsible for elbow extension.',
  };

  List<String> selectedMuscles = [];
  Map<String, int> musclePainLevels = {}; // muscle name -> pain level (0-10)

  @override
  void initState() {
    super.initState();
    print('AssessMuscle: initState() called');
    print('AssessMuscle: Current AssessmentData.injuredMuscles = "${AssessmentData.injuredMuscles}"');
    print('AssessMuscle: Current UserAssess.injuredMuscles = "${UserAssess.injuredMuscles}"');
    print('AssessMuscle: Primary selected muscle (from b_*.dart): "${AssessmentData.specificMuscle}"');
    
    // Initialize from existing data
    selectedMuscles = List.from(UserAssess.injuredMuscles);
    // Initialize pain levels from existing data (0-10 scale)
    musclePainLevels = Map.from(UserAssess.musclePainLevels);
    // If no pain levels exist, default to 5 (moderate) for existing selections
    for (String muscle in selectedMuscles) {
      if (!musclePainLevels.containsKey(muscle)) {
        musclePainLevels[muscle] = 5; // Default to moderate pain
      }
    }
    
    print('AssessMuscle: selectedMuscles initialized to: $selectedMuscles');
    print('AssessMuscle: musclePainLevels initialized to: $musclePainLevels');
    print('AssessMuscle: initState() completed');
  }

  // Get available muscles excluding the primary selected muscle from b_*.dart
  List<String> getAvailableMuscles() {
    final primaryMuscle = AssessmentData.specificMuscle;
    if (primaryMuscle.isEmpty) {
      return List.from(availableMuscles);
    }
    // Filter out the primary selected muscle
    return availableMuscles.where((muscle) => muscle != primaryMuscle).toList();
  }

  @override
  Widget build(BuildContext context) {
    print('AssessMuscle: build() called');
    print('AssessMuscle: Current selectedMuscles = $selectedMuscles');
    print('AssessMuscle: Current musclePainLevels = $musclePainLevels');
    
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
    final availableMuscleList = getAvailableMuscles();
    
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
          if (AssessmentData.specificMuscle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Note: ${AssessmentData.specificMuscle} is already selected as your primary muscle and excluded from this list.",
              style: GoogleFonts.ptSans(
                fontSize: 12,
                color: detailColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...availableMuscleList.map((muscle) {
            final isSelected = selectedMuscles.contains(muscle);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMuscleCard(muscle, isSelected),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMuscleCard(String muscle, bool isSelected) {
    final imagePath = muscleImages[muscle];
    final description = muscleDescriptions[muscle] ?? 'No description available.';
    final icon = muscleIcons[muscle] ?? Icons.fitness_center;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? mainColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? mainColor : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedMuscles.remove(muscle);
              musclePainLevels.remove(muscle);
            } else {
              selectedMuscles.add(muscle);
              musclePainLevels[muscle] = 5; // Default to moderate pain (5)
            }
          });
          _updateDataModels();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Image
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? mainColor : mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imagePath != null
                    ? SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(icon, color: isSelected ? Colors.white : mainColor, size: 24);
                          },
                        ),
                      )
                    : Icon(icon, color: isSelected ? Colors.white : mainColor, size: 24),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      muscle,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? mainColor : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        color: isSelected ? mainColor.withOpacity(0.8) : detailColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Selection indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: mainColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
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
            "Rate Pain Level for Each Injured Muscle",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "On a scale of 0-10, rate the current pain level for each selected muscle (0 = no pain, 10 = unbearable pain).",
            style: GoogleFonts.ptSans(
              fontSize: 14,
              color: detailColor,
            ),
          ),
          const SizedBox(height: 16),
          ...selectedMuscles.map((muscle) => _buildMusclePainSlider(muscle)),
        ],
      ),
    );
  }

  Widget _buildMusclePainSlider(String muscle) {
    final painLevel = musclePainLevels[muscle] ?? 5;
    final color = _getPainColor(painLevel);
    final category = _getCategoricalPainLevel(painLevel);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
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
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  muscle,
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$painLevel',
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.ptSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Pain level slider (similar to c_painlevel.dart)
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.3),
              thumbColor: color,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayColor: color.withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackHeight: 6,
            ),
            child: Slider(
              value: painLevel.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$painLevel',
              onChanged: (value) {
                setState(() {
                  musclePainLevels[muscle] = value.round();
                });
                _updateDataModels();
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 - No pain',
                style: GoogleFonts.ptSans(
                  fontSize: 11,
                  color: detailColor,
                ),
              ),
              Text(
                '10 - Unbearable',
                style: GoogleFonts.ptSans(
                  fontSize: 11,
                  color: detailColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPainColor(int level) {
    if (level <= 2) return successColor;
    if (level <= 4) return const Color(0xFFF59E0B);
    if (level <= 6) return const Color(0xFFC24A4A);
    if (level <= 8) return mainColor;
    return const Color(0xFFEF4444);
  }

  String _getCategoricalPainLevel(int level) {
    if (level <= 3) return "Low";
    if (level <= 6) return "Moderate";
    return "Severe";
  }


  void _updateDataModels() {
    print('AssessMuscle: Updating data models');
    print('AssessMuscle: selectedMuscles = $selectedMuscles');
    print('AssessMuscle: musclePainLevels = $musclePainLevels');
    
    // Update UserAssess with all selected muscles and their pain levels (0-10)
    UserAssess.injuredMuscles = List.from(selectedMuscles);
    UserAssess.musclePainLevels = Map.from(musclePainLevels);
    
    // Calculate pain categories based on pain levels
    UserAssess.musclePainCategories.clear();
    for (String muscle in selectedMuscles) {
      final painLevel = musclePainLevels[muscle] ?? 5;
      if (painLevel <= 3) {
        UserAssess.musclePainCategories[muscle] = "Low";
      } else if (painLevel <= 6) {
        UserAssess.musclePainCategories[muscle] = "Moderate";
      } else {
        UserAssess.musclePainCategories[muscle] = "Severe";
      }
    }
    
    // Update muscleStillPainful for compatibility (pain level > 0 means still painful)
    UserAssess.muscleStillPainful.clear();
    for (String muscle in selectedMuscles) {
      UserAssess.muscleStillPainful[muscle] = (musclePainLevels[muscle] ?? 0) > 0;
    }
    
    // Update AssessmentData
    AssessmentData.injuredMuscles = List.from(UserAssess.injuredMuscles);
    AssessmentData.musclePainLevels = Map.from(UserAssess.musclePainLevels);
    AssessmentData.musclePainCategories = Map.from(UserAssess.musclePainCategories);
    AssessmentData.muscleStillPainful = Map.from(UserAssess.muscleStillPainful);
    
    print('AssessMuscle: Updated UserAssess.musclePainLevels = ${UserAssess.musclePainLevels}');
    print('AssessMuscle: Updated UserAssess.musclePainCategories = ${UserAssess.musclePainCategories}');
    print('AssessMuscle: Updated AssessmentData.musclePainLevels = ${AssessmentData.musclePainLevels}');
  }

  Future<void> _saveDataAndNavigate() async {
    print('AssessMuscle: Saving data and navigating to summary');
    _updateDataModels();
    
    // Save to Hive
    try {
      await UserAssess.saveToHive();
      print('AssessMuscle: Data saved to Hive successfully');
    } catch (e) {
      print('AssessMuscle: Error saving to Hive: $e');
    }
    
    // Save to Firebase assessment collection
    try {
      await UserAssess.saveToFirebase();
      print('AssessMuscle: Data saved to Firebase successfully');
    } catch (e) {
      print('AssessMuscle: Error saving to Firebase: $e');
    }
    
    if (mounted) {
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
}
