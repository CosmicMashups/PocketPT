import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/rehab_plan_expansion_panel.dart';
import 'widgets/exercise_calendar_grid.dart';
import 'widgets/export_pdf_button.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  // Define color constants
  static const mainColor = Color(0xFF800020); // Burgundy/Maroon
  static const detailColor = Color(0xFF6A5D7B); // Muted Purple

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progress Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: mainColor, // Updated to mainColor
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    mainColor.withOpacity(0.05), // Updated to mainColor
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: const [
                    SizedBox(height: 8),
                    RehabPlanExpansionPanel(),
                    SizedBox(height: 24),
                    ExerciseCalendarGrid(),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: const ExportPDFButton(),
          ),
        ],
      ),
    );
  }
}