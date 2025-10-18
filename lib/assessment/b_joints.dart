// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import 'assessment_data.dart';
import 'b_focus1.dart';
import 'c_upload.dart';

class AssessJoints extends StatefulWidget {
  const AssessJoints({super.key});

  @override
  State<AssessJoints> createState() => _AssessJointsState();
}

class _AssessJointsState extends State<AssessJoints> {
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
    print('AssessJoints: initState() called');
    print('AssessJoints: Current AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
    print('AssessJoints: Current UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
    
    // Initialize specificMuscle from local data
    specificMuscle = UserAssess.specificMuscle;
    print('AssessJoints: specificMuscle initialized to: "$specificMuscle"');
    print('AssessJoints: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('AssessJoints: build() called');
    print('AssessJoints: Current AssessmentData.specificMuscle in build = "${AssessmentData.specificMuscle}"');
    print('AssessJoints: Current UserAssess.specificMuscle in build = "${UserAssess.specificMuscle}"');
    print('AssessJoints: Current specificMuscle = "$specificMuscle"');
    
    try {
      return _buildPageContent(context);
    } catch (e) {
      print('AssessJoints: ERROR in build() - $e');
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
                  ),
                ),
                Expanded(
                  child: Text(
                    "Joint Areas",
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
          Flexible(
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Section
                    _buildProgressSection(2, 8, "Joint Selection"),
                    
                    const SizedBox(height: 24),

                    // Question Section
                    _buildQuestionSection(
                      "Joint Selection",
                      "Select the specific joint area you'd like to focus on",
                      Icons.help_outline,
                    ),

                    const SizedBox(height: 24),

                    // Joint Options
                    _buildMuscleOption(
                      'Elbow',
                      'A hinge joint enabling arm bending and extension, supported by surrounding muscles and tendons.',
                      Icons.accessibility_new,
                      mainColor,
                    ),
                    const SizedBox(height: 16),
                    _buildMuscleOption(
                      'Knee',
                      'A complex joint that allows leg bending and straightening, vital for standing and movement.',
                      Icons.directions_run,
                      subColor,
                    ),
                    const SizedBox(height: 16),
                    _buildMuscleOption(
                      'Ankle',
                      'A flexible joint connecting the foot to the leg, essential for walking, running, and balance.',
                      Icons.directions_walk,
                      successColor,
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

  Widget _buildMuscleOption(String title, String description, IconData icon, Color color) {
    final isSelected = specificMuscle == title;
    
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
          print('AssessJoints: Joint option tapped - title: "$title"');
          print('AssessJoints: Before setState - AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
          print('AssessJoints: Before setState - UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
          
          setState(() {
            print('AssessJoints: Inside setState - setting AssessmentData.specificMuscle to: "$title"');
            AssessmentData.specificMuscle = title;
            print('AssessJoints: Inside setState - AssessmentData.specificMuscle is now: "${AssessmentData.specificMuscle}"');
            
            specificMuscle = title;
            UserAssess.specificMuscle = title;
          });
          
          print('AssessJoints: Selected joint: $title');
          print('AssessJoints: Final AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
          print('AssessJoints: Final UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
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
      'Elbow': 'assets/images/muscle/forearm_muscles.png',
      'Knee': 'assets/images/muscle/quadriceps.png',
      'Ankle': 'assets/images/muscle/ankle.png',
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