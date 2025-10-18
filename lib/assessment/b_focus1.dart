import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assessment_data.dart';
import '../data/globals.dart';
import 'b_upperbody.dart';
import 'b_lowerbody.dart';
import 'b_core.dart';
import 'b_neck.dart';
import 'b_joints.dart';

class AssessFocus1 extends StatefulWidget {
  const AssessFocus1({super.key});

  @override
  State<AssessFocus1> createState() => _AssessFocus1State();
}

class _AssessFocus1State extends State<AssessFocus1> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const successColor = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    print('=== AssessFocus1: initState() START ===');
    print('AssessFocus1: Widget key = ${widget.key}');
    print('AssessFocus1: Widget hashCode = ${widget.hashCode}');
    print('AssessFocus1: State hashCode = ${hashCode}');
    print('AssessFocus1: Current AssessmentData.generalMuscle = "${AssessmentData.generalMuscle}"');
    print('AssessFocus1: Current UserAssess.generalMuscle = "${UserAssess.generalMuscle}"');
    print('AssessFocus1: AssessmentData instance reference = AssessmentData');
    print('AssessFocus1: UserAssess instance reference = UserAssess');
    print('AssessFocus1: initState() COMPLETED ===');
  }

  @override
  Widget build(BuildContext context) {
    print('=== AssessFocus1: build() START ===');
    print('AssessFocus1: Widget key = ${widget.key}');
    print('AssessFocus1: State hashCode = ${hashCode}');
    print('AssessFocus1: Context hashCode = ${context.hashCode}');
    print('AssessFocus1: MediaQuery size = ${MediaQuery.of(context).size}');
    print('AssessFocus1: MediaQuery padding = ${MediaQuery.of(context).padding}');
    print('AssessFocus1: Current AssessmentData.generalMuscle in build = "${AssessmentData.generalMuscle}"');
    print('AssessFocus1: Current UserAssess.generalMuscle in build = "${UserAssess.generalMuscle}"');
    print('AssessFocus1: AssessmentData instance reference = AssessmentData');
    print('AssessFocus1: UserAssess instance reference = UserAssess');
    
    try {
      print('AssessFocus1: About to call _buildPageContent()');
      final result = _buildPageContent(context);
      print('AssessFocus1: _buildPageContent() returned successfully');
      print('AssessFocus1: build() COMPLETED ===');
      return result;
    } catch (e, stackTrace) {
      print('AssessFocus1: ERROR in build() - $e');
      print('AssessFocus1: Stack trace: $stackTrace');
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
    print('=== AssessFocus1: _buildPageContent() START ===');
    print('AssessFocus1: Context hashCode = ${context.hashCode}');
    print('AssessFocus1: Current AssessmentData.generalMuscle = "${AssessmentData.generalMuscle}"');
    print('AssessFocus1: Current UserAssess.generalMuscle = "${UserAssess.generalMuscle}"');
    print('AssessFocus1: Theme brightness = ${Theme.of(context).brightness}');
    print('AssessFocus1: Theme scaffold background = ${Theme.of(context).scaffoldBackgroundColor}');
    
    print('AssessFocus1: Creating Scaffold widget...');
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: null, // 🩹 Prevents internal FAB hit-test error
      appBar: AppBar(
        backgroundColor: mainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            print('=== AssessFocus1: Back button pressed ===');
            print('AssessFocus1: Context hashCode = ${context.hashCode}');
            print('AssessFocus1: Current AssessmentData.generalMuscle before navigation = "${AssessmentData.generalMuscle}"');
            print('AssessFocus1: Current UserAssess.generalMuscle before navigation = "${UserAssess.generalMuscle}"');
            print('AssessFocus1: About to call Navigator.pop()');
            Navigator.pop(context);
            print('AssessFocus1: Navigator.pop() completed successfully');
          },
        ),
        title: Text(
          "Focus Area",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              print('AssessFocus1: Refresh button pressed (disabled)');
            },
            icon: const Icon(Icons.refresh, color: Colors.transparent),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top content that should not scroll (if any). In your case we don't have separate top,
            // so we can just put the scrollable in Expanded.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  print('AssessFocus1: LayoutBuilder constraints = $constraints');
                  print('AssessFocus1: Available height = ${constraints.maxHeight}');
                  print('AssessFocus1: Available width = ${constraints.maxWidth}');
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        minWidth: constraints.maxWidth,
                      ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    // Progress Section
                    Builder(
                      builder: (context) {
                        print('AssessFocus1: About to build progress section');
                        final progressSection = _buildProgressSection(2, 8, "Focus Area");
                        print('AssessFocus1: Progress section built successfully');
                        return progressSection;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Question Section
                    Builder(
                      builder: (context) {
                        print('AssessFocus1: About to build question section');
                        final questionSection = _buildQuestionSection(
                          "Which muscle group are you focusing on?",
                          "Select the primary muscle group or area you want to work on during your rehabilitation.",
                          Icons.accessibility_new,
                        );
                        print('AssessFocus1: Question section built successfully');
                        return questionSection;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Muscle Region Options
                    Builder(
                      builder: (context) {
                        print('AssessFocus1: About to build Upper Body option');
                        final upperBody = _buildMuscleRegionOption(
                          'Upper Body',
                          'Shoulders, arms, and hands',
                          'assets/images/muscle_region/upper_body.png',
                          Icons.accessibility_new,
                          mainColor,
                        );
                        print('AssessFocus1: Upper Body option built successfully');
                        return upperBody;
                      },
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        print('AssessFocus1: About to build Lower Body option');
                        final lowerBody = _buildMuscleRegionOption(
                          'Lower Body',
                          'Hips, legs, and feet',
                          'assets/images/muscle_region/lower_body.png',
                          Icons.directions_run,
                          subColor,
                        );
                        print('AssessFocus1: Lower Body option built successfully');
                        return lowerBody;
                      },
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        print('AssessFocus1: About to build Core option');
                        final core = _buildMuscleRegionOption(
                          'Core',
                          'Abdominals and back muscles',
                          'assets/images/muscle_region/core.png',
                          Icons.fitness_center,
                          successColor,
                        );
                        print('AssessFocus1: Core option built successfully');
                        return core;
                      },
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        print('AssessFocus1: About to build Neck & Upper Back option');
                        final neck = _buildMuscleRegionOption(
                          'Neck & Upper Back',
                          'Cervical and thoracic spine',
                          'assets/images/muscle_region/neck.png',
                          Icons.healing,
                          const Color(0xFF8B5CF6),
                        );
                        print('AssessFocus1: Neck & Upper Back option built successfully');
                        return neck;
                      },
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        print('AssessFocus1: About to build Joints option');
                        final joints = _buildMuscleRegionOption(
                          'Joints',
                          'Knees, elbows, and other joints',
                          'assets/images/muscle_region/joints.png',
                          Icons.settings,
                          const Color(0xFFF59E0B),
                        );
                        print('AssessFocus1: Joints option built successfully');
                        return joints;
                      },
                    ),

                    // bottom spacing
                    const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a progress section widget
  Widget _buildProgressSection(int currentStep, int totalSteps, String stepName) {
    print('=== AssessFocus1: _buildProgressSection() START ===');
    print('AssessFocus1: currentStep = $currentStep, totalSteps = $totalSteps, stepName = "$stepName"');
    print('AssessFocus1: About to create Container for progress section');
    
    try {
      final container = Container(
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
      print('AssessFocus1: Progress section Container created successfully');
      print('AssessFocus1: _buildProgressSection() COMPLETED ===');
      return container;
    } catch (e, stackTrace) {
      print('AssessFocus1: ERROR in _buildProgressSection() - $e');
      print('AssessFocus1: Stack trace: $stackTrace');
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text('Error building progress section: $e', style: const TextStyle(color: Colors.red)),
      );
    }
  }

  // Build a question section widget
  Widget _buildQuestionSection(String title, String description, IconData icon) {
    print('=== AssessFocus1: _buildQuestionSection() START ===');
    print('AssessFocus1: title = "$title", description = "$description", icon = $icon');
    print('AssessFocus1: About to create Container for question section');
    
    try {
      final container = Container(
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
      print('AssessFocus1: Question section Container created successfully');
      print('AssessFocus1: _buildQuestionSection() COMPLETED ===');
      return container;
    } catch (e, stackTrace) {
      print('AssessFocus1: ERROR in _buildQuestionSection() - $e');
      print('AssessFocus1: Stack trace: $stackTrace');
      return Container(
        padding: const EdgeInsets.all(24),
        child: Text('Error building question section: $e', style: const TextStyle(color: Colors.red)),
      );
    }
  }


  Widget _buildMuscleRegionOption(String title, String description, String imagePath, IconData icon, Color color) {
    print('=== AssessFocus1: _buildMuscleRegionOption() START ===');
    print('AssessFocus1: title = "$title"');
    print('AssessFocus1: description = "$description"');
    print('AssessFocus1: imagePath = "$imagePath"');
    print('AssessFocus1: icon = $icon');
    print('AssessFocus1: color = $color');
    print('AssessFocus1: Current AssessmentData.generalMuscle = "${AssessmentData.generalMuscle}"');
    print('AssessFocus1: Current UserAssess.generalMuscle = "${UserAssess.generalMuscle}"');
    print('AssessFocus1: Comparing with title: "$title"');
    
    final isSelected = AssessmentData.generalMuscle == title;
    print('AssessFocus1: isSelected = $isSelected');
    print('AssessFocus1: About to create Container for muscle region option');
    
    try {
      print('AssessFocus1: Creating Container for muscle option: "$title"');
      print('AssessFocus1: Container constraints - isSelected: $isSelected, color: $color');
      
      final container = Container(
        constraints: const BoxConstraints(
          minHeight: 80,
        ),
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
          print('=== AssessFocus1: Muscle region option TAPPED ===');
          print('AssessFocus1: Tapped title = "$title"');
          print('AssessFocus1: Context hashCode = ${context.hashCode}');
          print('AssessFocus1: Widget mounted = $mounted');
          print('AssessFocus1: Before setState - AssessmentData.generalMuscle = "${AssessmentData.generalMuscle}"');
          print('AssessFocus1: Before setState - UserAssess.generalMuscle = "${UserAssess.generalMuscle}"');

          // Update state immediately (safe)
          print('AssessFocus1: About to call setState()');
          setState(() {
            print('AssessFocus1: Inside setState - setting AssessmentData.generalMuscle to: "$title"');
            AssessmentData.generalMuscle = title;
            print('AssessFocus1: Inside setState - AssessmentData.generalMuscle is now: "${AssessmentData.generalMuscle}"');
            
            print('AssessFocus1: Inside setState - setting UserAssess.generalMuscle to: "$title"');
            UserAssess.generalMuscle = title;
            print('AssessFocus1: Inside setState - UserAssess.generalMuscle is now: "${UserAssess.generalMuscle}"');
          });
          print('AssessFocus1: setState() completed successfully');

          print('AssessFocus1: About to call AssessmentData.printData()');
          AssessmentData.printData();

          // Small delay for UI feedback (optional)
          print('AssessFocus1: About to wait for 120ms delay');
          await Future.delayed(const Duration(milliseconds: 120));
          print('AssessFocus1: Delay completed');

          // Only navigate if widget is still mounted
          print('AssessFocus1: Checking if widget is still mounted: $mounted');
          if (!mounted) {
            print('AssessFocus1: Widget unmounted before navigation, skipping.');
            return;
          }

          print('AssessFocus1: About to navigate to next page based on selection: "$title"');
          switch (title) {
            case 'Upper Body':
              print('AssessFocus1: Navigating to AssessUpperBody');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessUpperBody()));
              break;
            case 'Lower Body':
              print('AssessFocus1: Navigating to AssessLowerBody');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessLowerBody()));
              break;
            case 'Core':
              print('AssessFocus1: Navigating to AssessCore');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessCore()));
              break;
            case 'Neck & Upper Back':
              print('AssessFocus1: Navigating to AssessNeck');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessNeck()));
              break;
            case 'Joints':
              print('AssessFocus1: Navigating to AssessJoints');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessJoints()));
              break;
          }
          print('AssessFocus1: Navigation completed successfully');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Builder(
            builder: (context) {
              print('AssessFocus1: Building Row for muscle option: "$title"');
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                child: IntrinsicHeight(
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
              );
            },
          ),
        ),
      ),
      );
      print('AssessFocus1: Muscle region option Container created successfully for: "$title"');
      print('AssessFocus1: _buildMuscleRegionOption() COMPLETED ===');
      return container;
    } catch (e, stackTrace) {
      print('AssessFocus1: ERROR in _buildMuscleRegionOption() for "$title" - $e');
      print('AssessFocus1: Stack trace: $stackTrace');
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text('Error building muscle region option "$title": $e', style: const TextStyle(color: Colors.red)),
      );
    }
  }
}