import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/rehab_plan_expansion_panel.dart';
import 'widgets/exercise_calendar_grid.dart';
import 'widgets/export_pdf_button.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Report'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: const [
                RehabPlanExpansionPanel(),
                SizedBox(height: 24),
                ExerciseCalendarGrid(),
              ],
            ),
          ),
          const ExportPDFButton(),
        ],
      ),
    );
  }
} 