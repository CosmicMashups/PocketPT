import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assessment_data.dart';
import '../data/globals.dart';
import 'b_focus1.dart';
// Persistence and sync removed for assessment choices (local-only)

class AssessGoal1 extends StatefulWidget {
  const AssessGoal1({super.key});

  @override
  State<AssessGoal1> createState() => _AssessGoal1State();
}

class _AssessGoal1State extends State<AssessGoal1> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const successColor = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    print('AssessGoal1: initState() called');
    print('AssessGoal1: Current AssessmentData.rehabGoal = "${AssessmentData.rehabGoal}"');
    print('AssessGoal1: Current UserAssess.rehabGoal = "${UserAssess.rehabGoal}"');
    
    // Ensure we have a default value for rehabGoal
    if (AssessmentData.rehabGoal.isEmpty) {
      print('AssessGoal1: AssessmentData.rehabGoal is empty, setting to empty string');
      AssessmentData.rehabGoal = '';
    } else {
      print('AssessGoal1: AssessmentData.rehabGoal already has value: "${AssessmentData.rehabGoal}"');
    }
    
    print('AssessGoal1: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('AssessGoal1: build() called');
    print('AssessGoal1: Current AssessmentData.rehabGoal in build = "${AssessmentData.rehabGoal}"');
    print('AssessGoal1: Current UserAssess.rehabGoal in build = "${UserAssess.rehabGoal}"');
    
    try {
      return _buildPageContent(context);
    } catch (e) {
      print('AssessGoal1: ERROR in build() - $e');
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
    print('AssessGoal1: _buildPageContent() called');
    print('AssessGoal1: Current AssessmentData.rehabGoal in _buildPageContent = "${AssessmentData.rehabGoal}"');
    print('AssessGoal1: MediaQuery size: ${MediaQuery.of(context).size}');
    print('AssessGoal1: MediaQuery padding: ${MediaQuery.of(context).padding}');
    print('AssessGoal1: Building layout structure...');
    
    try {
      print('AssessGoal1: Creating Material widget with Column layout');
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
                  onPressed: () {
                    print('AssessGoal1: Back button pressed');
                    print('AssessGoal1: Current AssessmentData.rehabGoal before navigation = "${AssessmentData.rehabGoal}"');
                    print('AssessGoal1: Current UserAssess.rehabGoal before navigation = "${UserAssess.rehabGoal}"');
                    Navigator.pop(context);
                    print('AssessGoal1: Navigator.pop() completed');
                  },
                ),
                Expanded(
                  child: Text(
                    "Rehabilitation Goal",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Progress Section
                    _buildProgressSection(1, 8, "Goal Selection"),
                    
                    const SizedBox(height: 24),

                    // Question Section
                    _buildQuestionSection(
                      "What is your primary rehabilitation goal?",
                      "Select the goal that best describes what you want to achieve through your rehabilitation program.",
                      Icons.flag,
                    ),

                    const SizedBox(height: 24),

                    // Goal Options
                    _buildGoalOption(
                      "Alleviate Pain",
                      "Reduce or eliminate pain and discomfort",
                      Icons.healing,
                      successColor,
                    ),
                    const SizedBox(height: 16),
                    _buildGoalOption(
                      "Improve Mobility",
                      "Increase range of motion and flexibility",
                      Icons.accessibility,
                      subColor,
                    ),
                    const SizedBox(height: 16),
                    _buildGoalOption(
                      "Strengthen Muscle",
                      "Build muscle strength and endurance",
                      Icons.fitness_center,
                      mainColor,
                    ),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
    } catch (e) {
      print('AssessGoal1: ERROR in _buildPageContent - $e');
      return Container(
        color: backgroundColor,
        child: Center(
          child: Text(
            'Error loading page content\nError: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  // Build a progress section widget
  Widget _buildProgressSection(int currentStep, int totalSteps, String stepName) {
    print('AssessGoal1: _buildProgressSection() called - Step $currentStep of $totalSteps - $stepName');
    try {
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
    } catch (e) {
      print('AssessGoal1: ERROR in _buildProgressSection - $e');
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          'Error loading progress section\nError: $e',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  // Build a question section widget
  Widget _buildQuestionSection(String title, String description, IconData icon) {
    print('AssessGoal1: _buildQuestionSection() called - Title: "$title"');
    try {
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
    } catch (e) {
      print('AssessGoal1: ERROR in _buildQuestionSection - $e');
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          'Error loading question section\nError: $e',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }


  Widget _buildGoalOption(String title, String description, IconData icon, Color color) {
    print('AssessGoal1: _buildGoalOption() called for title: "$title"');
    print('AssessGoal1: Current AssessmentData.rehabGoal = "${AssessmentData.rehabGoal}"');
    print('AssessGoal1: Comparing with title: "$title"');
    
    final isSelected = AssessmentData.rehabGoal == title;
    print('AssessGoal1: isSelected = $isSelected');
    
    try {
      return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          print('AssessGoal1: Goal option tapped - "$title"');
          print('AssessGoal1: Before setState - AssessmentData.rehabGoal = "${AssessmentData.rehabGoal}"');
          print('AssessGoal1: Before setState - UserAssess.rehabGoal = "${UserAssess.rehabGoal}"');
          
          setState(() {
            print('AssessGoal1: Inside setState - setting AssessmentData.rehabGoal to: "$title"');
            AssessmentData.rehabGoal = title;
            print('AssessGoal1: Inside setState - AssessmentData.rehabGoal is now: "${AssessmentData.rehabGoal}"');
          });
          
          // Update UserAssess with the new goal
          print('AssessGoal1: Before UserAssess update - UserAssess.rehabGoal = "${UserAssess.rehabGoal}"');
          UserAssess.rehabGoal = title;
          print('AssessGoal1: After UserAssess update - UserAssess.rehabGoal = "${UserAssess.rehabGoal}"');
          
          print('AssessGoal1: Selected rehab goal: $title');
          print('AssessGoal1: Stored locally in AssessmentData/UserAssess');
          print('AssessGoal1: Final AssessmentData.rehabGoal = "${AssessmentData.rehabGoal}"');
          print('AssessGoal1: Final UserAssess.rehabGoal = "${UserAssess.rehabGoal}"');
          AssessmentData.printData();
          
          // Navigate to next page after a brief delay
          print('AssessGoal1: Waiting 300ms before navigation...');
          await Future.delayed(const Duration(milliseconds: 300));
          print('AssessGoal1: Delay completed, checking if mounted...');
          if (mounted) {
            print('AssessGoal1: Widget is mounted, navigating to AssessFocus1');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssessFocus1()),
            );
            print('AssessGoal1: Navigation completed');
          } else {
            print('AssessGoal1: Widget is not mounted, skipping navigation');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ptSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : const Color(0xFF374151),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        color: detailColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    } catch (e) {
      print('AssessGoal1: ERROR in _buildGoalOption for "$title" - $e');
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          'Error loading option: $title\nError: $e',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }
}