import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'a_goal1.dart';
class AssessPrelim extends StatelessWidget {
  const AssessPrelim({super.key});

  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Professional blue
  static const subColor = Color(0xFFC24A4A); // Light blue
  static const detailColor = Color(0xFF6B7280); // Gray
  static const backgroundColor = Color(0xFFF8FAFC); // Light background
  static const successColor = Color(0xFF10B981); // Green
  static const warningColor = Color(0xFFF59E0B); // Orange
  static const errorColor = Color(0xFFEF4444); // Red

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Professional Header Section
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                      isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF0F9FF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
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
                    // Medical Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.medical_services,
                        color: mainColor,
                        size: 48,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                Text(
                      "Clinical Assessment",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : mainColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                    
                    const SizedBox(height: 12),
                
                    // Subtitle
                Text(
                      "Before we proceed with your personalized rehabilitation plan, we need to gather some important clinical information.",
                      style: GoogleFonts.ptSans(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : detailColor,
                        height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Assessment Steps Section
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
                    Text(
                      "Assessment Process",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : mainColor,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildAssessmentStep(
                      Icons.flag,
                      "Rehabilitation Goal",
                      "Define your primary treatment objective",
                      mainColor,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildAssessmentStep(
                      Icons.fitness_center,
                      "Focus Area",
                      "Identify the specific body region for treatment",
                      subColor,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildAssessmentStep(
                      Icons.health_and_safety,
                      "Pain Assessment",
                      "Evaluate pain level, type, and duration",
                      warningColor,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildAssessmentStep(
                      Icons.history,
                      "Medical History",
                      "Review previous injuries and conditions",
                      detailColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Proceed Button
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
                    Navigator.push(
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
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Begin Assessment",
                      style: GoogleFonts.ptSans(
                        fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
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
      ),
    );
  }

  // Helper method to build assessment steps
  Widget _buildAssessmentStep(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                Text(
                  title,
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 4),
        Text(
                  description,
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    color: detailColor,
          ),
        ),
      ],
            ),
          ),
          Icon(
            Icons.check_circle_outline,
            color: successColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}