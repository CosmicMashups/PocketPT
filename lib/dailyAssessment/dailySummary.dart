import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';

class DailySummaryPage extends StatefulWidget {
  const DailySummaryPage({super.key});

  @override
  State<DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<DailySummaryPage> {
  bool isInjured = false;

  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Professional blue
  static const detailColor = Color(0xFF6B7280); // Gray
  static const backgroundColor = Color(0xFFF8FAFC); // Light background
  static const successColor = Color(0xFF10B981); // Green

  @override
  void initState() {
    super.initState();
    print('DailySummaryPage: initState() called');
    print('DailySummaryPage: Current UserAssess.isInjured = "${UserAssess.isInjured}"');
    
    // Initialize isInjured from local data
    isInjured = UserAssess.isInjured;
    print('DailySummaryPage: isInjured initialized to: $isInjured');
    print('DailySummaryPage: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('DailySummaryPage: build() called');
    print('DailySummaryPage: Current UserAssess.isInjured in build = "${UserAssess.isInjured}"');
    print('DailySummaryPage: Current isInjured = $isInjured');
    
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : backgroundColor,
        body: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
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
                                  "Assessment Complete",
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
                              value: 1.0,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE5E7EB),
                              valueColor: AlwaysStoppedAnimation<Color>(successColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "All steps completed successfully",
                              style: GoogleFonts.ptSans(
                                fontSize: 14,
                                color: successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Success Header
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                              const Color(0x0D10B981),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0x3310B981),
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
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: successColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: successColor,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Daily Assessment Complete!",
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: mainColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Your daily progress has been recorded",
                              style: GoogleFonts.ptSans(
                                fontSize: 16,
                                color: detailColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Clinical Summary Report
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
                                  child: Icon(Icons.medical_information, color: mainColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Daily Assessment Summary",
                                  style: GoogleFonts.ptSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildSummaryRow(Icons.flag, "Rehabilitation Goal", UserAssess.rehabGoal),
                            _buildSummaryRow(Icons.fitness_center, "General Muscle Area", UserAssess.generalMuscle),
                            _buildSummaryRow(Icons.adjust, "Specific Muscle", UserAssess.specificMuscle),
                            _buildSummaryRow(Icons.bar_chart, "Pain Scale", UserAssess.painScale.toString()),
                            _buildSummaryRow(Icons.trending_up, "Pain Level", UserAssess.painLevel),
                            _buildSummaryRow(Icons.bolt, "Pain Type", UserAssess.painType),
                            _buildSummaryRow(Icons.schedule, "Pain Duration", UserAssess.painDuration),
                            _buildSummaryRow(Icons.health_and_safety, "Injury Status", isInjured ? "Yes" : "No"),
                            
                            // Muscle Assessment Data
                            if (UserAssess.injuredMuscles.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildMuscleAssessmentSection(),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: mainColor),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_back, color: Color(0xFF8B2E2E), size: 20),
                                label: Text(
                                  "Back to Dashboard",
                                  style: GoogleFonts.ptSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: mainColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    successColor,
                                    const Color(0xFF059669),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x4D10B981),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  print('DailySummaryPage: View Reports button pressed');
                                  print('DailySummaryPage: Final UserAssess.isInjured = "${UserAssess.isInjured}"');
                                  print('DailySummaryPage: Navigating back to dashboard');
                                  
                                  Navigator.of(context).pop();
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
                                icon: const Icon(Icons.analytics, color: Colors.white, size: 20),
                                label: Text(
                                  "View Reports",
                                  style: GoogleFonts.ptSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
      print('DailySummaryPage: ERROR in build() - $e');
      return Container(
        color: backgroundColor,
        child: Center(
          child: Text(
            'Error loading daily assessment summary: $e',
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
            onPressed: () {
              print('DailySummaryPage: Back button pressed');
              print('DailySummaryPage: Current UserAssess.isInjured = "${UserAssess.isInjured}"');
              print('DailySummaryPage: Navigating back to dashboard');
              
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: Text(
              "Daily Assessment Complete",
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

  Widget _buildSummaryRow(IconData icon, String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: mainColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: detailColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: mainColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleAssessmentSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE0F2FE),
          width: 1,
        ),
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
                child: Icon(Icons.fitness_center, size: 20, color: mainColor),
              ),
              const SizedBox(width: 12),
              Text(
                "Muscle Injury Assessment",
                style: GoogleFonts.ptSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: mainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...UserAssess.injuredMuscles.map((muscle) {
            final painLevel = UserAssess.musclePainLevels[muscle] ?? 0;
            final painCategory = UserAssess.musclePainCategories[muscle] ?? 'Low';
            final painColor = _getPainColor(painLevel);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: painColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: painColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: painColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      muscle,
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: mainColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: painColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Level $painLevel ($painCategory)",
                      style: GoogleFonts.ptSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: painColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getPainColor(int level) {
    if (level <= 2) return const Color(0xFF10B981);
    if (level <= 4) return const Color(0xFFF59E0B);
    if (level <= 6) return const Color(0xFFC24A4A);
    if (level <= 8) return const Color(0xFF8B2E2E);
    return const Color(0xFFEF4444);
  }
}