// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import 'c_painduration.dart';
import 'e_summary.dart';
import 'assessment_data.dart';
// Sync removed for assessment (local-only)

class AssessHistory extends StatefulWidget {
  const AssessHistory({super.key});

  @override
  State<AssessHistory> createState() => _AssessHistoryState();
}

class _AssessHistoryState extends State<AssessHistory> {
  bool isInjured = false;

  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Professional blue
  static const subColor = Color(0xFFC24A4A); // Light maroon
  static const detailColor = Color(0xFF6B7280); // Gray
  static const backgroundColor = Color(0xFFF8FAFC); // Light background
  static const successColor = Color(0xFF10B981); // Green

  @override
  void initState() {
    super.initState();
    print('AssessHistory: initState() called');
    print('AssessHistory: Current AssessmentData.isInjured = "${AssessmentData.isInjured}"');
    print('AssessHistory: Current UserAssess.isInjured = "${UserAssess.isInjured}"');
    
    // Initialize isInjured from local data
    isInjured = UserAssess.isInjured;
    print('AssessHistory: isInjured initialized to: $isInjured');
    print('AssessHistory: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('AssessHistory: build() called');
    print('AssessHistory: Current AssessmentData.isInjured in build = "${AssessmentData.isInjured}"');
    print('AssessHistory: Current UserAssess.isInjured in build = "${UserAssess.isInjured}"');
    print('AssessHistory: Current isInjured = $isInjured');
    
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Material(
      color: isDark ? Theme.of(context).scaffoldBackgroundColor : backgroundColor,
      child: Column(
        children: [
          _buildAppBar(context),
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
                    color: isDark ? const Color(0x33000000) : const Color(0x0A000000),
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
              value: 0.8,
              minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Step 4 of 5",
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
                          color: const Color(0x1A8B2E2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.medical_information, color: mainColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Medical History",
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
                    "Have you had any previous injuries or conditions that may currently affect your mobility?",
                    style: GoogleFonts.ptSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: mainColor,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "This information helps us create a safer and more effective treatment plan",
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      color: detailColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Yes/No Options
                  _buildHistoryOption(
                    true,
                    'Yes',
                    'I have previous injuries or conditions that may affect my mobility',
                    Icons.check_circle,
                    successColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildHistoryOption(
                    false,
                    'No',
                    'I do not have any previous injuries or conditions',
                    Icons.cancel,
                    detailColor,
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
                    color: const Color(0x4D8B2E2E),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint('🔍 AssessHistory: Complete Assessment button pressed');
                        debugPrint('📊 AssessHistory: UserAssess.isInjured = ${UserAssess.isInjured}');
                        debugPrint('🗺️ AssessHistory: Navigating to AssessSummary');
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
                      "Complete Assessment",
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
            ),
          ),
        ],
      ),
    );
    } catch (e) {
      print('AssessHistory: ERROR in build() - $e');
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

  Widget _buildAppBar(BuildContext context) {
    return Container(
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
            ),
          ),
          Expanded(
            child: Text(
              "Medical History",
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
    );
  }


  Widget _buildHistoryOption(bool value, String title, String description, IconData icon, Color color) {
    print('AssessHistory: _buildHistoryOption() called for value: $value, title: "$title"');
    print('AssessHistory: Current AssessmentData.isInjured = "${AssessmentData.isInjured}"');
    print('AssessHistory: Current UserAssess.isInjured = "${UserAssess.isInjured}"');
    print('AssessHistory: Current isInjured = $isInjured');
    
    final isSelected = isInjured == value;
    print('AssessHistory: isSelected = $isSelected');
    
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
          print('AssessHistory: History option tapped - value: $value, title: "$title"');
          print('AssessHistory: Before setState - AssessmentData.isInjured = "${AssessmentData.isInjured}"');
          print('AssessHistory: Before setState - UserAssess.isInjured = "${UserAssess.isInjured}"');
          
          setState(() {
            print('AssessHistory: Inside setState - setting AssessmentData.isInjured to: $value');
            AssessmentData.isInjured = value;
            print('AssessHistory: Inside setState - AssessmentData.isInjured is now: "${AssessmentData.isInjured}"');
            
            isInjured = value;
            UserAssess.isInjured = value;
          });
          
          print('AssessHistory: Selected injury status: $value');
          print('AssessHistory: Final AssessmentData.isInjured = "${AssessmentData.isInjured}"');
          print('AssessHistory: Final UserAssess.isInjured = "${UserAssess.isInjured}"');
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