// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import 'assessment_data.dart';
// Sync removed for assessment (local-only)
// removed unused import
import 'c_paintype.dart';

class AssessPainLevel extends StatefulWidget {
  const AssessPainLevel({super.key});

  @override
  State<AssessPainLevel> createState() => _AssessPainLevelState();
}

class _AssessPainLevelState extends State<AssessPainLevel> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  // static const subColor = Color(0xFFC24A4A); // Removed as not used in categorical version
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const successColor = Color(0xFF10B981);

  int selectedPainLevel = 0;

  @override
  void initState() {
    super.initState();
    print('AssessPainLevel: initState() called');
    print('AssessPainLevel: Current AssessmentData.painScale = "${AssessmentData.painScale}"');
    print('AssessPainLevel: Current UserAssess.painScale = "${UserAssess.painScale}"');
    
    // Initialize selectedPainLevel from local data
    selectedPainLevel = UserAssess.painScale;
    print('AssessPainLevel: selectedPainLevel initialized to: $selectedPainLevel');
    print('AssessPainLevel: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('AssessPainLevel: build() called');
    print('AssessPainLevel: Current AssessmentData.painScale in build = "${AssessmentData.painScale}"');
    print('AssessPainLevel: Current UserAssess.painScale in build = "${UserAssess.painScale}"');
    print('AssessPainLevel: Current selectedPainLevel = $selectedPainLevel');
    
    try {
      return _buildPageContent(context);
    } catch (e) {
      print('AssessPainLevel: ERROR in build() - $e');
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
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    "Pain Level",
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
                    _buildProgressSection(4, 8, "Pain Level Assessment"),
                    
                    const SizedBox(height: 24),

                    // Question Section
                    _buildQuestionSection(
                      "Pain Intensity",
                      "On a scale of 0-10, how would you rate your current pain level?",
                      Icons.sentiment_neutral,
                    ),

                    const SizedBox(height: 24),

                    // Pain Scale
                    _buildPainScale(),

                    const SizedBox(height: 24),

                    // Pain Level Description
                    if (selectedPainLevel > 0) _buildPainDescription(),

                    const SizedBox(height: 32),

                    // Next Button
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
                        onPressed: selectedPainLevel > 0 ? () {
            Navigator.push(
              context,
              PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => AssessPainType(),
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
                        } : null,
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

  // Build a progress section widget
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

  // Build a question section widget
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

  Widget _buildPainScale() {
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
        children: [
          // Pain scale header
          Text(
            "Select your pain level:",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // Pain scale numbers (0-10)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(11, (index) {
              final isSelected = selectedPainLevel == index;
              return GestureDetector(
                onTap: () {
                  print('AssessPainLevel: Pain level tapped - index: $index');
                  print('AssessPainLevel: Before setState - AssessmentData.painScale = "${AssessmentData.painScale}"');
                  print('AssessPainLevel: Before setState - UserAssess.painScale = "${UserAssess.painScale}"');
                  
                  setState(() {
                    selectedPainLevel = index;
                    UserAssess.painScale = index;
                    AssessmentData.painScale = index;
                    
                    // Set categorical pain level for filtering
                    UserAssess.painLevel = _getCategoricalPainLevel(index);
                  });
                  
                  print('AssessPainLevel: Selected pain level: $index');
                  print('AssessPainLevel: Categorical pain level: ${_getCategoricalPainLevel(index)}');
                  print('AssessPainLevel: Final AssessmentData.painScale = "${AssessmentData.painScale}"');
                  print('AssessPainLevel: Final UserAssess.painScale = "${UserAssess.painScale}"');
                  print('AssessPainLevel: Final UserAssess.painLevel = "${UserAssess.painLevel}"');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? _getPainColor(index) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _getPainColor(index) : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: _getPainColor(index).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : detailColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Pain scale labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "No Pain",
                style: GoogleFonts.ptSans(
                  fontSize: 12,
                  color: detailColor,
                ),
              ),
              Text(
                "Severe Pain",
                style: GoogleFonts.ptSans(
                  fontSize: 12,
                  color: detailColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Categorical indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryIndicator("Low", 0, 3),
              _buildCategoryIndicator("Moderate", 4, 6),
              _buildCategoryIndicator("Severe", 7, 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIndicator(String category, int startRange, int endRange) {
    final isInRange = selectedPainLevel >= startRange && selectedPainLevel <= endRange;
    final color = _getPainColorFromLevel(_getCategoricalPainLevel(selectedPainLevel));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isInRange ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInRange ? color : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Text(
        category,
        style: GoogleFonts.ptSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isInRange ? color : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildPainDescription() {
    final description = _getPainDescription(selectedPainLevel);
    final color = _getPainColor(selectedPainLevel);
    final categoricalLevel = _getCategoricalPainLevel(selectedPainLevel);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPainIcon(selectedPainLevel),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  description,
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Category: $categoricalLevel (for exercise filtering)",
              style: GoogleFonts.ptSans(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  String _getPainDescription(int level) {
    if (level == 0) return "No pain";
    if (level <= 2) return "Mild pain - barely noticeable";
    if (level <= 4) return "Moderate pain - noticeable but manageable";
    if (level <= 6) return "Moderately severe pain - interferes with daily activities";
    if (level <= 8) return "Severe pain - makes it difficult to concentrate";
    return "Unbearable pain - bed rest required";
  }

  IconData _getPainIcon(int level) {
    if (level <= 2) return Icons.sentiment_very_satisfied;
    if (level <= 4) return Icons.sentiment_neutral;
    if (level <= 6) return Icons.sentiment_dissatisfied;
    if (level <= 8) return Icons.sentiment_very_dissatisfied;
    return Icons.sick;
  }

  // Convert numerical pain scale (0-10) to categorical for filtering
  String _getCategoricalPainLevel(int level) {
    if (level <= 3) return "Low";
    if (level <= 6) return "Moderate";
    return "Severe";
  }

  // Helper method to get color from categorical level
  Color _getPainColorFromLevel(String level) {
    switch (level) {
      case "Low":
        return successColor;
      case "Moderate":
        return const Color(0xFFF59E0B);
      case "Severe":
        return const Color(0xFFEF4444);
      default:
        return detailColor;
    }
  }
}