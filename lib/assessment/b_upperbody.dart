// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import 'assessment_data.dart';
// Sync removed for assessment (local-only)
import 'b_focus1.dart';
import 'c_upload.dart';

class AssessUpperBody extends StatefulWidget {
  const AssessUpperBody({super.key});

  @override
  State<AssessUpperBody> createState() => _AssessUpperBodyState();
}

class _AssessUpperBodyState extends State<AssessUpperBody> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const successColor = Color(0xFF10B981);

  String specificMuscle = '';

  @override
  void initState() {
    super.initState();
    print('AssessUpperBody: initState() called');
    print('AssessUpperBody: Current AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
    print('AssessUpperBody: Current UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
    
    // Ensure we have a default value for specificMuscle
    if (AssessmentData.specificMuscle.isEmpty) {
      print('AssessUpperBody: AssessmentData.specificMuscle is empty, setting to empty string');
      AssessmentData.specificMuscle = '';
    } else {
      print('AssessUpperBody: AssessmentData.specificMuscle already has value: "${AssessmentData.specificMuscle}"');
    }
    
    // Initialize local variable
    specificMuscle = AssessmentData.specificMuscle;
    print('AssessUpperBody: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('AssessUpperBody: build() called');
    print('AssessUpperBody: Current AssessmentData.specificMuscle in build = "${AssessmentData.specificMuscle}"');
    print('AssessUpperBody: Current UserAssess.specificMuscle in build = "${UserAssess.specificMuscle}"');
    
    try {
      return _buildPageContent(context);
    } catch (e) {
      print('AssessUpperBody: ERROR in build() - $e');
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
    print('AssessUpperBody: _buildPageContent() called');
    print('AssessUpperBody: Current AssessmentData.specificMuscle in _buildPageContent = "${AssessmentData.specificMuscle}"');
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: mainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            print('AssessUpperBody: Back button pressed');
            print('AssessUpperBody: Current AssessmentData.specificMuscle before navigation = "${AssessmentData.specificMuscle}"');
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => AssessFocus1(),
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
            print('AssessUpperBody: Navigation completed');
          },
        ),
        title: Text(
          "Upper Body Muscles",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    // Progress Section
                    _buildProgressSection(2, 8, "Upper Body Muscle Selection"),
                    
                    const SizedBox(height: 24),

                    // Question Section
                    _buildQuestionSection(
                      "Muscle Selection",
                      "Select the specific upper body muscle you'd like to focus on",
                      Icons.help_outline,
                    ),

                    const SizedBox(height: 24),

                    // Muscle Options
                    _buildMuscleOption(
                      'Deltoids',
                      'The shoulder muscle connecting the arm to the torso, enabling arm movement and rotation.',
                      Icons.accessibility_new,
                      mainColor,
                    ),
                    const SizedBox(height: 16),
                    _buildMuscleOption(
                      'Biceps',
                      'Front arm muscles that flex the elbow and rotate the forearm.',
                      Icons.fitness_center,
                      subColor,
                    ),
                    const SizedBox(height: 16),
                    _buildMuscleOption(
                      'Triceps',
                      'Back arm muscles that extend the elbow and provide pushing power.',
                      Icons.sports_gymnastics,
                      successColor,
                    ),
                    const SizedBox(height: 16),
                    _buildMuscleOption(
                      'Cervical Muscle',
                      'Neck muscles that support head movement and maintain cervical spine alignment.',
                      Icons.healing,
                      const Color(0xFF8B5CF6),
                    ),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const AssessUpload(),
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

  Widget _buildMuscleOption(String title, String description, IconData icon, Color color) {
    print('AssessUpperBody: _buildMuscleOption() called for title: "$title"');
    print('AssessUpperBody: Current AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
    print('AssessUpperBody: Comparing with title: "$title"');
    
    final isSelected = specificMuscle == title;
    print('AssessUpperBody: isSelected = $isSelected');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE5E7EB),
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
          print('AssessUpperBody: Muscle option tapped - "$title"');
          print('AssessUpperBody: Before setState - AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
          print('AssessUpperBody: Before setState - UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
          
          setState(() {
            print('AssessUpperBody: Inside setState - setting AssessmentData.specificMuscle to: "$title"');
            AssessmentData.specificMuscle = title;
            print('AssessUpperBody: Inside setState - AssessmentData.specificMuscle is now: "${AssessmentData.specificMuscle}"');
            
            specificMuscle = title;
            UserAssess.specificMuscle = title;
          });
          
          print('AssessUpperBody: Selected specific muscle: $title');
          print('AssessUpperBody: Final AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
          print('AssessUpperBody: Final UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
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
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildMuscleImage(title, isSelected ? Colors.white : color),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        color: isSelected ? color.withOpacity(0.8) : detailColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
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

  Widget _buildMuscleImage(String title, Color fallbackTint) {
    final Map<String, String> titleToAsset = {
      'Deltoids': 'assets/images/muscle/deltoids.png',
      'Biceps': 'assets/images/muscle/biceps.png',
      'Triceps': 'assets/images/muscle/triceps.png',
      'Cervical Muscle': 'assets/images/muscle/neck_muscles.png',
    };
    final path = titleToAsset[title];
    if (path == null) {
      return Icon(Icons.image_not_supported, color: fallbackTint, size: 24);
    }
    return GestureDetector(
      onTap: () => _showImageDialog(title, path),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset(path, fit: BoxFit.contain),
      ),
    );
  }

  void _showImageDialog(String title, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B2E2E),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Image
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tap anywhere to close',
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}