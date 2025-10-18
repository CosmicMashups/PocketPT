// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import 'assessment_data.dart';
import 'b_focus1.dart';
import 'c_video.dart';

class AssessLowerBody extends StatefulWidget {
  const AssessLowerBody({super.key});

  @override
  State<AssessLowerBody> createState() => _AssessLowerBodyState();
}

class _AssessLowerBodyState extends State<AssessLowerBody> {
  String specificMuscle = '';

  @override
  void initState() {
    super.initState();
    print('AssessLowerBody: initState() called');
    print('AssessLowerBody: Current AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
    print('AssessLowerBody: Current UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
    
    // Ensure we have a default value for specificMuscle
    if (AssessmentData.specificMuscle.isEmpty) {
      print('AssessLowerBody: AssessmentData.specificMuscle is empty, setting to empty string');
      AssessmentData.specificMuscle = '';
    } else {
      print('AssessLowerBody: AssessmentData.specificMuscle already has value: "${AssessmentData.specificMuscle}"');
    }
    
    // Initialize local variable
    specificMuscle = AssessmentData.specificMuscle;
    print('AssessLowerBody: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('AssessLowerBody: build() called');
    print('AssessLowerBody: Current AssessmentData.specificMuscle in build = "${AssessmentData.specificMuscle}"');
    print('AssessLowerBody: Current UserAssess.specificMuscle in build = "${UserAssess.specificMuscle}"');
    
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC), // Professional background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8B2E2E)),
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
        ),
        title: Text(
          "Lower Body Muscles",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B2E2E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assessment,
                          color: Color(0xFF8B2E2E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Assessment Progress",
                              style: GoogleFonts.ptSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Step 2 of 5",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: 0.4,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
                  ),
                ],
              ),
            ),

            // Question Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B2E2E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Color(0xFF8B2E2E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Muscle Selection",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Select the specific lower body muscle you'd like to focus on",
                              style: GoogleFonts.ptSans(
                                fontSize: 16,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Muscle Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [

                  _buildMuscleOption(
                    'Quadriceps',
                    'Front thigh muscles that extend the knee and help with walking, running, and jumping.',
                    Icons.directions_run,
                    const Color(0xFF8B2E2E),
                  ),
                  
                  _buildMuscleOption(
                    'Hamstrings',
                    'Back thigh muscles responsible for knee flexion and hip extension.',
                    Icons.trending_down,
                    const Color(0xFFC24A4A),
                  ),
                  
                  _buildMuscleOption(
                    'Calf',
                    'Muscles at the back of the lower leg that allow for ankle movement and push-off during walking.',
                    Icons.directions_walk,
                    const Color(0xFF10B981),
                  ),
                  
                  _buildMuscleOption(
                    'Ankle',
                    'Composed of muscles and tendons that enable foot movement and balance.',
                    Icons.airline_seat_legroom_extra,
                    const Color(0xFFF59E0B),
                  ),
                  
                  _buildMuscleOption(
                    'Gluteals',
                    'Buttock muscles that extend and rotate the hip, crucial for walking, climbing, and posture.',
                    Icons.accessibility_new,
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
                          color: const Color(0xFF8B2E2E).withOpacity(0.3),
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
                            pageBuilder: (context, animation, secondaryAnimation) => AssessPainVideo(),
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
          ],
        ),
      ),
    );
    } catch (e) {
      print('AssessLowerBody: ERROR in build() - $e');
      return Container(
        color: const Color(0xFFF8FAFC),
        child: Center(
          child: Text(
            'Error loading page: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildMuscleOption(String title, String description, IconData icon, Color color) {
    print('AssessLowerBody: _buildMuscleOption() called for title: "$title"');
    print('AssessLowerBody: Current AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
    print('AssessLowerBody: Comparing with title: "$title"');
    
    final isSelected = specificMuscle == title;
    print('AssessLowerBody: isSelected = $isSelected');
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : (isDark ? Theme.of(context).colorScheme.surface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          print('AssessLowerBody: Muscle option tapped - "$title"');
          print('AssessLowerBody: Before setState - AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
          print('AssessLowerBody: Before setState - UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
          
          setState(() {
            print('AssessLowerBody: Inside setState - setting AssessmentData.specificMuscle to: "$title"');
            AssessmentData.specificMuscle = title;
            print('AssessLowerBody: Inside setState - AssessmentData.specificMuscle is now: "${AssessmentData.specificMuscle}"');
            
            specificMuscle = title;
            UserAssess.specificMuscle = title;
          });
          
          print('AssessLowerBody: Selected specific muscle: $title');
          print('AssessLowerBody: Final AssessmentData.specificMuscle = "${AssessmentData.specificMuscle}"');
          print('AssessLowerBody: Final UserAssess.specificMuscle = "${UserAssess.specificMuscle}"');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Image icon
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
                        color: isSelected ? color.withOpacity(0.8) : const Color(0xFF6B7280),
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
      'Quadriceps': 'assets/images/muscle/quadriceps.png',
      'Hamstrings': 'assets/images/muscle/hamstrings.png',
      'Calf': 'assets/images/muscle/ankle.png',
      'Ankle': 'assets/images/muscle/ankle.png',
      'Gluteals': 'assets/images/muscle/glutes.png',
    };
    final path = titleToAsset[title];
    if (path == null) {
      return Icon(Icons.image_not_supported, color: fallbackTint, size: 24);
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: Image.asset(path, fit: BoxFit.contain),
    );
  }
}
