import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import 'd_history.dart';
import 'generate_plan.dart';

class AssessSummary extends StatefulWidget {
  const AssessSummary({super.key});

  @override
  State<AssessSummary> createState() => _AssessSummaryState();
}

class _AssessSummaryState extends State<AssessSummary> {
  bool isInjured = UserAssess.isInjured;

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
          "Assessment Complete",
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
              pageBuilder: (_, __, ___) => const AssessHistory(),
              transitionsBuilder: (_, animation, __, child) =>
                  SlideTransition(position: animation.drive(Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))), child: child),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                    successColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: successColor.withOpacity(0.2),
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
                    "Assessment Complete!",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: mainColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your personalized rehabilitation plan is ready",
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
                        "Clinical Assessment Summary",
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Generate Plan Button
            Container(
              width: double.infinity,
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
                    color: successColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const GeneratePlanPage(),
                      transitionsBuilder: (_, animation, __, child) =>
                          SlideTransition(position: animation.drive(Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))), child: child),
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
                icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                label: Text(
                  "Generate Treatment Plan",
                  style: GoogleFonts.ptSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
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
}