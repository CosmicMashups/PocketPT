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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F4),
        elevation: 0,
        title: Text(
          "Assessment Summary",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => AssessHistory(),
              transitionsBuilder: (_, animation, __, child) =>
                  SlideTransition(position: animation.drive(Tween(begin: Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))), child: child),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: 1.0,
              minHeight: 8,
              color: const Color(0xFF800020),
              backgroundColor: const Color(0xFF404040),
            ),
            const SizedBox(height: 10),

            // Top Hero Image
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(20),
            //   child: Image.asset(
            //     'assets/images/summary_banner.png',
            //     height: 180,
            //     width: double.infinity,
            //     fit: BoxFit.cover,
            //   ),
            // ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF800020), size: 48),
                        const SizedBox(height: 8),
                        Text(
                          "You're all set!",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Here's a quick look at your inputs.",
                          style: GoogleFonts.ptSans(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Decorative summary box
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF3F1EF), Color(0xFFECE9E6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Summary Report",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF800020),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(Icons.flag, "Rehabilitation Goal", UserAssess.rehabGoal),
                        _buildSummaryRow(Icons.fitness_center, "General Muscle Area", UserAssess.generalMuscle),
                        _buildSummaryRow(Icons.adjust, "Specific Muscle", UserAssess.specificMuscle),
                        _buildSummaryRow(Icons.bar_chart, "Pain Scale", UserAssess.painScale.toString()),
                        _buildSummaryRow(Icons.trending_up, "Pain Level", UserAssess.painLevel),
                        _buildSummaryRow(Icons.bolt, "Pain Type", UserAssess.painType),
                        _buildSummaryRow(Icons.schedule, "Pain Duration", UserAssess.painDuration),
                        _buildSummaryRow(Icons.health_and_safety, "Is Injured?", isInjured ? "Yes" : "No"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Start Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => GeneratePlanPage(),
                            transitionsBuilder: (_, animation, __, child) =>
                                SlideTransition(position: animation.drive(Tween(begin: Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))), child: child),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF800020),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 6,
                      ),
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      label: Text(
                        "Start Plan",
                        style: GoogleFonts.ptSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
  }

  Widget _buildSummaryRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Color(0xFF800020)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ptSans(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: GoogleFonts.ptSans(fontSize: 15, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}