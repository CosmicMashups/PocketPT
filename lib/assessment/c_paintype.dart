// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import 'c_painlevel.dart';
import 'c_painduration.dart';
class AssessPainType extends StatefulWidget {
  const AssessPainType({super.key});

  @override
  State<AssessPainType> createState() => _AssessPainTypeState();
}

class _AssessPainTypeState extends State<AssessPainType> {
  String painType = UserAssess.painType;

  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Professional blue
  static const subColor = Color(0xFFC24A4A); // Light maroon
  static const detailColor = Color(0xFF6B7280); // Gray
  static const backgroundColor = Color(0xFFF8FAFC); // Light background
  static const warningColor = Color(0xFFF59E0B); // Orange
  static const errorColor = Color(0xFFEF4444); // Red

  @override
  void initState() {
    super.initState();
    // Initialize painType from global variables
    if (UserAssess.painType.isNotEmpty) {
      painType = UserAssess.painType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : backgroundColor,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: Text(
          "Pain Type Assessment",
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
              pageBuilder: (context, animation, secondaryAnimation) => const AssessPainLevel(),
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
              value: 0.6,
              minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Step 3 of 5",
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
                          color: warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.health_and_safety, color: warningColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Pain Assessment",
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
                    "How would you characterize the pain you're currently dealing with?",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: mainColor,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Select the type that best describes your pain experience",
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      color: detailColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pain Type Options
                  _buildPainTypeOption(
                    'Nerve Pain',
                    'Tingling, burning, or like an electric shock shooting through your body',
                    Icons.electrical_services,
                    errorColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPainTypeOption(
                    'Muscle Pain',
                    'It feels like sore muscles, especially when you move or touch the area',
                    Icons.fitness_center,
                    mainColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPainTypeOption(
                    'Bone Pain',
                    'It feels like it\'s coming from deep inside the bone, not the muscle',
                    Icons.medical_services,
                    detailColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPainTypeOption(
                    'Joint Pain',
                    'It comes from a joint like your knee, shoulder, or fingers',
                    Icons.accessibility_new,
                    subColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPainTypeOption(
                    'Inflammatory Pain',
                    'The area is red, warm, or swollen',
                    Icons.local_fire_department,
                    warningColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPainTypeOption(
                    'Referred Pain',
                    'I feel pain somewhere even though that part doesn\'t seem injured',
                    Icons.location_on,
                    const Color(0xFF8B5CF6),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPainTypeOption(
                    'Cramping Pain',
                    'My muscles or stomach are tightening or cramping up suddenly',
                    Icons.bolt,
                    const Color(0xFFF59E0B),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPainTypeOption(
                    'Visceral Pain',
                    'The pain is deep inside the body and hard to describe exactly where it is',
                    Icons.visibility_off,
                    const Color(0xFF6B7280),
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
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const AssessPainDuration(),
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

  Widget _buildPainTypeOption(String title, String description, IconData icon, Color color) {
    final isSelected = painType == title;
    
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
        onTap: () {
          setState(() {
            painType = title;
            UserAssess.painType = title;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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