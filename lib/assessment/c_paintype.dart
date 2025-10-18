// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import 'assessment_data.dart';
// Sync removed for assessment (local-only)
// removed unused import
import 'c_painduration.dart';

class AssessPainType extends StatefulWidget {
  const AssessPainType({super.key});

  @override
  State<AssessPainType> createState() => _AssessPainTypeState();
}

class _AssessPainTypeState extends State<AssessPainType> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);
  // removed unused successColor to satisfy analyzer

  String selectedPainType = '';

  @override
  void initState() {
    super.initState();
    print('AssessPainType: initState() called');
    print('AssessPainType: Current AssessmentData.painType = "${AssessmentData.painType}"');
    print('AssessPainType: Current UserAssess.painType = "${UserAssess.painType}"');
    
    // Initialize selectedPainType from local data
    selectedPainType = UserAssess.painType;
    print('AssessPainType: selectedPainType initialized to: "$selectedPainType"');
    print('AssessPainType: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('AssessPainType: build() called');
    print('AssessPainType: Current AssessmentData.painType in build = "${AssessmentData.painType}"');
    print('AssessPainType: Current UserAssess.painType in build = "${UserAssess.painType}"');
    print('AssessPainType: Current selectedPainType = "$selectedPainType"');
    
    try {
      return _buildPageContent(context);
    } catch (e) {
      print('AssessPainType: ERROR in build() - $e');
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
                    "Pain Type",
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
                    _buildProgressSection(5, 8, "Pain Type Assessment"),
                    
                    const SizedBox(height: 24),

                    // Question Section
                    _buildQuestionSection(
                      "Pain Type",
                      "What type of pain are you experiencing?",
                      Icons.healing,
                    ),

                    const SizedBox(height: 24),

                    // Pain Type Options
                    _buildPainTypeOption(
                      'Sharp/Stabbing',
                      'Intense, sudden pain that feels like being stabbed',
                      Icons.flash_on,
                      mainColor,
                    ),
                    const SizedBox(height: 16),
                    _buildPainTypeOption(
                      'Dull/Aching',
                      'Persistent, throbbing pain that lingers',
                      Icons.waves,
                      subColor,
                    ),
                    const SizedBox(height: 16),
                    _buildPainTypeOption(
                      'Burning',
                      'Hot, searing sensation like a burn',
                      Icons.local_fire_department,
                      const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 16),
                    _buildPainTypeOption(
                      'Throbbing',
                      'Rhythmic, pulsing pain that comes and goes',
                      Icons.favorite,
                      const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 16),
                    _buildPainTypeOption(
                      'Stiffness',
                      'Tightness and reduced range of motion',
                      Icons.lock,
                      const Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 16),
                    _buildPainTypeOption(
                      'Numbness/Tingling',
                      'Loss of sensation or pins and needles feeling',
                      Icons.psychology,
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
                        onPressed: selectedPainType.isNotEmpty ? () {
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

  Widget _buildPainTypeOption(String title, String description, IconData icon, Color color) {
    final isSelected = selectedPainType == title;
    
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
          print('AssessPainType: Pain type option tapped - title: "$title"');
          print('AssessPainType: Before setState - AssessmentData.painType = "${AssessmentData.painType}"');
          print('AssessPainType: Before setState - UserAssess.painType = "${UserAssess.painType}"');
          
          setState(() {
            print('AssessPainType: Inside setState - setting AssessmentData.painType to: "$title"');
            AssessmentData.painType = title;
            print('AssessPainType: Inside setState - AssessmentData.painType is now: "${AssessmentData.painType}"');
            
            selectedPainType = title;
            UserAssess.painType = title;
          });
          
          print('AssessPainType: Selected pain type: $title');
          print('AssessPainType: Final AssessmentData.painType = "${AssessmentData.painType}"');
          print('AssessPainType: Final UserAssess.painType = "${UserAssess.painType}"');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
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
}