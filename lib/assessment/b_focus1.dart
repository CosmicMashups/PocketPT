// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import 'a_goal1.dart';

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
  String generalMuscle = UserAssess.generalMuscle;

  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Professional blue
  static const subColor = Color(0xFFC24A4A); // Light blue
  static const detailColor = Color(0xFF6B7280); // Gray
  static const backgroundColor = Color(0xFFF8FAFC); // Light background
  static const successColor = Color(0xFF10B981); // Green

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : backgroundColor,
      appBar: AppBar(
        backgroundColor: mainColor,
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
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                mainColor,
                subColor,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const AssessGoal1(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.assessment, color: mainColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Assessment Progress",
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.4,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Step 2 of 5",
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      color: detailColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Question Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
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
                        child: Icon(Icons.help_outline, color: mainColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Clinical Assessment",
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Which general muscle region are you aiming to target?",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: mainColor,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Select the primary body region for your rehabilitation focus",
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      color: detailColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Muscle Region Options
                  _buildMuscleRegionOption(
                    'Upper Body',
                    'Shoulders, arms, and hands',
                    'assets/images/muscle_region/upper_body.png',
                    Icons.accessibility_new,
                    mainColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildMuscleRegionOption(
                    'Lower Body',
                    'Hips, legs, and feet',
                    'assets/images/muscle_region/lower_body.png',
                    Icons.directions_walk,
                    subColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildMuscleRegionOption(
                    'Core Area',
                    'Stomach, and lower back muscles',
                    'assets/images/muscle_region/core_area.png',
                    Icons.fitness_center,
                    successColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildMuscleRegionOption(
                    'Neck & Upper Back',
                    'Neck, shoulder blade',
                    'assets/images/muscle_region/neck.png',
                    Icons.health_and_safety,
                    detailColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildMuscleRegionOption(
                    'Joints',
                    'Elbow, knee, ankle',
                    'assets/images/muscle_region/joints.png',
                    Icons.medical_services,
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Next Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    mainColor,
                    subColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Widget nextPage;

                  if (generalMuscle == "Upper Body") {
                    nextPage = const AssessUpperBody();
                  } else if (generalMuscle == "Lower Body") {
                    nextPage = const AssessLowerBody();
                  } else if (generalMuscle == "Core Area") {
                    nextPage = const AssessCore();
                  } else if (generalMuscle == "Neck & Upper Back") {
                    nextPage = const AssessNeck();
                  } else if (generalMuscle == "Joints") {
                    nextPage = const AssessJoints();
                  } else {
                    // Default
                    nextPage = const AssessFocus1();
                  }

                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => nextPage,
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
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Continue Assessment",
                      style: GoogleFonts.ptSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleRegionOption(String title, String description, String imagePath, IconData icon, Color color) {
    final isSelected = generalMuscle == title;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : (isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            generalMuscle = title;
            UserAssess.generalMuscle = title;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ptSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : mainColor,
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
}